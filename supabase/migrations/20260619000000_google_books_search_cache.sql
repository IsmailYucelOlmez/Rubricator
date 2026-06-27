-- Google Books search/author result cache (shared across clients).

create table if not exists public.google_books_search_cache (
  cache_key text primary key,
  cache_type text not null,
  books_json jsonb not null default '[]'::jsonb,
  result_count int not null default 0,
  last_fetch_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  constraint google_books_search_cache_type_check check (
    cache_type in ('search', 'author')
  )
);

create index if not exists google_books_search_cache_last_fetch_at_idx
  on public.google_books_search_cache using btree (last_fetch_at desc);

alter table public.google_books_search_cache enable row level security;

create policy "google_books_search_cache_select"
  on public.google_books_search_cache
  for select
  to anon, authenticated
  using (true);

create policy "google_books_search_cache_insert"
  on public.google_books_search_cache
  for insert
  to anon, authenticated
  with check (true);

create policy "google_books_search_cache_update"
  on public.google_books_search_cache
  for update
  to anon, authenticated
  using (true)
  with check (true);
