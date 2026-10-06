-- `related()` on the book detail page asks PostgREST for
-- `category=eq.<key>&order=rating.desc&limit=11`. trbooks (~167k rows) has no
-- index on category, so big categories ("literature" ~31k rows) sort the
-- whole slice and hit the statement timeout (57014, ~5s) — Turkish related
-- books never loaded for categorized titles. The composite index serves the
-- filter and the `rating desc` (nulls first, PostgREST's default) order.

create index if not exists trbooks_category_rating_idx
  on public.trbooks using btree (category, rating desc);

analyze public.trbooks;
