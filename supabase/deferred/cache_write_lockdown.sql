-- DEFERRED: do NOT apply until the app version that treats cache writes as
-- best-effort (try/catch around the saves, see book_repository.dart and
-- home_repository_impl.dart) is what nearly all users run.
--
-- Why it exists: genre_books_cache and google_books_search_cache accept
-- INSERT/UPDATE with `true` for anon and authenticated, so anyone can plant or
-- overwrite the cached books (titles, descriptions, cover URLs) that are then
-- served to every user. It can't be closed yet because the published apps
-- `await` these writes without a try/catch: a rejected write would make book
-- search / the home genre rows throw.
--
-- After the rollout, only the service role (cron edge functions, or a future
-- server-side cache) writes these tables:

drop policy if exists "genre_books_cache_insert" on public.genre_books_cache;
drop policy if exists "genre_books_cache_update" on public.genre_books_cache;
drop policy if exists "google_books_search_cache_insert" on public.google_books_search_cache;
drop policy if exists "google_books_search_cache_update" on public.google_books_search_cache;
-- (Confirm the real policy names first:
--   select tablename, policyname, cmd from pg_policies
--   where tablename in ('genre_books_cache','google_books_search_cache');)
