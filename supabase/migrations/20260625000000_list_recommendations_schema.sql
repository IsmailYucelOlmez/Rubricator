-- Phase 1: precomputed list recommendations schema + dirty-flag triggers.

create table if not exists public.list_recommendations (
  user_id uuid not null references auth.users (id) on delete cascade,
  list_id uuid not null references public.lists (id) on delete cascade,
  score numeric(5, 2) not null check (score >= 0 and score <= 100),
  generated_at timestamptz not null default now(),
  primary key (user_id, list_id)
);

create index if not exists list_recommendations_user_score_idx
  on public.list_recommendations (user_id, score desc);

create table if not exists public.user_list_recommendation_state (
  user_id uuid primary key references auth.users (id) on delete cascade,
  recommendation_dirty boolean not null default true,
  last_computed_at timestamptz,
  updated_at timestamptz not null default now()
);

create index if not exists user_list_recommendation_state_dirty_idx
  on public.user_list_recommendation_state (recommendation_dirty)
  where recommendation_dirty = true;

alter table public.list_recommendations enable row level security;
alter table public.user_list_recommendation_state enable row level security;

create policy "list_recommendations_select_own"
  on public.list_recommendations
  for select
  to authenticated
  using (user_id = auth.uid());

create policy "list_recommendation_state_select_own"
  on public.user_list_recommendation_state
  for select
  to authenticated
  using (user_id = auth.uid());

-- Service role / SECURITY DEFINER functions write recommendations.

create or replace function public.mark_list_recommendation_dirty(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_user_id is null then
    return;
  end if;

  insert into public.user_list_recommendation_state (
    user_id,
    recommendation_dirty,
    updated_at
  )
  values (p_user_id, true, now())
  on conflict (user_id) do update
    set recommendation_dirty = true,
        updated_at = now();
end;
$$;

comment on function public.mark_list_recommendation_dirty(uuid) is
  'Marks a user for nightly list recommendation recomputation.';

create or replace function public.trg_mark_list_recommendation_dirty_from_user_books()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    perform public.mark_list_recommendation_dirty(new.user_id);
    return new;
  end if;

  if tg_op = 'UPDATE' then
    if new.status is distinct from old.status
      or new.is_favorite is distinct from old.is_favorite then
      perform public.mark_list_recommendation_dirty(new.user_id);
    end if;
    return new;
  end if;

  if tg_op = 'DELETE' then
    perform public.mark_list_recommendation_dirty(old.user_id);
    return old;
  end if;

  return null;
end;
$$;

drop trigger if exists trg_user_books_list_recommendation_dirty on public.user_books;
create trigger trg_user_books_list_recommendation_dirty
after insert or update of status, is_favorite or delete
on public.user_books
for each row
execute function public.trg_mark_list_recommendation_dirty_from_user_books();

create or replace function public.trg_mark_list_recommendation_dirty_from_ratings()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    perform public.mark_list_recommendation_dirty(new.user_id);
    return new;
  end if;

  if tg_op = 'UPDATE' then
    if new.rating is distinct from old.rating then
      perform public.mark_list_recommendation_dirty(new.user_id);
    end if;
    return new;
  end if;

  if tg_op = 'DELETE' then
    perform public.mark_list_recommendation_dirty(old.user_id);
    return old;
  end if;

  return null;
end;
$$;

drop trigger if exists trg_ratings_list_recommendation_dirty on public.ratings;
create trigger trg_ratings_list_recommendation_dirty
after insert or update of rating or delete
on public.ratings
for each row
execute function public.trg_mark_list_recommendation_dirty_from_ratings();

create or replace function public.trg_mark_list_recommendation_dirty_from_list_likes()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    perform public.mark_list_recommendation_dirty(new.user_id);
    return new;
  end if;

  if tg_op = 'DELETE' then
    perform public.mark_list_recommendation_dirty(old.user_id);
    return old;
  end if;

  return null;
end;
$$;

drop trigger if exists trg_list_likes_list_recommendation_dirty on public.list_likes;
create trigger trg_list_likes_list_recommendation_dirty
after insert or delete
on public.list_likes
for each row
execute function public.trg_mark_list_recommendation_dirty_from_list_likes();

create or replace function public.trg_mark_list_recommendation_dirty_from_saved_lists()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if tg_op = 'INSERT' then
    perform public.mark_list_recommendation_dirty(new.user_id);
    return new;
  end if;

  if tg_op = 'DELETE' then
    perform public.mark_list_recommendation_dirty(old.user_id);
    return old;
  end if;

  return null;
end;
$$;

drop trigger if exists trg_saved_lists_list_recommendation_dirty on public.saved_lists;
create trigger trg_saved_lists_list_recommendation_dirty
after insert or delete
on public.saved_lists
for each row
execute function public.trg_mark_list_recommendation_dirty_from_saved_lists();

grant execute on function public.mark_list_recommendation_dirty(uuid) to service_role;
