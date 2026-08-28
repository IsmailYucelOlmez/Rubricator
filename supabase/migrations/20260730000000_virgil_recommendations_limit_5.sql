-- Raise Virgil daily recommendation quota from 3 to 5.
-- Upload limit stays at 3 / day.

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
    v_limit := 5;
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
    5,
    3
  from (select 1) as _
  left join public.virgil_usage_daily u
    on u.user_id = v_uid and u.usage_date = v_today;
end;
$$;
