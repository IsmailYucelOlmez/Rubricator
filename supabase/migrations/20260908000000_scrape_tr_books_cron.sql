-- Schedule scrape-tr-books edge function — weekly, Sunday, one small
-- invocation PER GENRE (staggered 5 minutes apart starting 04:00 UTC)
-- rather than one invocation doing all 7 genres. A single do-everything
-- call hit Supabase's WORKER_RESOURCE_LIMIT in production (too much
-- aggregate relay/network work for one function call's compute budget);
-- splitting by genre keeps each call small. 04:00 UTC is an hour after and
-- a different day than the Mon/Wed/Fri 03:00 UTC warm-genre-cache job, so
-- the two schedules never overlap.
-- Requires pg_cron + pg_net. Vault secrets (Dashboard → Project Settings → Vault):
--   project_url  = https://<project-ref>.supabase.co
--   service_role_key = service role JWT
-- Safe no-op locally if extensions or secrets are missing.

do $$
declare
  project_url text;
  service_key text;
  job_id bigint;
  genre_key text;
  minute_offset int;
  genre_keys text[] := array[
    'popular_fiction', 'fantasy', 'science_fiction',
    'romance', 'mystery', 'thriller', 'horror'
  ];
begin
  if not exists (select 1 from pg_extension where extname = 'pg_cron') then
    raise notice 'pg_cron not available; skip scrape-tr-books-weekly schedule';
    return;
  end if;

  if not exists (select 1 from pg_extension where extname = 'pg_net') then
    raise notice 'pg_net not available; skip scrape-tr-books-weekly schedule';
    return;
  end if;

  begin
    select decrypted_secret into project_url
    from vault.decrypted_secrets
    where name = 'project_url'
    limit 1;

    select decrypted_secret into service_key
    from vault.decrypted_secrets
    where name = 'service_role_key'
    limit 1;
  exception
    when undefined_table then
      raise notice 'vault not available; invoke POST /functions/v1/scrape-tr-books manually';
      return;
  end;

  if project_url is null or service_key is null then
    raise notice
      'Vault secrets project_url / service_role_key missing; '
      'invoke POST /functions/v1/scrape-tr-books manually or via Dashboard cron';
    return;
  end if;

  -- Drop the old single do-everything job, if it exists from before genre
  -- splitting was introduced.
  select jobid into job_id from cron.job where jobname = 'scrape-tr-books-weekly' limit 1;
  if job_id is not null then
    perform cron.unschedule(job_id);
  end if;

  for i in 1 .. array_length(genre_keys, 1) loop
    genre_key := genre_keys[i];
    minute_offset := (i - 1) * 5;

    select jobid into job_id
    from cron.job
    where jobname = 'scrape-tr-books-weekly-' || genre_key
    limit 1;

    if job_id is not null then
      perform cron.unschedule(job_id);
    end if;

    perform cron.schedule(
      'scrape-tr-books-weekly-' || genre_key,
      minute_offset || ' 4 * * 0',
      format(
        $cron$
        select net.http_post(
          url := %L || '/functions/v1/scrape-tr-books',
          headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || %L
          ),
          body := jsonb_build_object('genreKey', %L)
        ) as request_id;
        $cron$,
        project_url,
        service_key,
        genre_key
      )
    );
  end loop;

  raise notice 'Scheduled scrape-tr-books-weekly-* for 7 genres (Sunday 04:00-04:30 UTC, 5 min apart)';
exception
  when others then
    raise notice
      'Could not schedule scrape-tr-books-weekly-*: %. '
      'Deploy scrape-tr-books and invoke it manually (with a genreKey) once to seed trbooks.',
      sqlerrm;
end $$;
