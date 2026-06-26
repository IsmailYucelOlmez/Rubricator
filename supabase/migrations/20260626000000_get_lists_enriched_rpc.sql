-- Batch-enriched list cards: counts, preview covers, viewer like/save flags in one RPC.

create or replace function public.get_lists_enriched(p_list_ids uuid[])
returns table (
  list_id uuid,
  user_id uuid,
  user_name text,
  title text,
  description text,
  is_public boolean,
  created_at timestamptz,
  like_count bigint,
  comment_count bigint,
  preview_cover_image_urls text[],
  is_liked_by_me boolean,
  is_saved_by_me boolean
)
language sql
stable
security definer
set search_path = public
as $$
  with ord as (
    select t.id, t.ord::int as ord
    from unnest(coalesce(p_list_ids, array[]::uuid[])) with ordinality as t(id, ord)
  ),
  visible as (
    select l.*, o.ord
    from public.lists l
    inner join ord o on o.id = l.id
    where l.is_public = true
       or l.user_id = auth.uid()
  ),
  like_counts as (
    select ll.list_id, count(*)::bigint as c
    from public.list_likes ll
    where ll.list_id in (select v.id from visible v)
    group by ll.list_id
  ),
  comment_counts as (
    select lc.list_id, count(*)::bigint as c
    from public.list_comments lc
    where lc.list_id in (select v.id from visible v)
    group by lc.list_id
  ),
  preview_ranked as (
    select
      li.list_id,
      li.cover_image_url,
      li.order_index,
      row_number() over (
        partition by li.list_id
        order by li.order_index asc
      ) as rn
    from public.list_items li
    where li.list_id in (select v.id from visible v)
  ),
  previews as (
    select
      pr.list_id,
      array_agg(pr.cover_image_url order by pr.order_index) as covers
    from preview_ranked pr
    where pr.rn <= 4
    group by pr.list_id
  ),
  viewer_id as (
    select auth.uid() as uid
  )
  select
    v.id as list_id,
    v.user_id,
    coalesce(nullif(trim(v.user_name), ''), 'user') as user_name,
    coalesce(v.title, 'Untitled list') as title,
    coalesce(v.description, '') as description,
    v.is_public,
    v.created_at,
    coalesce(lk.c, 0) as like_count,
    coalesce(cm.c, 0) as comment_count,
    coalesce(p.covers, array[]::text[]) as preview_cover_image_urls,
    exists (
      select 1
      from public.list_likes ml
      cross join viewer_id vi
      where ml.list_id = v.id
        and ml.user_id = vi.uid
    ) as is_liked_by_me,
    exists (
      select 1
      from public.saved_lists ms
      cross join viewer_id vi
      where ms.list_id = v.id
        and ms.user_id = vi.uid
    ) as is_saved_by_me
  from visible v
  left join like_counts lk on lk.list_id = v.id
  left join comment_counts cm on cm.list_id = v.id
  left join previews p on p.list_id = v.id
  order by v.ord;
$$;

comment on function public.get_lists_enriched(uuid[]) is
  'Returns list card fields (counts, preview covers, viewer flags) for visible lists, preserving input order.';

create or replace function public.get_feed_lists_enriched(p_limit int default 50)
returns table (
  list_id uuid,
  user_id uuid,
  user_name text,
  title text,
  description text,
  is_public boolean,
  created_at timestamptz,
  like_count bigint,
  comment_count bigint,
  preview_cover_image_urls text[],
  is_liked_by_me boolean,
  is_saved_by_me boolean
)
language sql
stable
security definer
set search_path = public
as $$
  with feed as (
    select l.id, l.created_at
    from public.lists l
    where l.is_public = true
       or l.user_id = auth.uid()
    order by l.created_at desc
    limit greatest(1, least(coalesce(p_limit, 50), 100))
  )
  select e.*
  from public.get_lists_enriched(
    coalesce(
      (select array_agg(f.id order by f.created_at desc) from feed f),
      array[]::uuid[]
    )
  ) e;
$$;

comment on function public.get_feed_lists_enriched(int) is
  'Public/relevant feed lists with enriched card fields (newest first).';

grant execute on function public.get_lists_enriched(uuid[]) to anon, authenticated;
grant execute on function public.get_feed_lists_enriched(int) to anon, authenticated;
