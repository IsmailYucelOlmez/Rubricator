-- Phase 2: hybrid list recommendation scoring + nightly dirty-user batch.

create or replace function public.compute_list_recommendations_for_user(p_user_id uuid)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_inserted integer := 0;
  v_max_results constant integer := 100;
  v_candidate_limit constant integer := 400;
begin
  if p_user_id is null then
    return 0;
  end if;

  delete from public.list_recommendations
  where user_id = p_user_id;

  with taste_books as (
    select distinct
      ub.book_id,
      greatest(
        case when ub.status = 'completed' then 1.0 else 0.0 end,
        case when ub.is_favorite then 1.2 else 0.0 end,
        case when coalesce(r.rating, 0) >= 8 then 1.5 else 0.0 end
      )::numeric as weight,
      lower(trim(coalesce(ub.book_author, ''))) as author_key
    from public.user_books ub
    left join public.ratings r
      on r.user_id = ub.user_id
     and r.book_id = ub.book_id
    where ub.user_id = p_user_id
      and (
        ub.status = 'completed'
        or ub.is_favorite = true
        or coalesce(r.rating, 0) >= 8
      )
  ),
  excluded_lists as (
    select list_id
    from public.list_likes
    where user_id = p_user_id
    union
    select list_id
    from public.saved_lists
    where user_id = p_user_id
  ),
  list_engagement as (
    select
      l.id as list_id,
      l.title,
      l.description,
      coalesce(ll.c, 0)::numeric as like_count,
      coalesce(sl.c, 0)::numeric as save_count,
      coalesce(lc.c, 0)::numeric as comment_count
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
    left join (
      select list_id, count(*)::bigint as c
      from public.list_comments
      group by list_id
    ) lc on lc.list_id = l.id
    where l.is_public = true
      and l.user_id <> p_user_id
      and not exists (
        select 1
        from excluded_lists ex
        where ex.list_id = l.id
      )
  ),
  candidate_lists as (
    select *
    from list_engagement
    order by (like_count + save_count + comment_count) desc, list_id
    limit v_candidate_limit
  ),
  engagement_bounds as (
    select
      coalesce(min(like_count + save_count + comment_count), 0) as min_eng,
      coalesce(max(like_count + save_count + comment_count), 1) as max_eng
    from candidate_lists
  ),
  book_overlap as (
    select
      cl.list_id,
      coalesce(sum(tb.weight), 0)::numeric as raw_content
    from candidate_lists cl
    inner join public.list_items li on li.list_id = cl.list_id
    inner join taste_books tb on tb.book_id = li.book_id
    group by cl.list_id
  ),
  author_overlap as (
    select
      cl.list_id,
      coalesce(sum(tb.weight * 0.5), 0)::numeric as raw_author
    from candidate_lists cl
    inner join public.list_items li on li.list_id = cl.list_id
    inner join taste_books tb
      on tb.author_key <> ''
     and tb.author_key <> 'unknown author'
     and (
       lower(coalesce(li.book_author, '')) = tb.author_key
       or lower(coalesce(li.book_author, '')) like '%' || split_part(tb.author_key, ' ', -1) || '%'
     )
    group by cl.list_id
  ),
  my_interacted_lists as (
    select list_id
    from public.list_likes
    where user_id = p_user_id
    union
    select list_id
    from public.saved_lists
    where user_id = p_user_id
  ),
  similar_users as (
    select user_id as similar_user_id, sum(overlap)::numeric as overlap_score
    from (
      select ll.user_id, count(*)::numeric as overlap
      from public.list_likes ll
      where ll.list_id in (select list_id from my_interacted_lists)
        and ll.user_id <> p_user_id
      group by ll.user_id
      union all
      select sl.user_id, count(*)::numeric as overlap
      from public.saved_lists sl
      where sl.list_id in (select list_id from my_interacted_lists)
        and sl.user_id <> p_user_id
      group by sl.user_id
      union all
      select ub.user_id, count(*)::numeric * 0.5 as overlap
      from public.user_books ub
      where ub.user_id <> p_user_id
        and ub.book_id in (select book_id from taste_books)
        and (ub.status = 'completed' or ub.is_favorite = true)
      group by ub.user_id
    ) s
    group by user_id
  ),
  similar_bounds as (
    select coalesce(max(overlap_score), 1)::numeric as max_sim
    from similar_users
  ),
  similar_list_scores as (
    select
      cl.list_id,
      coalesce(max(su.overlap_score), 0)::numeric as raw_sim
    from candidate_lists cl
    left join public.list_likes ll on ll.list_id = cl.list_id
    left join public.saved_lists sl on sl.list_id = cl.list_id
    left join similar_users su
      on su.similar_user_id = ll.user_id
      or su.similar_user_id = sl.user_id
    group by cl.list_id
  ),
  content_bounds as (
    select
      coalesce(
        max(coalesce(bo.raw_content, 0) + coalesce(ao.raw_author, 0)),
        1
      )::numeric as max_content
    from candidate_lists cl
    left join book_overlap bo on bo.list_id = cl.list_id
    left join author_overlap ao on ao.list_id = cl.list_id
  ),
  scored as (
    select
      cl.list_id,
      (
        case
          when cb.max_content <= 0 then 0
          else (
            (coalesce(bo.raw_content, 0) + coalesce(ao.raw_author, 0))
            / cb.max_content
          ) * 100.0
        end
      ) * 0.50
      + (
        case
          when sb.max_sim <= 0 then 0
          else (coalesce(sls.raw_sim, 0) / sb.max_sim) * 100.0
        end
      ) * 0.30
      + (
        case
          when eb.max_eng = eb.min_eng then 50.0
          else (
            (cl.like_count + cl.save_count + cl.comment_count - eb.min_eng)
            / nullif(eb.max_eng - eb.min_eng, 0)
          ) * 100.0
        end
      ) * 0.20 as final_score
    from candidate_lists cl
    cross join content_bounds cb
    cross join similar_bounds sb
    cross join engagement_bounds eb
    left join book_overlap bo on bo.list_id = cl.list_id
    left join author_overlap ao on ao.list_id = cl.list_id
    left join similar_list_scores sls on sls.list_id = cl.list_id
  ),
  ranked as (
    select
      list_id,
      round(least(greatest(final_score, 0), 100)::numeric, 2) as score
    from scored
    where final_score > 0
    order by final_score desc, list_id
    limit v_max_results
  )
  insert into public.list_recommendations (user_id, list_id, score, generated_at)
  select p_user_id, list_id, score, now()
  from ranked;

  get diagnostics v_inserted = row_count;

  insert into public.user_list_recommendation_state (
    user_id,
    recommendation_dirty,
    last_computed_at,
    updated_at
  )
  values (p_user_id, false, now(), now())
  on conflict (user_id) do update
    set recommendation_dirty = false,
        last_computed_at = now(),
        updated_at = now();

  return v_inserted;
end;
$$;

comment on function public.compute_list_recommendations_for_user(uuid) is
  'Recomputes hybrid list recommendations for one user (content + similar users + popularity).';

create or replace function public.process_dirty_list_recommendations_batch()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_processed integer := 0;
begin
  for v_user_id in
    select distinct s.user_id
    from public.user_list_recommendation_state s
    where s.recommendation_dirty = true
      and s.updated_at >= now() - interval '24 hours'
    order by s.user_id
    limit 500
  loop
    perform public.compute_list_recommendations_for_user(v_user_id);
    v_processed := v_processed + 1;
  end loop;

  return v_processed;
end;
$$;

comment on function public.process_dirty_list_recommendations_batch() is
  'Nightly batch: recompute list recommendations for dirty users active in the last 24h.';

create or replace function public.get_list_recommendations(
  p_limit integer default 50,
  p_offset integer default 0
)
returns table (list_id uuid, score numeric)
language sql
stable
security invoker
set search_path = public
as $$
  select lr.list_id, lr.score
  from public.list_recommendations lr
  inner join public.lists l on l.id = lr.list_id
  where lr.user_id = auth.uid()
    and l.is_public = true
  order by lr.score desc, lr.generated_at desc
  limit greatest(1, least(coalesce(p_limit, 50), 100))
  offset greatest(0, coalesce(p_offset, 0));
$$;

comment on function public.get_list_recommendations(integer, integer) is
  'Returns precomputed list recommendations for the signed-in user.';

grant execute on function public.compute_list_recommendations_for_user(uuid) to service_role;
grant execute on function public.process_dirty_list_recommendations_batch() to service_role;
grant execute on function public.get_list_recommendations(integer, integer) to authenticated;

-- Nightly 02:00 UTC via pg_cron (no-op locally if pg_cron unavailable).
do $$
declare
  job_id bigint;
begin
  if not exists (select 1 from pg_extension where extname = 'pg_cron') then
    raise notice 'pg_cron not available; skip list-recommendations batch schedule';
    return;
  end if;

  select jobid into job_id
  from cron.job
  where jobname = 'process-dirty-list-recommendations'
  limit 1;

  if job_id is not null then
    perform cron.unschedule(job_id);
  end if;

  perform cron.schedule(
    'process-dirty-list-recommendations',
    '0 2 * * *',
    $cron$select public.process_dirty_list_recommendations_batch();$cron$
  );

  raise notice 'Scheduled process-dirty-list-recommendations (daily 02:00 UTC)';
exception
  when others then
    raise notice
      'Could not schedule list recommendations batch: %. '
      'Run select public.process_dirty_list_recommendations_batch(); manually.',
      sqlerrm;
end $$;
