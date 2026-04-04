-- Reading habit logs: minutes + pages per day (multiple entries per day allowed).
-- Aggregations for stats use RPC; RLS restricts rows to auth.uid().

create table if not exists public.reading_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  book_id text,
  date date not null,
  minutes_read integer not null default 0,
  pages_read integer not null default 0,
  created_at timestamptz not null default now(),
  constraint reading_logs_non_negative check (minutes_read >= 0 and pages_read >= 0),
  constraint reading_logs_one_positive check (minutes_read > 0 or pages_read > 0)
);

create index if not exists reading_logs_user_date_idx
  on public.reading_logs using btree (user_id, date);

create index if not exists reading_logs_user_created_at_idx
  on public.reading_logs using btree (user_id, created_at desc);

alter table public.reading_logs enable row level security;

create policy "reading_logs_select_own"
  on public.reading_logs
  for select
  to authenticated
  using (user_id = auth.uid());

create policy "reading_logs_insert_own"
  on public.reading_logs
  for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "reading_logs_delete_own"
  on public.reading_logs
  for delete
  to authenticated
  using (user_id = auth.uid());

-- Summary for totals + distinct active dates (streaks computed in app).
create or replace function public.reading_logs_user_summary()
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select jsonb_build_object(
    'total_minutes', coalesce((
      select sum(rl.minutes_read)::bigint
      from public.reading_logs rl
      where rl.user_id = auth.uid()
    ), 0),
    'total_pages', coalesce((
      select sum(rl.pages_read)::bigint
      from public.reading_logs rl
      where rl.user_id = auth.uid()
    ), 0),
    'active_dates', coalesce((
      select jsonb_agg(q.d order by q.d desc)
      from (
        select distinct rl2.date::date as d
        from public.reading_logs rl2
        where rl2.user_id = auth.uid()
      ) q
    ), '[]'::jsonb)
  );
$$;

grant execute on function public.reading_logs_user_summary() to authenticated;
