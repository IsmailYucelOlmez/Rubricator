-- Social lists module schema (lists + items + likes + comments + saved lists)
-- Designed for profile-integrated discovery and personal curation.

create table if not exists public.lists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  user_name text,
  title text not null check (char_length(trim(title)) > 0),
  description text not null default '',
  is_public boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.list_items (
  id uuid primary key default gen_random_uuid(),
  list_id uuid not null references public.lists (id) on delete cascade,
  book_id text not null,
  book_title text,
  book_author text,
  cover_id integer,
  order_index integer not null default 0,
  note text,
  created_at timestamptz not null default now(),
  unique (list_id, book_id)
);

create table if not exists public.list_likes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  list_id uuid not null references public.lists (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, list_id)
);

create table if not exists public.list_comments (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  user_name text,
  list_id uuid not null references public.lists (id) on delete cascade,
  content text not null check (char_length(trim(content)) > 0),
  created_at timestamptz not null default now()
);

create table if not exists public.saved_lists (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  list_id uuid not null references public.lists (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, list_id)
);

create index if not exists lists_user_id_idx on public.lists using btree (user_id);
create index if not exists lists_created_at_idx on public.lists using btree (created_at desc);
create index if not exists list_items_list_id_idx on public.list_items using btree (list_id);
create index if not exists list_items_order_idx on public.list_items using btree (list_id, order_index);
create index if not exists list_likes_list_id_idx on public.list_likes using btree (list_id);
create index if not exists list_comments_list_id_idx on public.list_comments using btree (list_id);
create index if not exists saved_lists_user_id_idx on public.saved_lists using btree (user_id);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_lists_set_updated_at on public.lists;
create trigger trg_lists_set_updated_at
before update on public.lists
for each row
execute function public.set_updated_at();

alter table public.lists enable row level security;
alter table public.list_items enable row level security;
alter table public.list_likes enable row level security;
alter table public.list_comments enable row level security;
alter table public.saved_lists enable row level security;

-- LISTS
create policy "lists_select_visible"
  on public.lists
  for select
  to authenticated
  using (is_public = true or user_id = auth.uid());

create policy "lists_insert_own"
  on public.lists
  for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "lists_update_own"
  on public.lists
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "lists_delete_own"
  on public.lists
  for delete
  to authenticated
  using (user_id = auth.uid());

-- LIST ITEMS
create policy "list_items_select_visible_parent"
  on public.list_items
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.lists l
      where l.id = list_items.list_id
        and (l.is_public = true or l.user_id = auth.uid())
    )
  );

create policy "list_items_modify_owner"
  on public.list_items
  for all
  to authenticated
  using (
    exists (
      select 1
      from public.lists l
      where l.id = list_items.list_id
        and l.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1
      from public.lists l
      where l.id = list_items.list_id
        and l.user_id = auth.uid()
    )
  );

-- LIST LIKES
create policy "list_likes_select_visible_parent"
  on public.list_likes
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.lists l
      where l.id = list_likes.list_id
        and (l.is_public = true or l.user_id = auth.uid())
    )
  );

create policy "list_likes_insert_own"
  on public.list_likes
  for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "list_likes_delete_own"
  on public.list_likes
  for delete
  to authenticated
  using (user_id = auth.uid());

-- LIST COMMENTS
create policy "list_comments_select_visible_parent"
  on public.list_comments
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.lists l
      where l.id = list_comments.list_id
        and (l.is_public = true or l.user_id = auth.uid())
    )
  );

create policy "list_comments_insert_own"
  on public.list_comments
  for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "list_comments_delete_own"
  on public.list_comments
  for delete
  to authenticated
  using (user_id = auth.uid());

-- SAVED LISTS
create policy "saved_lists_select_own"
  on public.saved_lists
  for select
  to authenticated
  using (user_id = auth.uid());

create policy "saved_lists_insert_own"
  on public.saved_lists
  for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "saved_lists_delete_own"
  on public.saved_lists
  for delete
  to authenticated
  using (user_id = auth.uid());
