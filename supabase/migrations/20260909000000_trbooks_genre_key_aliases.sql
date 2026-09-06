-- D&R (dr.com.tr) has a single combined "Korku Gerilim" category for both
-- `thriller` and `horror` — scrape-tr-books scrapes it once per week under
-- whichever of the two genre keys the cron happens to run first (currently
-- always `thriller`, since it's scheduled 5 minutes before `horror`), and
-- the second one then finds every candidate's ISBN already present and
-- inserts nothing. Left as `genre_key = p_genre_key` exact-match, this
-- means `horror`'s home section would never get its own tagged rows and
-- would permanently fall back to the Google Books cache.
--
-- Fix on the read side rather than the scrape/insert side: querying for
-- either `thriller` or `horror` returns rows tagged with either value,
-- since they're the same real-world category on this source. Whichever
-- genre actually claims the tag when scraped no longer matters.
create or replace function public.search_trbooks_by_genre_key(
  p_genre_key text,
  p_limit integer default 20
)
returns setof public.trbooks
language sql
stable
as $$
  select *
  from public.trbooks
  where genre_key = any(
    case p_genre_key
      when 'thriller' then array['thriller', 'horror']
      when 'horror' then array['thriller', 'horror']
      else array[p_genre_key]
    end
  )
  order by rating desc nulls last, reviews_count desc nulls last, scraped_at desc nulls last
  limit p_limit;
$$;

grant execute on function public.search_trbooks_by_genre_key(text, integer) to anon, authenticated;
