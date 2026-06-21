-- Schedule warm-genre-cache edge function (Mon/Wed/Fri 03:00 UTC).
-- Requires pg_cron + pg_net. Vault secrets (Dashboard → Project Settings → Vault):
--   project_url  = https://<project-ref>.supabase.co
--   service_role_key = service role JWT
-- Safe no-op locally if extensions or secrets are missing.

do $$
declare
  project_url text;
  service_key text;
  job_id bigint;
begin
  if not exists (select 1 from pg_extension where extname = 'pg_cron') then
    raise notice 'pg_cron not available; skip warm-genre-books-cache schedule';
    return;
  end if;

  if not exists (select 1 from pg_extension where extname = 'pg_net') then
    raise notice 'pg_net not available; skip warm-genre-books-cache schedule';
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
      raise notice 'vault not available; invoke POST /functions/v1/warm-genre-cache manually';
      return;
  end;

  if project_url is null or service_key is null then
    raise notice
      'Vault secrets project_url / service_role_key missing; '
      'invoke POST /functions/v1/warm-genre-cache manually or via Dashboard cron';
    return;
  end if;

  select jobid into job_id
  from cron.job
  where jobname = 'warm-genre-books-cache'
  limit 1;

  if job_id is not null then
    perform cron.unschedule(job_id);
  end if;

  perform cron.schedule(
    'warm-genre-books-cache',
    '0 3 * * 1,3,5',
    format(
      $cron$
      select net.http_post(
        url := %L || '/functions/v1/warm-genre-cache',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || %L
        ),
        body := '{}'::jsonb
      ) as request_id;
      $cron$,
      project_url,
      service_key
    )
  );

  raise notice 'Scheduled warm-genre-books-cache (Mon/Wed/Fri 03:00 UTC)';
exception
  when others then
    raise notice
      'Could not schedule warm-genre-books-cache: %. '
      'Deploy warm-genre-cache and invoke it manually once to seed genre_books_cache.',
      sqlerrm;
end $$;
