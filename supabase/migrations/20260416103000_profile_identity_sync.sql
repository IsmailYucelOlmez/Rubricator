-- Keep list/list_comment usernames aligned with auth metadata.

create or replace function public.profile_display_name(p_user_id uuid)
returns text
language sql
stable
as $$
  select coalesce(
    nullif(trim((u.raw_user_meta_data ->> 'username')), ''),
    nullif(trim(split_part(u.email, '@', 1)), ''),
    'user'
  )
  from auth.users u
  where u.id = p_user_id
$$;

create or replace function public.fill_actor_name_from_auth()
returns trigger
language plpgsql
as $$
begin
  if new.user_name is null or char_length(trim(new.user_name)) = 0 then
    new.user_name := public.profile_display_name(new.user_id);
  end if;
  return new;
end;
$$;

drop trigger if exists trg_lists_fill_user_name on public.lists;
create trigger trg_lists_fill_user_name
before insert or update on public.lists
for each row
execute function public.fill_actor_name_from_auth();

drop trigger if exists trg_list_comments_fill_user_name on public.list_comments;
create trigger trg_list_comments_fill_user_name
before insert or update on public.list_comments
for each row
execute function public.fill_actor_name_from_auth();

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'list_comments'
      and policyname = 'list_comments_update_own'
  ) then
    create policy "list_comments_update_own"
      on public.list_comments
      for update
      to authenticated
      using (user_id = auth.uid())
      with check (user_id = auth.uid());
  end if;
end;
$$;

update public.lists l
set user_name = public.profile_display_name(l.user_id)
where user_name is null
   or char_length(trim(user_name)) = 0
   or user_name like 'user_%';

update public.list_comments c
set user_name = public.profile_display_name(c.user_id)
where user_name is null
   or char_length(trim(user_name)) = 0
   or user_name like 'user_%';
