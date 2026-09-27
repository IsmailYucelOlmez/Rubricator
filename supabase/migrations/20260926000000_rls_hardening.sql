-- Security hardening found by replaying every migration in a real Postgres
-- engine with Supabase's default privileges (see xdocs/rls_audit.md).
--
-- Every change here is backward compatible with the published app versions:
-- none of them removes something the client reads or writes.
--
-- NOT included (would break the published apps, see
-- supabase/deferred/cache_write_lockdown.sql): the write policies on
-- genre_books_cache and google_books_search_cache.

-- ---------------------------------------------------------------------------
-- 1. quotes: any signed-in user could UPDATE any row (USING/WITH CHECK true),
--    i.e. rewrite other people's quotes or reassign user_id. The app never
--    updates quotes directly (likes go through toggle_quote_like, a
--    SECURITY DEFINER RPC), so restrict updates to the owner.
-- ---------------------------------------------------------------------------
drop policy if exists "quotes_update_all_authenticated" on public.quotes;
drop policy if exists "quotes_update_own" on public.quotes;
create policy "quotes_update_own"
  on public.quotes
  for update
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- 2. Cron/trigger-only SECURITY DEFINER functions were callable by anyone.
--    Their migrations granted EXECUTE to service_role but never revoked the
--    default PUBLIC/anon/authenticated grants, so /rest/v1/rpc/... let an
--    anonymous caller run the nightly batch, recompute any user's list
--    recommendations, or mark arbitrary users dirty.
-- ---------------------------------------------------------------------------
revoke execute on function public.compute_list_recommendations_for_user(uuid)
  from public, anon, authenticated;
revoke execute on function public.process_dirty_list_recommendations_batch()
  from public, anon, authenticated;
revoke execute on function public.mark_list_recommendation_dirty(uuid)
  from public, anon, authenticated;

-- Trigger functions are only ever invoked by their triggers.
revoke execute on function public.trg_mark_list_recommendation_dirty_from_list_likes()
  from public, anon, authenticated;
revoke execute on function public.trg_mark_list_recommendation_dirty_from_ratings()
  from public, anon, authenticated;
revoke execute on function public.trg_mark_list_recommendation_dirty_from_saved_lists()
  from public, anon, authenticated;
revoke execute on function public.trg_mark_list_recommendation_dirty_from_user_books()
  from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 3. search_logs: rows with user_id IS NULL (anonymous searches, including the
--    ones the API logs for every Virgil query) were readable by anyone,
--    including anon. The app only reads its own rows; "popular searches" go
--    through the SECURITY DEFINER RPCs, which don't need this policy.
--    Anonymous INSERTs keep working (separate policy).
-- ---------------------------------------------------------------------------
drop policy if exists "search_logs_select_own_or_anon_rows" on public.search_logs;
drop policy if exists "search_logs_select_own" on public.search_logs;
create policy "search_logs_select_own"
  on public.search_logs
  for select
  to authenticated
  using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- 4. trbooks_scrape_runs is operational data (scrape status/errors). Only the
--    service role (cron edge function) uses it; nothing in the apps reads it.
-- ---------------------------------------------------------------------------
drop policy if exists "trbooks_scrape_runs_select" on public.trbooks_scrape_runs;

-- ---------------------------------------------------------------------------
-- 5. profile-photos: the SELECT policy let anon/authenticated list every
--    object (enumerating user ids from the folder names). The bucket is
--    public, so serving avatars via getPublicUrl needs no policy; the owner
--    still needs SELECT for upload(upsert: true).
-- ---------------------------------------------------------------------------
drop policy if exists "profile_photos_public_read" on storage.objects;
drop policy if exists "profile_photos_owner_read" on storage.objects;
create policy "profile_photos_owner_read"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'profile-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
