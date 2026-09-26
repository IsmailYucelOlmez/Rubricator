-- Server-side enforcement of the Virgil daily quotas.
--
-- Until now the quota was only enforced by the Flutter client: it called
-- try_consume_virgil_usage() and *then* called the `rubricatorApi` edge
-- function, which forwarded to the Gemini-backed API for anyone (no auth, no
-- quota). Anyone could skip the RPC and call the API directly.
--
-- Now the edge function verifies the user's JWT and consumes quota itself via
-- authorize_virgil_action() (service_role only). To stay compatible with
-- already-published app versions -- which still call try_consume_virgil_usage()
-- before every API call -- that RPC becomes a *check only* (it no longer
-- increments); the edge function does the incrementing. Old clients therefore
-- keep working unchanged and are never double-charged.

-- ---------------------------------------------------------------------------
-- Single source of truth for the limits (was hard-coded in three functions).
-- ---------------------------------------------------------------------------
create or replace function public.virgil_usage_limit(p_action text)
returns integer
language sql
immutable
as $$
  select case p_action
    when 'recommendation' then 5
    when 'upload' then 3
    else null
  end;
$$;

-- ---------------------------------------------------------------------------
-- Client-facing RPC: now a non-mutating check. Name and signature unchanged.
-- ---------------------------------------------------------------------------
create or replace function public.try_consume_virgil_usage(p_action text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_today date := (timezone('utc', now()))::date;
  v_limit integer := public.virgil_usage_limit(p_action);
  v_count integer;
begin
  if v_uid is null then
    raise exception 'not_authenticated';
  end if;
  if v_limit is null then
    raise exception 'invalid_action';
  end if;

  select case p_action
           when 'recommendation' then recommendations_count
           else uploads_count
         end
    into v_count
  from public.virgil_usage_daily
  where user_id = v_uid and usage_date = v_today;

  return coalesce(v_count, 0) < v_limit;
end;
$$;

comment on function public.try_consume_virgil_usage(text) is
  'Checks (does NOT consume) whether the current user still has Virgil quota for the action (recommendation|upload). Consumption happens server-side in the rubricatorApi edge function via authorize_virgil_action().';

-- Same output shape as before; limits now come from virgil_usage_limit().
create or replace function public.get_virgil_usage_today()
returns table (
  recommendations_count integer,
  uploads_count integer,
  recommendations_limit integer,
  uploads_limit integer
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_today date := (timezone('utc', now()))::date;
begin
  if v_uid is null then
    raise exception 'not_authenticated';
  end if;

  return query
  select
    coalesce(u.recommendations_count, 0),
    coalesce(u.uploads_count, 0),
    public.virgil_usage_limit('recommendation'),
    public.virgil_usage_limit('upload')
  from (select 1) as _
  left join public.virgil_usage_daily u
    on u.user_id = v_uid and u.usage_date = v_today;
end;
$$;

-- ---------------------------------------------------------------------------
-- Search "tickets".
--
-- A recommendation search costs one quota unit, but the app legitimately calls
-- the API several times for the same query (changing the genre filter or the
-- language re-runs it) and used to charge only once per submit. A ticket keeps
-- that behaviour: the first call for a query consumes a unit and opens a
-- 30-minute window allowing up to 10 calls for that same query. Only a hash of
-- the normalised query is stored, never the text.
-- ---------------------------------------------------------------------------
create table if not exists public.virgil_search_tickets (
  user_id uuid not null references auth.users (id) on delete cascade,
  query_hash text not null,
  expires_at timestamptz not null,
  calls_left integer not null check (calls_left >= 0),
  primary key (user_id, query_hash)
);

alter table public.virgil_search_tickets enable row level security;
-- No policies on purpose: only service_role (which bypasses RLS) touches it.
revoke all on public.virgil_search_tickets from anon, authenticated;

-- ---------------------------------------------------------------------------
-- Server-side authorisation + consumption. Called only by the edge function
-- with the service role, after it has verified the caller's JWT.
--   recommendation + query hash : ticket (see above), else consume one unit
--   recommendation, no hash     : consume one unit
--   upload                      : consume one unit
-- Returns false when the daily limit is already reached.
-- ---------------------------------------------------------------------------
create or replace function public.authorize_virgil_action(
  p_uid uuid,
  p_action text,
  p_query_hash text default null
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_today date := (timezone('utc', now()))::date;
  v_limit integer := public.virgil_usage_limit(p_action);
  v_ticket boolean;
  v_allowed boolean := false;
begin
  if p_uid is null then
    raise exception 'not_authenticated';
  end if;
  if v_limit is null then
    raise exception 'invalid_action';
  end if;

  -- An open ticket for this exact query covers the call for free.
  if p_action = 'recommendation' and p_query_hash is not null then
    update public.virgil_search_tickets
    set calls_left = calls_left - 1
    where user_id = p_uid
      and query_hash = p_query_hash
      and expires_at > now()
      and calls_left > 0
    returning true into v_ticket;

    if v_ticket then
      return true;
    end if;
  end if;

  insert into public.virgil_usage_daily (user_id, usage_date)
  values (p_uid, v_today)
  on conflict (user_id, usage_date) do nothing;

  if p_action = 'recommendation' then
    update public.virgil_usage_daily
    set recommendations_count = recommendations_count + 1
    where user_id = p_uid
      and usage_date = v_today
      and recommendations_count < v_limit
    returning true into v_allowed;
  else
    update public.virgil_usage_daily
    set uploads_count = uploads_count + 1
    where user_id = p_uid
      and usage_date = v_today
      and uploads_count < v_limit
    returning true into v_allowed;
  end if;

  v_allowed := coalesce(v_allowed, false);

  -- Paid for a new search: open its ticket (this call + 9 more, 30 minutes).
  if v_allowed and p_action = 'recommendation' and p_query_hash is not null then
    delete from public.virgil_search_tickets
    where user_id = p_uid and expires_at <= now();

    insert into public.virgil_search_tickets
      (user_id, query_hash, expires_at, calls_left)
    values
      (p_uid, p_query_hash, now() + interval '30 minutes', 9)
    on conflict (user_id, query_hash) do update
      set expires_at = excluded.expires_at,
          calls_left = excluded.calls_left;
  end if;

  return v_allowed;
end;
$$;

comment on function public.authorize_virgil_action(uuid, text, text) is
  'Server-side Virgil quota gate used by the rubricatorApi edge function (service_role only). Consumes one unit, or spends an open per-query search ticket.';

-- Functions are executable by PUBLIC by default: lock this one down.
revoke all on function public.authorize_virgil_action(uuid, text, text)
  from public, anon, authenticated;
grant execute on function public.authorize_virgil_action(uuid, text, text)
  to service_role;
