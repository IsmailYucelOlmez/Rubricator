-- Turkish-aware normalized search for trbooks, replacing the raw-column trgm
-- indexes from 20260902000000. Plain `ilike` on the raw title/author is
-- correctness-fragile for Turkish casing (İ/I/ı/i fold inconsistently under
-- Postgres's default `lower()`), which the app's own Google Books matching
-- already works around client-side in
-- lib/features/books/data/utils/google_books_utils.dart (`normalizeSearchText`
-- / `_foldTurkish`). This migration mirrors that exact fold rule in SQL so
-- trbooks search behaves consistently with it, then adds a ranked search RPC
-- (pg_trgm `similarity()`) so results aren't returned in arbitrary index order.

create extension if not exists pg_trgm;

create or replace function public.trbooks_normalize_tr(input text)
returns text
language sql
immutable
parallel safe
as $$
  select nullif(
    trim(
      regexp_replace(
        regexp_replace(
          lower(translate(coalesce(input, ''), 'İIıŞşĞğÇçÖöÜü', 'iiissggccoouu')),
          '[^[:alnum:][:space:]]+', ' ', 'g'
        ),
        '\s+', ' ', 'g'
      )
    ),
    ''
  );
$$;

alter table public.trbooks
  add column if not exists title_normalized text
    generated always as (public.trbooks_normalize_tr(title)) stored,
  add column if not exists author_normalized text
    generated always as (public.trbooks_normalize_tr(author)) stored;

drop index if exists public.trbooks_title_trgm_idx;
drop index if exists public.trbooks_author_trgm_idx;

create index if not exists trbooks_title_normalized_trgm_idx
  on public.trbooks using gin (title_normalized gin_trgm_ops);
create index if not exists trbooks_author_normalized_trgm_idx
  on public.trbooks using gin (author_normalized gin_trgm_ops);

create index if not exists trbooks_title_normalized_btree_idx
  on public.trbooks using btree (title_normalized);
create index if not exists trbooks_author_normalized_btree_idx
  on public.trbooks using btree (author_normalized);

create or replace function public.search_trbooks(p_query text, p_limit integer default 20)
returns setof public.trbooks
language plpgsql
stable
as $$
declare
  q text := public.trbooks_normalize_tr(p_query);
begin
  if q is null or q = '' then
    return;
  end if;

  return query
    select t.*
    from public.trbooks t
    where t.title_normalized ilike '%' || q || '%'
       or t.author_normalized ilike '%' || q || '%'
    order by
      greatest(
        similarity(t.title_normalized, q),
        similarity(t.author_normalized, q)
      ) desc,
      t.reviews_count desc nulls last
    limit p_limit;
end;
$$;

grant execute on function public.trbooks_normalize_tr(text) to anon, authenticated;
grant execute on function public.search_trbooks(text, integer) to anon, authenticated;
