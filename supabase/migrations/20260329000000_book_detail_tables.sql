create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  book_id text not null,
  content text not null check (char_length(trim(content)) >= 10),
  created_at timestamptz not null default now()
);

create table if not exists public.external_reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  book_id text not null,
  title text not null,
  url text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.quotes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  book_id text not null,
  content text not null check (char_length(trim(content)) > 0),
  likes integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.ratings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  book_id text not null,
  rating integer not null check (rating between 1 and 5),
  created_at timestamptz not null default now(),
  unique (user_id, book_id)
);

alter table public.reviews enable row level security;
alter table public.external_reviews enable row level security;
alter table public.quotes enable row level security;
alter table public.ratings enable row level security;

create policy "reviews_select_all"
  on public.reviews
  for select
  to authenticated
  using (true);

create policy "reviews_insert_own"
  on public.reviews
  for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "reviews_update_own"
  on public.reviews
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "reviews_delete_own"
  on public.reviews
  for delete
  to authenticated
  using (user_id = auth.uid());

create policy "external_reviews_select_all"
  on public.external_reviews
  for select
  to authenticated
  using (true);

create policy "external_reviews_insert_own"
  on public.external_reviews
  for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "quotes_select_all"
  on public.quotes
  for select
  to authenticated
  using (true);

create policy "quotes_insert_own"
  on public.quotes
  for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "quotes_update_all_authenticated"
  on public.quotes
  for update
  to authenticated
  using (true)
  with check (true);

create policy "ratings_select_all"
  on public.ratings
  for select
  to authenticated
  using (true);

create policy "ratings_insert_own"
  on public.ratings
  for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "ratings_update_own"
  on public.ratings
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());
