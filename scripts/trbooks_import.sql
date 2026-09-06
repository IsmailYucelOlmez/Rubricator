-- One-time bulk import of the two Kaggle Turkish book CSVs into public.trbooks.
-- Not a schema migration — run manually against the hosted DB after applying
-- supabase/migrations/20260901000000_trbooks_table.sql:
--
--   psql "$DATABASE_URL" -f scripts/trbooks_import.sql
--
-- Requires local file access to the two CSVs (paths below); adjust if they've moved.
-- Uses temp tables + temp helper functions, so nothing here lingers after the session ends.

create or replace function pg_temp.safe_int(txt text) returns integer
language plpgsql as $$
begin
  return nullif(regexp_replace(coalesce(txt, ''), '[^0-9-]', '', 'g'), '')::integer;
exception when others then
  return null;
end;
$$;

create or replace function pg_temp.safe_numeric(txt text) returns numeric
language plpgsql as $$
begin
  return nullif(regexp_replace(coalesce(txt, ''), '[^0-9.-]', '', 'g'), '')::numeric;
exception when others then
  return null;
end;
$$;

create or replace function pg_temp.safe_date(txt text) returns date
language plpgsql as $$
begin
  return nullif(trim(coalesce(txt, '')), '')::date;
exception when others then
  return null;
end;
$$;

-- 1. Turkish Book Dataset -----------------------------------------------------

create temp table stg_turkish_book_dataset (
  book_title text,
  book_publisher text,
  book_author text,
  book_category_name text,
  book_productcode text,
  book_page_count text,
  book_released_year text,
  book_detail text
);

\copy stg_turkish_book_dataset from 'C:/Users/User/Downloads/Turkish_Book_Dataset_Kaggle_V2.csv/Turkish_Book_Dataset_Kaggle_V2.csv' csv header

insert into public.trbooks (
  source, title, author, publisher, category, isbn,
  page_count, released_year, description, language
)
select
  'turkish_book_dataset',
  nullif(trim(book_title), ''),
  nullif(trim(book_author), ''),
  nullif(trim(book_publisher), ''),
  nullif(trim(book_category_name), ''),
  nullif(trim(book_productcode), ''),
  pg_temp.safe_int(book_page_count),
  case
    when pg_temp.safe_int(book_released_year) between 1000 and 2100
    then pg_temp.safe_int(book_released_year)
  end,
  nullif(trim(book_detail), ''),
  'tr'
from stg_turkish_book_dataset
where nullif(trim(book_title), '') is not null;

-- 2. E-Commerce Bookstore Dataset ---------------------------------------------

create temp table stg_ecommerce_bookstore (
  title text,
  author text,
  publisher text,
  page text,
  language text,
  discount_rate text,
  discounted_price text,
  price text,
  rating text,
  reviews text,
  cover text,
  paper text,
  isbn text,
  date text,
  link text,
  image text
);

\copy stg_ecommerce_bookstore from 'C:/Users/User/AppData/Local/Temp/books.csv' csv header

insert into public.trbooks (
  source, title, author, publisher, isbn, page_count, published_date,
  language, rating, reviews_count, image_url
)
select
  'ecommerce_bookstore',
  nullif(trim(title), ''),
  nullif(trim(author), ''),
  nullif(trim(publisher), ''),
  nullif(trim(isbn), ''),
  pg_temp.safe_int(page),
  pg_temp.safe_date(date),
  coalesce(
    case
      when language ilike '%türk%' or language ilike '%turk%' then 'tr'
      when language ilike '%ingiliz%' or language ilike '%english%' then 'en'
      else lower(nullif(trim(language), ''))
    end,
    'tr'
  ),
  pg_temp.safe_numeric(rating),
  pg_temp.safe_int(reviews),
  nullif(trim(image), '')
from stg_ecommerce_bookstore
where nullif(trim(title), '') is not null;

-- Sanity check (also see verification steps in the plan doc).
select source, count(*) from public.trbooks group by source;
