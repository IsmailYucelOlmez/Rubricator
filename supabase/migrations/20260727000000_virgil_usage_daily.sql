-- Virgil daily usage quotas (per authenticated user).
-- Recommendations: max 3 / day
-- Book uploads: max 3 / day
-- Questions per book remain enforced by the document-chat API (default 10).

create table if not exists public.virgil_usage_daily (
  user_id uuid not null references auth.users (id) on delete cascade,
  usage_date date not null default ((timezone('utc', now()))::date),
  recommendations_count integer not null default 0
    check (recommendations_count >= 0),
  uploads_count integer not null default 0
    check (uploads_count >= 0),
  primary key (user_id, usage_date)
);

create index if not exists virgil_usage_daily_user_date_idx
  on public.virgil_usage_daily (user_id, usage_date desc);

alter table public.virgil_usage_daily enable row level security;

drop policy if exists "virgil_usage_daily_select_own" on public.virgil_usage_daily;
create policy "virgil_usage_daily_select_own"
  on public.virgil_usage_daily
  for select
  to authenticated
  using (auth.uid() = user_id);

-- Atomic consume: increments if under limit, returns whether the action was allowed.
create or replace function public.try_consume_virgil_usage(p_action text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_today date := (timezone('utc', now()))::date;
  v_limit integer;
  v_allowed boolean := false;
begin
  if v_uid is null then
    raise exception 'not_authenticated';
  end if;

  if p_action = 'recommendation' then
    v_limit := 3;
  elsif p_action = 'upload' then
    v_limit := 3;
  else
    raise exception 'invalid_action';
  end if;

  insert into public.virgil_usage_daily (user_id, usage_date)
  values (v_uid, v_today)
  on conflict (user_id, usage_date) do nothing;

  if p_action = 'recommendation' then
    update public.virgil_usage_daily
    set recommendations_count = recommendations_count + 1
    where user_id = v_uid
      and usage_date = v_today
      and recommendations_count < v_limit
    returning true into v_allowed;
  else
    update public.virgil_usage_daily
    set uploads_count = uploads_count + 1
    where user_id = v_uid
      and usage_date = v_today
      and uploads_count < v_limit
    returning true into v_allowed;
  end if;

  return coalesce(v_allowed, false);
end;
$$;

comment on function public.try_consume_virgil_usage(text) is
  'Atomically consumes one Virgil daily quota unit (recommendation|upload). Returns false when limit reached.';

grant execute on function public.try_consume_virgil_usage(text) to authenticated;

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
    3,
    3
  from (select 1) as _
  left join public.virgil_usage_daily u
    on u.user_id = v_uid and u.usage_date = v_today;
end;
$$;

comment on function public.get_virgil_usage_today() is
  'Returns today''s Virgil usage counts and hard limits for the current user.';

grant execute on function public.get_virgil_usage_today() to authenticated;
