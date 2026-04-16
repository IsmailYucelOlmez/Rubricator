-- Profile photo storage bucket + RLS policies.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'profile-photos',
  'profile-photos',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/heic']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'profile_photos_public_read'
  ) then
    create policy "profile_photos_public_read"
      on storage.objects
      for select
      to anon, authenticated
      using (bucket_id = 'profile-photos');
  end if;
end;
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'profile_photos_insert_own_folder'
  ) then
    create policy "profile_photos_insert_own_folder"
      on storage.objects
      for insert
      to authenticated
      with check (
        bucket_id = 'profile-photos'
        and (storage.foldername(name))[1] = auth.uid()::text
      );
  end if;
end;
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'profile_photos_update_own_folder'
  ) then
    create policy "profile_photos_update_own_folder"
      on storage.objects
      for update
      to authenticated
      using (
        bucket_id = 'profile-photos'
        and (storage.foldername(name))[1] = auth.uid()::text
      )
      with check (
        bucket_id = 'profile-photos'
        and (storage.foldername(name))[1] = auth.uid()::text
      );
  end if;
end;
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'profile_photos_delete_own_folder'
  ) then
    create policy "profile_photos_delete_own_folder"
      on storage.objects
      for delete
      to authenticated
      using (
        bucket_id = 'profile-photos'
        and (storage.foldername(name))[1] = auth.uid()::text
      );
  end if;
end;
$$;
