-- External reviews: description, display name, and owner delete.

alter table public.external_reviews
  add column if not exists description text not null default '';

alter table public.external_reviews
  add column if not exists user_name text;

drop trigger if exists trg_external_reviews_fill_user_name on public.external_reviews;
create trigger trg_external_reviews_fill_user_name
before insert or update on public.external_reviews
for each row
execute function public.fill_actor_name_from_auth();

update public.external_reviews r
set user_name = public.profile_display_name(r.user_id)
where user_name is null
   or char_length(trim(user_name)) = 0;

drop policy if exists "external_reviews_delete_own" on public.external_reviews;
create policy "external_reviews_delete_own"
  on public.external_reviews
  for delete
  to authenticated
  using (user_id = auth.uid());

-- Ensure PostgREST picks up new columns immediately.
notify pgrst, 'reload schema';
