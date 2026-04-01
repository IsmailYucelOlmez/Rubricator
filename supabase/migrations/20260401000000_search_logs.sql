-- Search analytics: Open Library queries + optional book clicks.
-- Run via Supabase CLI or SQL Editor.

create table if not exists public.search_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete set null,
  query text not null,
  book_id text,
  created_at timestamptz not null default now()
);

create index if not exists search_logs_query_idx on public.search_logs using btree (query);

create index if not exists search_logs_created_at_idx on public.search_logs using btree (created_at desc);

create index if not exists search_logs_book_id_idx on public.search_logs using btree (book_id)
  where book_id is not null;

alter table public.search_logs enable row level security;

-- Inserts: anonymous (user_id null) or current user only.
create policy "search_logs_insert_own_or_anon"
  on public.search_logs
  for insert
  to anon, authenticated
  with check (user_id is null or user_id = auth.uid());

-- Reads: anonymous rows or own rows (see global popular stats via RPCs below).
create policy "search_logs_select_own_or_anon_rows"
  on public.search_logs
  for select
  to anon, authenticated
  using (user_id is null or user_id = auth.uid());

-- Global aggregates (bypass RLS); safe read-only aggregates for discovery UI.
create or replace function public.search_logs_popular_queries(p_limit int default 10)
returns table (query text, hit_count bigint)
language sql
stable
security definer
set search_path = public
as $$
  select
    sl.query,
    count(*)::bigint as hit_count
  from public.search_logs sl
  group by sl.query
  order by hit_count desc
  limit least(coalesce(p_limit, 10), 50);
$$;

create or replace function public.search_logs_popular_book_ids(p_limit int default 10)
returns table (book_id text, hit_count bigint)
language sql
stable
security definer
set search_path = public
as $$
  select
    sl.book_id,
    count(*)::bigint as hit_count
  from public.search_logs sl
  where sl.book_id is not null
  group by sl.book_id
  order by hit_count desc
  limit least(coalesce(p_limit, 10), 50);
$$;

grant execute on function public.search_logs_popular_queries(int) to anon, authenticated;
grant execute on function public.search_logs_popular_book_ids(int) to anon, authenticated;
