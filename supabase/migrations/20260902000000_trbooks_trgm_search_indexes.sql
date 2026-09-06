-- trbooks_select queries use leading-wildcard ilike ('%term%') for search, which
-- the plain btree indexes from 20260901000000_trbooks_table.sql cannot use — on
-- ~167k rows this falls back to a sequential scan and can exceed the statement
-- timeout (observed as intermittent 500s from the search screen). Trigram GIN
-- indexes make leading-wildcard ilike fast.

create extension if not exists pg_trgm;

drop index if exists public.trbooks_title_idx;
drop index if exists public.trbooks_author_idx;

create index if not exists trbooks_title_trgm_idx
  on public.trbooks using gin (title gin_trgm_ops);

create index if not exists trbooks_author_trgm_idx
  on public.trbooks using gin (author gin_trgm_ops);
