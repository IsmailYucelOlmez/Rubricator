-- Snapshot metadata when a user marks a book completed (stats + offline-friendly reads).

alter table public.user_books
  add column if not exists book_title text,
  add column if not exists book_author text,
  add column if not exists book_categories jsonb,
  add column if not exists completed_at timestamptz;

create index if not exists user_books_user_completed_at_idx
  on public.user_books (user_id, completed_at desc nulls last)
  where status = 'completed';
