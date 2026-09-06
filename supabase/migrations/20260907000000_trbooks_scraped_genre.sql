-- Extends `trbooks` (previously a static one-time Kaggle import) to also
-- hold rows live-scraped weekly from Turkish bookstore sites (Kitapyurdu
-- first, more sites later — see supabase/functions/scrape-tr-books), tagged
-- with the app's own home-page genre taxonomy (fantasy/science_fiction/
-- romance/mystery/thriller/horror/popular_fiction) at insert time instead of
-- relying on the fuzzy title/description ILIKE match in
-- search_trbooks_by_keyword.

alter table public.trbooks drop constraint if exists trbooks_source_check;

alter table public.trbooks add constraint trbooks_source_check check (
  source in (
    'turkish_book_dataset', 'ecommerce_bookstore', 'kitapyurdu_scrape', 'dr_scrape'
  )
);

alter table public.trbooks add column if not exists genre_key text;
alter table public.trbooks add column if not exists source_url text;
alter table public.trbooks add column if not exists scraped_at timestamptz;

create index if not exists trbooks_genre_key_idx
  on public.trbooks using btree (genre_key)
  where genre_key is not null;

-- ISBN uniqueness scoped to scraped rows only (not the whole table): the
-- existing 167k-row Kaggle import may contain duplicate or blank ISBNs that
-- would break a table-wide unique index. The scraper's own dedup check
-- queries `trbooks.isbn` directly before inserting, so this index only
-- needs to guard against the scraper itself racing/retrying. Scoped to
-- every scrape source (not just one site) via the `_scrape` suffix.
create unique index if not exists trbooks_scraped_isbn_unique_idx
  on public.trbooks (isbn)
  where source like '%_scrape' and isbn is not null and isbn <> '';

-- Ana sayfanın genre/popular bölümleri için taksonomiye tam eşleşen sorgu
-- (search_trbooks_by_keyword'ün ILIKE bulanıklığı yerine, sadece scrape
-- edilip genre_key'i dolu olan satırlar için).
create or replace function public.search_trbooks_by_genre_key(
  p_genre_key text,
  p_limit integer default 20
)
returns setof public.trbooks
language sql
stable
as $$
  select *
  from public.trbooks
  where genre_key = p_genre_key
  order by rating desc nulls last, reviews_count desc nulls last, scraped_at desc nulls last
  limit p_limit;
$$;

grant execute on function public.search_trbooks_by_genre_key(text, integer) to anon, authenticated;

-- Gözlemlenebilirlik: her scrape çalıştırmasının genre/kaynak başına özeti
-- (genre_books_cache'teki last_fetch_status/last_fetch_error'a benzer amaç).
create table if not exists public.trbooks_scrape_runs (
  id uuid primary key default gen_random_uuid(),
  genre_key text not null,
  source text not null,
  run_at timestamptz not null default now(),
  candidates_seen integer not null default 0,
  inserted_count integer not null default 0,
  skipped_existing_count integer not null default 0,
  skipped_no_isbn_count integer not null default 0,
  status text not null check (status in ('success', 'partial', 'error')),
  error text
);

alter table public.trbooks_scrape_runs enable row level security;

drop policy if exists "trbooks_scrape_runs_select" on public.trbooks_scrape_runs;

create policy "trbooks_scrape_runs_select"
  on public.trbooks_scrape_runs
  for select
  to anon, authenticated
  using (true);
