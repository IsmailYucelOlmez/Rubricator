-- Repair: trbooks_title_idx / trbooks_author_idx (plain btree on the raw
-- title/author columns, from 20260901000000) never actually existed on the
-- live DB — likely the tail of that migration didn't make it into the first
-- SQL Editor paste. Confirmed via `select * from pg_indexes where tablename
-- = 'trbooks'`: only trbooks_pkey, trbooks_isbn_idx, and the *_normalized_*
-- indexes were present. `explain analyze` on `author = 'x'` showed a full
-- Seq Scan (166947 rows removed by filter, ~4.4s) — exactly this missing
-- index. `related()`'s author-exact-match path relies on it.
--
-- Also re-confirms RLS is actually enabled with the intended select policy
-- (`if not exists` makes this safe to run whether or not it's already there).

create index if not exists trbooks_title_idx on public.trbooks using btree (title);
create index if not exists trbooks_author_idx on public.trbooks using btree (author);

alter table public.trbooks enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'trbooks' and policyname = 'trbooks_select'
  ) then
    create policy "trbooks_select"
      on public.trbooks
      for select
      to anon, authenticated
      using (true);
  end if;
end
$$;

analyze public.trbooks;
