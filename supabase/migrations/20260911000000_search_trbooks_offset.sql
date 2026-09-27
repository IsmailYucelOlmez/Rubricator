-- Adds pagination (p_offset) to search_trbooks and a stable tiebreaker (id) so
-- pages never overlap or skip rows when similarity/reviews_count tie.
-- The old 2-arg signature is dropped so PostgREST has no overload ambiguity.

drop function if exists public.search_trbooks(text, integer);

create or replace function public.search_trbooks(
  p_query text,
  p_limit integer default 20,
  p_offset integer default 0
)
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
      t.reviews_count desc nulls last,
      t.id
    limit p_limit
    offset greatest(p_offset, 0);
end;
$$;

grant execute on function public.search_trbooks(text, integer, integer) to anon, authenticated;
