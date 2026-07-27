-- Allow unauthenticated (anon) users to read public lists and their
-- items/comments/likes. Write policies remain authenticated-only.
-- Mirrors the book_notes_select_public_or_own pattern.

drop policy if exists "lists_select_visible" on public.lists;
create policy "lists_select_visible"
  on public.lists
  for select
  to anon, authenticated
  using (is_public = true or user_id = auth.uid());

drop policy if exists "list_items_select_visible_parent" on public.list_items;
create policy "list_items_select_visible_parent"
  on public.list_items
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.lists l
      where l.id = list_items.list_id
        and (l.is_public = true or l.user_id = auth.uid())
    )
  );

drop policy if exists "list_likes_select_visible_parent" on public.list_likes;
create policy "list_likes_select_visible_parent"
  on public.list_likes
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.lists l
      where l.id = list_likes.list_id
        and (l.is_public = true or l.user_id = auth.uid())
    )
  );

drop policy if exists "list_comments_select_visible_parent" on public.list_comments;
create policy "list_comments_select_visible_parent"
  on public.list_comments
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.lists l
      where l.id = list_comments.list_id
        and (l.is_public = true or l.user_id = auth.uid())
    )
  );
