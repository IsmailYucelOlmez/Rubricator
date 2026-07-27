-- Store reviewer display names on reviews (same pattern as lists/comments).

alter table public.reviews
  add column if not exists user_name text;

drop trigger if exists trg_reviews_fill_user_name on public.reviews;
create trigger trg_reviews_fill_user_name
before insert or update on public.reviews
for each row
execute function public.fill_actor_name_from_auth();

update public.reviews r
set user_name = public.profile_display_name(r.user_id)
where user_name is null
   or char_length(trim(user_name)) = 0;
