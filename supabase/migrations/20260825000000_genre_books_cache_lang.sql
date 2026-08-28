-- Add language dimension to genre_books_cache so Home page recommendations
-- can be cached per locale instead of one shared (English-dominant) row.

alter table public.genre_books_cache
  add column if not exists lang text not null default 'en';

alter table public.genre_books_cache
  drop constraint if exists genre_books_cache_pkey;

alter table public.genre_books_cache
  add constraint genre_books_cache_pkey primary key (genre_key, lang);
