alter table public.ratings
  drop constraint if exists ratings_rating_check;

alter table public.ratings
  add constraint ratings_rating_check
  check (rating between 1 and 10);
