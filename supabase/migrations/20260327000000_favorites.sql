-- Run in Supabase SQL Editor or via CLI. RLS: users only see/modify their own rows.

create table if not exists public.favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  book_id text not null,
  created_at timestamptz not null default now(),
  unique (user_id, book_id)
);

alter table public.favorites enable row level security;

create policy "favorites_select_own"
  on public.favorites
  for select
  to authenticated
  using (user_id = auth.uid());

create policy "favorites_insert_own"
  on public.favorites
  for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "favorites_delete_own"
  on public.favorites
  for delete
  to authenticated
  using (user_id = auth.uid());

create policy "favorites_update_own"
  on public.favorites
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
