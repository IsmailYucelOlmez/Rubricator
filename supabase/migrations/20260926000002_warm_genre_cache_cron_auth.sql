-- The weekly warm-genre-cache cron job called the function with NO
-- Authorization header (headers := '{}'), which only worked while the
-- function was an open endpoint. The function now requires the service key
-- (see supabase/functions/_shared/service_auth.ts), so without this the job
-- would start getting 401 and the genre cache would silently stop refreshing.
--
-- The key is read from Vault when the job RUNS instead of being baked into the
-- command text, so rotating the key needs no re-scheduling.
-- Requires the Vault secrets `project_url` and `service_role_key`, the same
-- ones the scrape-tr-books jobs use.

do $$
declare
  v_job_id bigint;
begin
  if not exists (select 1 from pg_extension where extname = 'pg_net') then
    raise notice 'pg_net not available; skip warm-genre-books-cache schedule';
    return;
  end if;

  if not exists (select 1 from vault.decrypted_secrets where name = 'service_role_key')
     or not exists (select 1 from vault.decrypted_secrets where name = 'project_url') then
    raise notice 'Vault secrets project_url / service_role_key missing; leaving the job untouched';
    return;
  end if;

  select jobid into v_job_id
  from cron.job
  where jobname = 'warm-genre-books-cache-weekly'
  limit 1;

  if v_job_id is not null then
    perform cron.unschedule(v_job_id);
  end if;

  perform cron.schedule(
    'warm-genre-books-cache-weekly',
    '0 2 * * 1',
    $cron$
      select net.http_post(
        url := (select decrypted_secret from vault.decrypted_secrets where name = 'project_url')
               || '/functions/v1/warm-genre-cache',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'Authorization', 'Bearer ' || (
            select decrypted_secret from vault.decrypted_secrets where name = 'service_role_key'
          )
        ),
        body := '{}'::jsonb,
        timeout_milliseconds := 2000
      );
    $cron$
  );
end;
$$;
