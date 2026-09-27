-- Follow-up to 20260925000000_virgil_server_side_quota.sql:
--   * a daily quota for the Turkish-book description generator
--     (POST /api/v1/trbooks/generate-description calls Gemini and had none),
--   * refunds, so a call that fails upstream or times out doesn't cost the user
--     a unit,
--   * authorize_virgil_action_ex(), which reports WHAT was spent so exactly that
--     can be given back.
--
-- Backward compatible: authorize_virgil_action() (boolean) and the client RPCs
-- keep their signatures and behaviour.

-- ---------------------------------------------------------------------------
-- Third counter + limit.
-- ---------------------------------------------------------------------------
alter table public.virgil_usage_daily
  add column if not exists trbook_descriptions_count integer not null default 0
    check (trbook_descriptions_count >= 0);

create or replace function public.virgil_usage_limit(p_action text)
returns integer
language sql
immutable
as $$
  select case p_action
    when 'recommendation' then 5
    when 'upload' then 3
    when 'trbook_description' then 10
    else null
  end;
$$;

-- Old clients call this before every API call (check only, see previous
-- migration). It now understands the third action too.
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
           when 'upload' then uploads_count
           else trbook_descriptions_count
         end
    into v_count
  from public.virgil_usage_daily
  where user_id = v_uid and usage_date = v_today;

  return coalesce(v_count, 0) < v_limit;
end;
$$;

-- ---------------------------------------------------------------------------
-- authorize_virgil_action_ex: 'unit' (a daily unit was consumed), 'ticket' (a
-- call of an open per-query search ticket was spent) or 'denied'.
-- ---------------------------------------------------------------------------
create or replace function public.authorize_virgil_action_ex(
  p_uid uuid,
  p_action text,
  p_query_hash text default null
)
returns text
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

  if p_action = 'recommendation' and p_query_hash is not null then
    update public.virgil_search_tickets
    set calls_left = calls_left - 1
    where user_id = p_uid
      and query_hash = p_query_hash
      and expires_at > now()
      and calls_left > 0
    returning true into v_ticket;

    if v_ticket then
      return 'ticket';
    end if;
  end if;

  insert into public.virgil_usage_daily (user_id, usage_date)
  values (p_uid, v_today)
  on conflict (user_id, usage_date) do nothing;

  if p_action = 'recommendation' then
    update public.virgil_usage_daily
    set recommendations_count = recommendations_count + 1
    where user_id = p_uid and usage_date = v_today
      and recommendations_count < v_limit
    returning true into v_allowed;
  elsif p_action = 'upload' then
    update public.virgil_usage_daily
    set uploads_count = uploads_count + 1
    where user_id = p_uid and usage_date = v_today
      and uploads_count < v_limit
    returning true into v_allowed;
  else
    update public.virgil_usage_daily
    set trbook_descriptions_count = trbook_descriptions_count + 1
    where user_id = p_uid and usage_date = v_today
      and trbook_descriptions_count < v_limit
    returning true into v_allowed;
  end if;

  if not coalesce(v_allowed, false) then
    return 'denied';
  end if;

  if p_action = 'recommendation' and p_query_hash is not null then
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

  return 'unit';
end;
$$;

-- The boolean form stays for callers that only need allow/deny.
create or replace function public.authorize_virgil_action(
  p_uid uuid,
  p_action text,
  p_query_hash text default null
)
returns boolean
language sql
security definer
set search_path = public
as $$
  select public.authorize_virgil_action_ex(p_uid, p_action, p_query_hash)
         <> 'denied';
$$;

-- ---------------------------------------------------------------------------
-- refund_virgil_action: gives back what authorize_virgil_action_ex spent.
--   p_kind 'ticket' : hand the call back to the ticket (capped at its 9 spare
--                     calls) if it is still open.
--   p_kind 'unit'   : decrement today's counter (never below 0); a search also
--                     drops its ticket, so the retry pays -- and re-opens it --
--                     like the failed call would have.
-- Idempotence isn't guaranteed: call it once per failed call.
-- ---------------------------------------------------------------------------
create or replace function public.refund_virgil_action(
  p_uid uuid,
  p_action text,
  p_kind text,
  p_query_hash text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_today date := (timezone('utc', now()))::date;
begin
  if p_uid is null then
    raise exception 'not_authenticated';
  end if;
  if public.virgil_usage_limit(p_action) is null then
    raise exception 'invalid_action';
  end if;

  if p_kind = 'ticket' then
    if p_query_hash is not null then
      update public.virgil_search_tickets
      set calls_left = least(calls_left + 1, 9)
      where user_id = p_uid
        and query_hash = p_query_hash
        and expires_at > now();
    end if;
  elsif p_kind = 'unit' then
    if p_action = 'recommendation' then
      update public.virgil_usage_daily
      set recommendations_count = greatest(recommendations_count - 1, 0)
      where user_id = p_uid and usage_date = v_today;
      if p_query_hash is not null then
        delete from public.virgil_search_tickets
        where user_id = p_uid and query_hash = p_query_hash;
      end if;
    elsif p_action = 'upload' then
      update public.virgil_usage_daily
      set uploads_count = greatest(uploads_count - 1, 0)
      where user_id = p_uid and usage_date = v_today;
    else
      update public.virgil_usage_daily
      set trbook_descriptions_count = greatest(trbook_descriptions_count - 1, 0)
      where user_id = p_uid and usage_date = v_today;
    end if;
  else
    raise exception 'invalid_kind';
  end if;
end;
$$;

-- Service role only (functions are executable by PUBLIC/anon by default).
revoke all on function public.authorize_virgil_action_ex(uuid, text, text)
  from public, anon, authenticated;
revoke all on function public.authorize_virgil_action(uuid, text, text)
  from public, anon, authenticated;
revoke all on function public.refund_virgil_action(uuid, text, text, text)
  from public, anon, authenticated;
grant execute on function public.authorize_virgil_action_ex(uuid, text, text)
  to service_role;
grant execute on function public.authorize_virgil_action(uuid, text, text)
  to service_role;
grant execute on function public.refund_virgil_action(uuid, text, text, text)
  to service_role;
