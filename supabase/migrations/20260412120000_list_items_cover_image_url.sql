-- Store book cover URLs (e.g. Google Books thumbnails) per list item.
alter table public.list_items
  add column if not exists cover_image_url text;

comment on column public.list_items.cover_id is 'Deprecated; use cover_image_url.';
