-- search_trbooks_by_keyword (20260904000000) filtered the raw `title` column,
-- but title's trigram index lives on `title_normalized` (20260903000000) —
-- the raw `title_trgm_idx` was dropped there. Matching raw `title` had no
-- usable index and timed out/500'd on the 167k-row table. Match
-- title_normalized (with the keyword run through the same normalize
-- function) instead; description keeps its own raw-column trgm index from
-- 20260904000000, so it's left as-is.

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
  normalized_kw text := public.trbooks_normalize_tr(p_keyword);
begin
  if kw is null then
    return;
  end if;

  return query
    select t.*
    from public.trbooks t
    where (normalized_kw is not null and t.title_normalized ilike '%' || normalized_kw || '%')
       or t.description ilike '%' || kw || '%'
    order by t.rating desc nulls last, t.reviews_count desc nulls last
    limit p_limit;
end;
$$;
