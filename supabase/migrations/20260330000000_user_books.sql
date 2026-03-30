create table if not exists public.user_books (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  book_id text not null,
  status text not null default 'to_read' check (
    status in ('to_read', 'reading', 'completed', 'dropped', 're_reading')
  ),
  is_favorite boolean not null default false,
  progress integer check (progress is null or (progress between 0 and 100)),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, book_id)
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_user_books_set_updated_at on public.user_books;
create trigger trg_user_books_set_updated_at
before update on public.user_books
for each row
execute function public.set_updated_at();

alter table public.user_books enable row level security;

create policy "user_books_select_own"
  on public.user_books
  for select
  to authenticated
  using (user_id = auth.uid());

create policy "user_books_insert_own"
  on public.user_books
  for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "user_books_update_own"
  on public.user_books
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "user_books_delete_own"
  on public.user_books
  for delete
  to authenticated
  using (user_id = auth.uid());
