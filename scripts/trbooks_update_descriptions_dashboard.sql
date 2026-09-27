-- One-time backfill of public.trbooks.description from the merged, enriched
-- Turkish book dataset produced by the bookapp-api pipeline (Kaggle Turkish
-- Book Dataset + Kitapyurdu scrape + Google Books/OpenLibrary fallbacks),
-- for the Supabase Dashboard workflow (no psql/CLI required):
--
--   1. In Table Editor, "Import data from CSV" -> create a NEW table named
--      stg_merged_tr_books from merged_tr_books.csv (isbn13, isbn10, title,
--      authors, description, simple_categories, published_year, source,
--      language, thumbnail).
--   2. Paste this whole file into the SQL Editor and run it as one query.
--      It only UPDATEs rows in public.trbooks whose description is
--      currently null/blank — it never truncates, deletes, or overwrites
--      an existing description, and it drops the staging table + index
--      when done, so nothing extra is left behind.
--
-- Note: an earlier version of this script normalized isbn/description with
-- a plpgsql function that had an `exception when others` block. Every call
-- to a function with an exception handler opens a subtransaction, and that
-- ran once per staging row during the join — with ~141k rows that overhead
-- was enough to blow past the Dashboard SQL Editor's connection timeout.
-- This version precomputes plain (no-exception) normalized columns on the
-- staging table first, so the actual join against trbooks is a cheap
-- hash join with no per-row subtransactions.

-- Precompute normalized join columns once, no join yet (fast: 141k rows).
alter table public.stg_merged_tr_books
  add column if not exists isbn13_norm text,
  add column if not exists isbn10_norm text,
  add column if not exists description_clean text;

update public.stg_merged_tr_books
set isbn13_norm = nullif(regexp_replace(coalesce(isbn13::text, ''), '[^0-9]', '', 'g'), ''),
    isbn10_norm = nullif(regexp_replace(coalesce(isbn10::text, ''), '[^0-9]', '', 'g'), ''),
    description_clean = nullif(trim(coalesce(description::text, '')), '');

create index if not exists stg_merged_tr_books_isbn13_norm_idx
  on public.stg_merged_tr_books (isbn13_norm);
create index if not exists stg_merged_tr_books_isbn10_norm_idx
  on public.stg_merged_tr_books (isbn10_norm);

-- Sanity check (before): how many trbooks rows are missing a description.
select 'before' as stage, source, count(*)
from public.trbooks
where description is null or trim(description) = ''
group by source;

-- Pass 1: match on isbn13.
update public.trbooks t
set description = s.description_clean
from public.stg_merged_tr_books s
where regexp_replace(t.isbn, '[^0-9]', '', 'g') = s.isbn13_norm
  and s.isbn13_norm is not null
  and (t.description is null or trim(t.description) = '')
  and s.description_clean is not null;

-- Pass 2: fallback match on isbn10 for rows still missing a description.
update public.trbooks t
set description = s.description_clean
from public.stg_merged_tr_books s
where regexp_replace(t.isbn, '[^0-9]', '', 'g') = s.isbn10_norm
  and s.isbn10_norm is not null
  and (t.description is null or trim(t.description) = '')
  and s.description_clean is not null;

-- Cleanup ----------------------------------------------------------------------

drop table if exists public.stg_merged_tr_books;

-- Sanity check (after): should be lower than the "before" counts above.
select 'after' as stage, source, count(*)
from public.trbooks
where description is null or trim(description) = ''
group by source;
