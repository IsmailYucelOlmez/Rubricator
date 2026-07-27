create table if not exists public.book_notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  book_id text not null,
  page_number integer null check (page_number is null or page_number > 0),
  chapter_title text null,
  note_title text not null check (char_length(trim(note_title)) > 0),
  note_content text not null check (char_length(trim(note_content)) > 0),
  tags text[] not null default '{}',
  is_public boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists book_notes_book_id_public_created_idx
  on public.book_notes (book_id, is_public, created_at desc);

create index if not exists book_notes_user_id_created_idx
  on public.book_notes (user_id, created_at desc);

create index if not exists book_notes_user_id_tags_idx
  on public.book_notes using gin (tags);

alter table public.book_notes enable row level security;

create policy "book_notes_select_public_or_own"
  on public.book_notes
  for select
  to anon, authenticated
  using (is_public = true or user_id = auth.uid());

create policy "book_notes_insert_own"
  on public.book_notes
  for insert
  to authenticated
  with check (user_id = auth.uid());

create policy "book_notes_update_own"
  on public.book_notes
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "book_notes_delete_own"
  on public.book_notes
  for delete
  to authenticated
  using (user_id = auth.uid());

create or replace function public.set_book_notes_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists book_notes_updated_at on public.book_notes;

create trigger book_notes_updated_at
  before update on public.book_notes
  for each row
  execute function public.set_book_notes_updated_at();
