-- Lets an authenticated user in Turkish locale contribute a book that's
-- missing from the trbooks catalog (source = 'user_submitted'), without
-- opening up direct table INSERT via RLS. All validation/dedup happens
-- inside a single security-definer RPC, mirroring the auth.uid() check
-- already used by toggle_quote_like/toggle_review_like
-- (20260620000000_content_likes_toggle.sql).

-- 1) Widen the source check constraint (same drop/add pattern as
--    20260907000000_trbooks_scraped_genre.sql).
alter table public.trbooks drop constraint if exists trbooks_source_check;

alter table public.trbooks add constraint trbooks_source_check check (
  source in (
    'turkish_book_dataset', 'ecommerce_bookstore',
    'kitapyurdu_scrape', 'dr_scrape', 'user_submitted'
  )
);

-- 2) Extend the scraped-only unique index to also cover user submissions,
--    so duplicate ISBNs are rejected at the DB level as a second line of
--    defense behind the RPC's own existence check.
drop index if exists public.trbooks_scraped_isbn_unique_idx;

create unique index if not exists trbooks_scraped_or_submitted_isbn_unique_idx
  on public.trbooks (isbn)
  where (source like '%_scrape' or source = 'user_submitted')
    and isbn is not null and isbn <> '';

-- 3) ISBN normalization/validation helper (digits only; mirrors the
--    regexp_replace idiom in scripts/trbooks_update_descriptions.sql).
create or replace function public.trbooks_normalize_isbn(input text)
returns text
language sql
immutable
parallel safe
as $$
  select nullif(regexp_replace(coalesce(input, ''), '[^0-9Xx]', '', 'g'), '');
$$;

-- 4) The insert RPC. security definer so it can write despite trbooks only
--    having a `select` RLS policy; auth.uid() enforces sign-in the same way
--    _requiredUserId() does client-side for reviews/quotes/ratings.
create or replace function public.submit_user_trbook(
  p_title text,
  p_author text,
  p_isbn text,
  p_description text default null,
  p_image_url text default null,
  p_publisher text default null,
  p_category text default null,
  p_page_count integer default null,
  p_released_year integer default null
)
returns public.trbooks
language plpgsql
security definer
set search_path = public
as $$
declare
  uid uuid := auth.uid();
  v_title text := nullif(trim(p_title), '');
  v_author text := nullif(trim(p_author), '');
  v_isbn text := public.trbooks_normalize_isbn(p_isbn);
  v_existing public.trbooks;
  v_row public.trbooks;
begin
  if uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;
  if v_title is null then
    raise exception 'Title is required' using errcode = '22023';
  end if;
  if v_author is null then
    raise exception 'Author is required' using errcode = '22023';
  end if;
  if v_isbn is null or length(v_isbn) not in (10, 13) then
    raise exception 'ISBN must be 10 or 13 digits' using errcode = '22023';
  end if;

  select * into v_existing from public.trbooks t where t.isbn = v_isbn limit 1;
  if found then
    -- Duplicate: reject rather than overwrite scraped/verified data. The
    -- Dart layer parses the embedded id out of this message and offers to
    -- open the existing book instead.
    raise exception 'DUPLICATE_ISBN:%', v_existing.id using errcode = '23505';
  end if;

  insert into public.trbooks (
    source, title, author, isbn, description, image_url,
    publisher, category, page_count, released_year, language,
    scraped_at, created_at
  ) values (
    'user_submitted', v_title, v_author, v_isbn, nullif(trim(p_description), ''),
    nullif(trim(p_image_url), ''), nullif(trim(p_publisher), ''),
    nullif(trim(p_category), ''), p_page_count, p_released_year, 'tr',
    now(), now()
  )
  returning * into v_row;

  return v_row;
end;
$$;

grant execute on function public.submit_user_trbook(
  text, text, text, text, text, text, text, integer, integer
) to authenticated;
