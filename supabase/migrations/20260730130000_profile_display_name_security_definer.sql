-- Make display-name helper runnable from row-level triggers under RLS.
create or replace function public.profile_display_name(p_user_id uuid)
returns text
language sql
stable
security definer
set search_path = public, auth
as $$
  select coalesce(
    nullif(trim((u.raw_user_meta_data ->> 'username')), ''),
    nullif(trim(split_part(u.email, '@', 1)), ''),
    'user'
  )
  from auth.users u
  where u.id = p_user_id
$$;

notify pgrst, 'reload schema';
