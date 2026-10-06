-- Cover URL snapshot on user_books so reading/favorite lists render without a
-- per-book Google Books / trbooks lookup.

alter table public.user_books
  add column if not exists book_cover_url text;
