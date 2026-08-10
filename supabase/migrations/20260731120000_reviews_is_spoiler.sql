-- Mark app reviews that contain spoilers; default false for existing rows.
alter table public.reviews
  add column if not exists is_spoiler boolean not null default false;

notify pgrst, 'reload schema';
