-- Genre-based Google Books cache for home + genre pages.

create table if not exists public.genre_books_cache (
  genre_key text primary key,
  books_json jsonb not null default '[]'::jsonb,
  total_count int not null default 0,
  allowed_weekdays smallint[] not null default array[1, 3, 5],
  fetch_completed boolean not null default false,
  is_active boolean not null default true,
  last_fetch_status text,
  last_fetch_error text,
  last_fetch_at timestamptz,
  updated_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint genre_books_cache_status_check check (
    last_fetch_status is null or last_fetch_status in ('success', 'error')
  )
);

create index if not exists genre_books_cache_updated_at_idx
  on public.genre_books_cache using btree (updated_at desc);

create or replace function public.set_genre_books_cache_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_genre_books_cache_updated_at on public.genre_books_cache;
create trigger trg_genre_books_cache_updated_at
before update on public.genre_books_cache
for each row
execute function public.set_genre_books_cache_updated_at();

alter table public.genre_books_cache enable row level security;

create policy "genre_books_cache_select"
  on public.genre_books_cache
  for select
  to anon, authenticated
  using (true);

create policy "genre_books_cache_insert"
  on public.genre_books_cache
  for insert
  to anon, authenticated
  with check (true);

create policy "genre_books_cache_update"
  on public.genre_books_cache
  for update
  to anon, authenticated
  using (true)
  with check (true);
