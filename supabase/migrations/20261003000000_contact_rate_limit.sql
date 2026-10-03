-- Website contact form (edge function `contact`): per-IP rate limit.
-- Only a salted hash of the IP and the time are kept, never the message, and
-- rows older than a day are removed on every call. No RLS policies: only the
-- edge function (service role) can touch this, through contact_allow().
create table if not exists public.contact_submissions (
  id bigint generated always as identity primary key,
  ip_hash text not null,
  created_at timestamptz not null default now()
);

alter table public.contact_submissions enable row level security;

create index if not exists contact_submissions_ip_time_idx
  on public.contact_submissions using btree (ip_hash, created_at);

-- true = allowed (and recorded); false = 3 or more messages in the last hour.
create or replace function public.contact_allow(p_ip_hash text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  recent integer;
begin
  delete from public.contact_submissions
   where created_at < now() - interval '1 day';

  select count(*) into recent
    from public.contact_submissions
   where ip_hash = p_ip_hash
     and created_at > now() - interval '1 hour';

  if recent >= 3 then
    return false;
  end if;

  insert into public.contact_submissions (ip_hash) values (p_ip_hash);
  return true;
end;
$$;

revoke all on function public.contact_allow(text) from public, anon, authenticated;
grant execute on function public.contact_allow(text) to service_role;
