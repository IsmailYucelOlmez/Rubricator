-- One-time bulk import of the two Kaggle Turkish book CSVs into public.trbooks,
-- for the Supabase Dashboard workflow (no psql/CLI required):
--
--   1. Run supabase/migrations/20260901000000_trbooks_table.sql in the SQL Editor
--      first (creates public.trbooks).
--   2. In Table Editor, "Import data from CSV" -> create a NEW table named
--      stg_turkish_book_dataset from Turkish_Book_Dataset_Kaggle_V2.csv.
--      Prefer setting every column to `text` in the wizard, but it's not
--      required — every value here goes through public.trbooks_import_safe_*(),
--      which accepts any column type (the wizard sometimes auto-detects
--      bigint/numeric/date regardless of what you pick).
--   3. Same for a table named stg_ecommerce_bookstore from books.csv.
--   4. Paste this whole file into the SQL Editor and run it as one query.
--      It transforms + inserts into public.trbooks, then drops both staging
--      tables — nothing extra is left behind.

-- Clears out any partial data from a previous failed run so this script is
-- safe to re-run from scratch (nothing else reads from trbooks yet).
truncate table public.trbooks;
drop function if exists public.trbooks_import_safe_int(text);
drop function if exists public.trbooks_import_safe_numeric(text);
drop function if exists public.trbooks_import_safe_date(text);

-- Accept `anyelement` (not `text`) because the CSV import wizard sometimes
-- auto-detects a staging column as bigint/numeric/date instead of text even
-- when told otherwise — casting to text here handles either case.
create or replace function public.trbooks_import_safe_int(val anyelement) returns integer
language plpgsql as $$
begin
  return nullif(regexp_replace(coalesce(val::text, ''), '[^0-9-]', '', 'g'), '')::integer;
exception when others then
  return null;
end;
$$;

create or replace function public.trbooks_import_safe_numeric(val anyelement) returns numeric
language plpgsql as $$
begin
  return nullif(regexp_replace(coalesce(val::text, ''), '[^0-9.-]', '', 'g'), '')::numeric;
exception when others then
  return null;
end;
$$;

create or replace function public.trbooks_import_safe_date(val anyelement) returns date
language plpgsql as $$
begin
  return nullif(trim(coalesce(val::text, '')), '')::date;
exception when others then
  return null;
end;
$$;

create or replace function public.trbooks_import_safe_text(val anyelement) returns text
language plpgsql as $$
begin
  return nullif(trim(coalesce(val::text, '')), '');
exception when others then
  return null;
end;
$$;

-- 1. Turkish Book Dataset -----------------------------------------------------

insert into public.trbooks (
  source, title, author, publisher, category, isbn,
  page_count, released_year, description, language
)
select
  'turkish_book_dataset',
  public.trbooks_import_safe_text(book_title),
  public.trbooks_import_safe_text(book_author),
  public.trbooks_import_safe_text(book_publisher),
  public.trbooks_import_safe_text(book_category_name),
  public.trbooks_import_safe_text(book_productcode),
  public.trbooks_import_safe_int(book_page_count),
  case
    when public.trbooks_import_safe_int(book_released_year) between 1000 and 2100
    then public.trbooks_import_safe_int(book_released_year)
  end,
  public.trbooks_import_safe_text(book_detail),
  'tr'
from public.stg_turkish_book_dataset
where public.trbooks_import_safe_text(book_title) is not null;

-- 2. E-Commerce Bookstore Dataset ---------------------------------------------

insert into public.trbooks (
  source, title, author, publisher, isbn, page_count, published_date,
  language, rating, reviews_count, image_url
)
select
  'ecommerce_bookstore',
  public.trbooks_import_safe_text(title),
  public.trbooks_import_safe_text(author),
  public.trbooks_import_safe_text(publisher),
  public.trbooks_import_safe_text(isbn),
  public.trbooks_import_safe_int(page),
  public.trbooks_import_safe_date(date),
  coalesce(
    case
      when language::text ilike '%türk%' or language::text ilike '%turk%' then 'tr'
      when language::text ilike '%ingiliz%' or language::text ilike '%english%' then 'en'
      else lower(public.trbooks_import_safe_text(language))
    end,
    'tr'
  ),
  public.trbooks_import_safe_numeric(rating),
  public.trbooks_import_safe_int(reviews),
  public.trbooks_import_safe_text(image)
from public.stg_ecommerce_bookstore
where public.trbooks_import_safe_text(title) is not null;

-- Cleanup ----------------------------------------------------------------------

drop table if exists public.stg_turkish_book_dataset;
drop table if exists public.stg_ecommerce_bookstore;
drop function if exists public.trbooks_import_safe_int(anyelement);
drop function if exists public.trbooks_import_safe_numeric(anyelement);
drop function if exists public.trbooks_import_safe_date(anyelement);
drop function if exists public.trbooks_import_safe_text(anyelement);

-- Sanity check.
select source, count(*) from public.trbooks group by source;
