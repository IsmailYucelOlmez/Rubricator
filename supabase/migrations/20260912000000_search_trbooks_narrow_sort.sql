-- search_trbooks previously sorted full-width rows (t.*, incl. description) for
-- every match. Rank on (id, score, reviews_count) only, apply limit/offset, and
-- join back for full columns of just the returned page.

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
    with ranked as (
      select
        t.id,
        t.reviews_count,
        greatest(
          similarity(t.title_normalized, q),
          similarity(t.author_normalized, q)
        ) as score
      from public.trbooks t
      where t.title_normalized ilike '%' || q || '%'
         or t.author_normalized ilike '%' || q || '%'
      order by score desc, t.reviews_count desc nulls last, t.id
      limit p_limit
      offset greatest(p_offset, 0)
    )
    select t.*
    from ranked r
    join public.trbooks t on t.id = r.id
    order by r.score desc, r.reviews_count desc nulls last, r.id;
end;
$$;

grant execute on function public.search_trbooks(text, integer, integer) to anon, authenticated;
