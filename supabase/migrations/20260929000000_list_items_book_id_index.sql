-- "Which lists contain this book?" (book detail page: list count + the
-- lists page, and the "add to my lists" sheet) filters list_items by
-- book_id. The only existing composite index leads with list_id, so it
-- can't serve that lookup.
create index if not exists list_items_book_id_idx
  on public.list_items using btree (book_id);
