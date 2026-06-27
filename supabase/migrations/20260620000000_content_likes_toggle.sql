-- Per-user like tracking with toggle support for quotes and reviews.

create table if not exists public.quote_likes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  quote_id uuid not null references public.quotes (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, quote_id)
);

create table if not exists public.review_likes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  review_id uuid not null references public.reviews (id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, review_id)
);

create index if not exists quote_likes_quote_id_idx on public.quote_likes (quote_id);
create index if not exists review_likes_review_id_idx on public.review_likes (review_id);

alter table public.quote_likes enable row level security;
alter table public.review_likes enable row level security;

create policy "quote_likes_select_all"
  on public.quote_likes
  for select
  to authenticated
  using (true);

create policy "review_likes_select_all"
  on public.review_likes
  for select
  to authenticated
  using (true);

drop function if exists public.increment_quote_likes(uuid);
drop function if exists public.increment_review_likes(uuid);

create or replace function public.toggle_quote_like(p_quote_id uuid)
returns table (liked boolean, likes_count integer)
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;

  if exists (
    select 1
    from public.quote_likes ql
    where ql.user_id = uid and ql.quote_id = p_quote_id
  ) then
    delete from public.quote_likes
    where user_id = uid and quote_id = p_quote_id;

    update public.quotes
    set likes = greatest(likes - 1, 0)
    where id = p_quote_id;
  else
    insert into public.quote_likes (user_id, quote_id)
    values (uid, p_quote_id);

    update public.quotes
    set likes = likes + 1
    where id = p_quote_id;
  end if;

  return query
  select
    exists (
      select 1
      from public.quote_likes ql
      where ql.user_id = uid and ql.quote_id = p_quote_id
    ) as liked,
    q.likes as likes_count
  from public.quotes q
  where q.id = p_quote_id;
end;
$$;

create or replace function public.toggle_review_like(p_review_id uuid)
returns table (liked boolean, likes_count integer)
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'Not authenticated';
  end if;

  if exists (
    select 1
    from public.review_likes rl
    where rl.user_id = uid and rl.review_id = p_review_id
  ) then
    delete from public.review_likes
    where user_id = uid and review_id = p_review_id;

    update public.reviews
    set likes = greatest(likes - 1, 0)
    where id = p_review_id;
  else
    insert into public.review_likes (user_id, review_id)
    values (uid, p_review_id);

    update public.reviews
    set likes = likes + 1
    where id = p_review_id;
  end if;

  return query
  select
    exists (
      select 1
      from public.review_likes rl
      where rl.user_id = uid and rl.review_id = p_review_id
    ) as liked,
    r.likes as likes_count
  from public.reviews r
  where r.id = p_review_id;
end;
$$;

grant execute on function public.toggle_quote_like(uuid) to authenticated;
grant execute on function public.toggle_review_like(uuid) to authenticated;
