-- Let users delete their own quotes (the book detail page now offers
-- edit/delete on a user's quotes). Editing is already covered by
-- "quotes_update_own" (20260926000000_rls_hardening.sql). quote_likes rows
-- cascade on delete.
drop policy if exists "quotes_delete_own" on public.quotes;
create policy "quotes_delete_own"
  on public.quotes
  for delete
  to authenticated
  using (user_id = auth.uid());

notify pgrst, 'reload schema';
