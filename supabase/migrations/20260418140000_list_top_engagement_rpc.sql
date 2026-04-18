-- Top lists by all-time engagement: like count + save count (global aggregates).
-- Uses SECURITY DEFINER because saved_lists is only visible to row owners under RLS.

create index if not exists saved_lists_list_id_idx on public.saved_lists using btree (list_id);

create or replace function public.list_top_by_engagement(p_limit int default 20)
returns table (list_id uuid, engagement_score bigint)
language sql
stable
security definer
set search_path = public
as $$
  select l.id as list_id,
         coalesce(ll.c, 0) + coalesce(sl.c, 0) as engagement_score
  from public.lists l
  left join (
    select list_id, count(*)::bigint as c
    from public.list_likes
    group by list_id
  ) ll on ll.list_id = l.id
  left join (
    select list_id, count(*)::bigint as c
    from public.saved_lists
    group by list_id
  ) sl on sl.list_id = l.id
  where l.is_public = true
  order by engagement_score desc, l.created_at desc
  limit greatest(1, least(coalesce(p_limit, 20), 200));
$$;

comment on function public.list_top_by_engagement(int) is
  'Public lists ranked by total likes plus saves (all time).';

grant execute on function public.list_top_by_engagement(int) to anon, authenticated;
