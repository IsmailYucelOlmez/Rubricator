-- Genre-browse support: the app already maps each home-page genre key to a
-- Turkish keyword (e.g. 'science_fiction' -> 'bilim kurgu', see
-- HomeRemoteDataSource.turkishGenreQueries) for querying Google Books.
-- trbooks' `category` column doesn't share that fiction-subgenre taxonomy
-- (it's coarse buckets like 'literature'/'academic'), so genre browsing
-- reuses the same keyword against title/description instead, ranked by
-- rating/reviews_count rather than text similarity (a broad keyword match,
-- not a precise search).

create index if not exists trbooks_description_trgm_idx
  on public.trbooks using gin (description gin_trgm_ops);

create or replace function public.search_trbooks_by_keyword(
  p_keyword text,
  p_limit integer default 20
)
returns setof public.trbooks
language plpgsql
stable
as $$
declare
  kw text := nullif(trim(coalesce(p_keyword, '')), '');
begin
  if kw is null then
    return;
  end if;

  return query
    select t.*
    from public.trbooks t
    where t.title ilike '%' || kw || '%'
       or t.description ilike '%' || kw || '%'
    order by t.rating desc nulls last, t.reviews_count desc nulls last
    limit p_limit;
end;
$$;

grant execute on function public.search_trbooks_by_keyword(text, integer) to anon, authenticated;
