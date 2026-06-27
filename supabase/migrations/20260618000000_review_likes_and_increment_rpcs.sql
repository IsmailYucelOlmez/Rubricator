-- Review likes + atomic increment RPCs for quotes and reviews.

alter table public.reviews
  add column if not exists likes integer not null default 0;

create or replace function public.increment_quote_likes(quote_id uuid)
returns void
language sql
security definer
set search_path = public
as $$
  update public.quotes set likes = likes + 1 where id = quote_id;
$$;

create or replace function public.increment_review_likes(review_id uuid)
returns void
language sql
security definer
set search_path = public
as $$
  update public.reviews set likes = likes + 1 where id = review_id;
$$;

grant execute on function public.increment_quote_likes(uuid) to authenticated;
grant execute on function public.increment_review_likes(uuid) to authenticated;
