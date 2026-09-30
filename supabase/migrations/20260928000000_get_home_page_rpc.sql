-- One round trip for the whole home page. The client used to fire one
-- `genre_books_cache` read (plus a second, sequential read for the `en`
-- fallback) and one `search_trbooks_by_genre_key` RPC per section — 7-8 HTTP
-- requests whose slowest one gated the entire page.
--
-- Returns a jsonb object keyed by genre key:
--   { "<genre_key>": { "trbooks": [<trbooks rows>], "cache": <cache row|null> } }
-- `trbooks` is only filled for p_lang = 'tr' (same rule as the client-side
-- `_trbooksHomeBooks`), with the same thriller/horror aliasing as
-- search_trbooks_by_genre_key. `cache` is the p_lang row when it has books,
-- else the `en` row when that has books, else the p_lang row (so its
-- last_fetch_status still reaches the client) — mirroring
-- `_loadHomeCacheWithFallback`. Section priority (trbooks over cache) stays in
-- the client.
--
-- security invoker: reads go through the existing anon/authenticated SELECT
-- policies on trbooks and genre_books_cache.
create or replace function public.get_home_page(
  p_lang text,
  p_genre_keys text[],
  p_limit integer default 10
)
returns jsonb
language sql
stable
security invoker
set search_path = public
as $$
  select coalesce(
    jsonb_object_agg(
      k.genre_key,
      jsonb_build_object(
        'trbooks',
        case
          when p_lang = 'tr' then (
            select coalesce(jsonb_agg(to_jsonb(t) order by t.ord), '[]'::jsonb)
            from (
              select
                b.id, b.isbn, b.title, b.author, b.image_url, b.description,
                b.category, b.source_url, b.source,
                row_number() over (
                  order by b.rating desc nulls last,
                    b.reviews_count desc nulls last,
                    b.scraped_at desc nulls last
                ) as ord
              from public.trbooks b
              where b.genre_key = any(
                case k.genre_key
                  when 'thriller' then array['thriller', 'horror']
                  when 'horror' then array['thriller', 'horror']
                  else array[k.genre_key]
                end
              )
              order by ord
              limit p_limit
            ) t
          )
          else '[]'::jsonb
        end,
        'cache',
        (
          select jsonb_build_object(
            'genre_key', c.genre_key,
            'lang', c.lang,
            'books_json', c.books_json,
            'allowed_weekdays', c.allowed_weekdays,
            'fetch_completed', c.fetch_completed,
            'is_active', c.is_active,
            'last_fetch_at', c.last_fetch_at,
            'last_fetch_status', c.last_fetch_status
          )
          from public.genre_books_cache c
          where c.genre_key = k.genre_key
            and c.lang in (p_lang, 'en')
          order by
            (jsonb_array_length(coalesce(c.books_json, '[]'::jsonb)) > 0) desc,
            (c.lang = p_lang) desc
          limit 1
        )
      )
    ),
    '{}'::jsonb
  )
  from unnest(p_genre_keys) as k(genre_key);
$$;

grant execute on function public.get_home_page(text, text[], integer) to anon, authenticated;
