-- Static Turkish book catalog imported from Kaggle datasets (Turkish Book Dataset +
-- E-Commerce Bookstore Dataset), unified into one table with a `source` discriminator.

create table if not exists public.trbooks (
  id uuid primary key default gen_random_uuid(),
  source text not null check (source in ('turkish_book_dataset', 'ecommerce_bookstore')),
  title text not null,
  author text,
  publisher text,
  category text,
  isbn text,
  page_count integer,
  released_year integer,
  published_date date,
  description text,
  language text not null default 'tr',
  rating numeric(3,2),
  reviews_count integer,
  image_url text,
  created_at timestamptz not null default now()
);

create index if not exists trbooks_isbn_idx on public.trbooks using btree (isbn);
create index if not exists trbooks_title_idx on public.trbooks using btree (title);
create index if not exists trbooks_author_idx on public.trbooks using btree (author);

alter table public.trbooks enable row level security;

create policy "trbooks_select"
  on public.trbooks
  for select
  to anon, authenticated
  using (true);
