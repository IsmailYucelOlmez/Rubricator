-- One-time backfill of public.trbooks.description from the merged, enriched
-- Turkish book dataset produced by the bookapp-api pipeline (Kaggle Turkish
-- Book Dataset + Kitapyurdu scrape + Google Books/OpenLibrary fallbacks).
--
-- Only fills rows where trbooks.description is currently null/blank — never
-- overwrites an existing description, and never touches any other column.
-- Does NOT truncate or delete anything, so scraped catalog rows (source
-- kitapyurdu_scrape/dr_scrape from the scrape-tr-books cron) are untouched
-- except for having their description filled in if it was empty.
--
--   psql "$DATABASE_URL" -f scripts/trbooks_update_descriptions.sql
--
-- Requires local file access to the merged CSV (path below); adjust if it's moved.
-- Uses a temp table, so nothing here lingers after the session ends.

create temp table stg_merged_tr_books (
  isbn13 text,
  isbn10 text,
  title text,
  authors text,
  description text,
  simple_categories text,
  published_year text,
  source text,
  language text,
  thumbnail text
);

\copy stg_merged_tr_books from 'C:/dev/bookapp-api/data/merged_tr_books.csv' csv header

-- Sanity check (before): how many trbooks rows are missing a description.
select 'before' as stage, source, count(*)
from public.trbooks
where description is null or trim(description) = ''
group by source;

-- Pass 1: match on isbn13.
update public.trbooks t
set description = s.description
from stg_merged_tr_books s
where regexp_replace(t.isbn, '[^0-9]', '', 'g') = regexp_replace(s.isbn13, '[^0-9]', '', 'g')
  and nullif(trim(s.isbn13), '') is not null
  and (t.description is null or trim(t.description) = '')
  and nullif(trim(s.description), '') is not null;

-- Pass 2: fallback match on isbn10 for rows still missing a description.
update public.trbooks t
set description = s.description
from stg_merged_tr_books s
where regexp_replace(t.isbn, '[^0-9]', '', 'g') = regexp_replace(s.isbn10, '[^0-9]', '', 'g')
  and nullif(trim(s.isbn10), '') is not null
  and (t.description is null or trim(t.description) = '')
  and nullif(trim(s.description), '') is not null;

drop table if exists stg_merged_tr_books;

-- Sanity check (after): should be lower than the "before" counts above.
select 'after' as stage, source, count(*)
from public.trbooks
where description is null or trim(description) = ''
group by source;
