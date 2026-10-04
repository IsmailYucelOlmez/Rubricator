-- Demo account seed for Play Store screenshots. NOT a migration.
--
-- 1. Create the demo account in the app yourself (username e.g. "kitapkurdu").
-- 2. Put its e-mail into v_email below.
-- 3. Run once:  supabase db query --linked -f supabase/scripts/demo_account_seed.sql
--
-- Re-runnable: it first wipes this user's own seeded data (user_books, ratings,
-- reviews, quotes, notes, reading logs, lists). It touches no other user.
-- Books are picked from public.trbooks by title so covers resolve in the app.
-- Reading logs are relative to current_date (UTC): run it on the day you take
-- screenshots, not between 00:00 and 03:00 Turkey time.

do $$
declare
  v_email text := 'DEMO_EMAIL@example.com';
  v_uid uuid;
  v_has_cover_col boolean;
  v_reading_book text;
  v_list uuid;
  b record;
  t record;
  i int;
begin
  select id into v_uid from auth.users where lower(email) = lower(v_email);
  if v_uid is null then
    raise exception 'Demo user % not found. Create the account in the app first.', v_email;
  end if;

  select exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'user_books' and column_name = 'book_cover_url'
  ) into v_has_cover_col;

  -- Reset this user's data.
  delete from public.reading_logs where user_id = v_uid;
  delete from public.book_notes   where user_id = v_uid;
  delete from public.quotes       where user_id = v_uid;
  delete from public.reviews      where user_id = v_uid;
  delete from public.ratings      where user_id = v_uid;
  delete from public.lists        where user_id = v_uid; -- cascades to list_items/comments
  delete from public.user_books   where user_id = v_uid;

  create temp table demo_books (
    key text primary key,
    book_id text not null,
    title text not null,
    author text,
    cover text
  ) on commit drop;

  -- key, title pattern, author pattern, status, favorite, rating (1-10), progress, completed N days ago, category
  for b in
    select * from (values
      ('kirke',      'Kirke',                   'Miller',      'completed',  true,  10, null::int, 6, 'Mitoloji'),
      ('akhilleus',  'Akhilleus',               'Miller',      'completed',  true,   9, null, 20, 'Mitoloji'),
      ('gilgamis',   'Gılgamış Destanı',        'Sait Maden',   'completed',  true,   9, null, 35, 'Mitoloji'),
      ('suc_ceza',   'Suç ve Ceza',             'Dostoyevski', 'completed',  true,  10, null, 50, 'Roman'),
      ('kurk',       'Kürk Mantolu Madonna',    'Sabahattin',  'completed',  true,   9, null, 64, 'Roman'),
      ('saatleri',   'Saatleri Ayarlama',       'Tanpınar',    'completed',  false,  8, null, 80, 'Roman'),
      ('ince_memed', 'İnce Memed',              'Yaşar Kemal', 'completed',  false,  8, null, 95, 'Roman'),
      ('hayvan',     'Hayvan Çiftliği',         'Orwell',      'completed',  true,   9, null, 110, 'Roman'),
      ('kucuk',      'Küçük Prens',             'Exupery',     'completed',  false,  8, null, 125, 'Çocuk Klasikleri'),
      ('donusum',    'Dönüşüm',                 'Kafka',       'completed',  false,  7, null, 140, 'Roman'),
      ('simyaci',    'Simyacı',                 'Coelho',      'completed',  false,  6, null, 160, 'Roman'),
      ('beyaz_dis',  'Beyaz Diş',               'London',      'completed',  false,  7, null, 175, 'Roman'),
      ('savas',      'Savaş ve Barış',          'Tolstoy',     'reading',    false, null, 42, null, 'Roman'),
      ('yuzyillik',  'Yüzyıllık Yalnızlık',     'Marquez',     'reading',    false, null, 18, null, 'Roman'),
      ('tutunamay',  'Tutunamayanlar',          'Atay',        'to_read',    false, null, null, null, 'Roman'),
      ('sefiller',   'Sefiller',                'Hugo',        'to_read',    false, null, null, null, 'Roman'),
      ('karamazov',  'Karamazov Kardeşler',     'Dostoyevski',  'to_read',    false, null, null, null, 'Roman'),
      ('roma',       'Beş Günü',                'Ümit',        'to_read',    false, null, null, null, 'Polisiye'),
      ('marti',      'Martı',                   'Bach',        're_reading', true,  8, 60, null, 'Roman'),
      ('fareler',    'Fareler ve İnsanlar',     'Steinbeck',   'dropped',    false, null, null, null, 'Roman')
    ) as v(key, title_pat, author_pat, status, fav, rating, progress, done_ago, category)
  loop
    -- Literal patterns (format %L) so the planner uses the trigram indexes.
    execute format(
      'select tb.id, tb.title, tb.author, tb.image_url
         from public.trbooks tb
        where tb.title_normalized like %L
          and (%L is null or tb.author_normalized like %L)
          and coalesce(tb.image_url, '''') <> ''''
        order by (tb.title_normalized = %L) desc, tb.reviews_count desc nulls last
        limit 1',
      '%' || public.trbooks_normalize_tr(b.title_pat) || '%',
      b.author_pat,
      '%' || public.trbooks_normalize_tr(b.author_pat) || '%',
      public.trbooks_normalize_tr(b.title_pat)
    ) into t;

    if t.id is null then
      raise notice 'Skipped: no trbooks match for "%"', b.title_pat;
      continue;
    end if;

    insert into demo_books values (b.key, 'trbooks:' || t.id, t.title, t.author, t.image_url);

    insert into public.user_books (
      user_id, book_id, status, is_favorite, progress,
      book_title, book_author, book_categories, completed_at, created_at, updated_at
    ) values (
      v_uid, 'trbooks:' || t.id, b.status, b.fav, b.progress,
      t.title, t.author,
      jsonb_build_array(b.category),
      case when b.done_ago is null then null else now() - make_interval(days => b.done_ago) end,
      now() - make_interval(days => coalesce(b.done_ago, 0) + 14),
      now() - make_interval(days => coalesce(b.done_ago, 0))
    );

    if v_has_cover_col then
      execute 'update public.user_books set book_cover_url = $1 where user_id = $2 and book_id = $3'
        using t.image_url, v_uid, 'trbooks:' || t.id;
    end if;

    if b.rating is not null then
      insert into public.ratings (user_id, book_id, rating, created_at)
      values (v_uid, 'trbooks:' || t.id, b.rating, now() - make_interval(days => coalesce(b.done_ago, 0)));
    end if;
  end loop;

  -- Reading logs: unbroken 12-day streak ending today, plus scattered days over ~26 weeks.
  select book_id into v_reading_book from demo_books where key = 'savas';

  insert into public.reading_logs (user_id, book_id, date, minutes_read, pages_read)
  select v_uid, v_reading_book, current_date - d,
         20 + (d * 37) % 45,
         18 + (d * 29) % 40
    from generate_series(0, 11) as d;

  insert into public.reading_logs (user_id, book_id, date, minutes_read, pages_read)
  select v_uid, null, current_date - d,
         15 + (d * 23) % 50,
         12 + (d * 17) % 45
    from generate_series(14, 180) as d
   where d % 7 not in (2, 5)          -- leave gaps so the calendar looks real
     and d % 11 <> 0;

  -- Reviews (original text).
  for b in
    select * from (values
      ('kirke',    'Mitolojiyi bir kadının gözünden yeniden anlatıyor. Kirke''nin yalnızlığı ve dönüşümü uzun süre aklımdan çıkmadı.', 2),
      ('suc_ceza', 'Raskolnikov''un kafasının içinde geçen yüzlerce sayfa. Yavaş başlıyor ama bırakılmıyor; vicdan üzerine okuduğum en güçlü roman.', 48),
      ('kurk',     'Kısa ama çok yoğun. Raif Efendi''nin sessizliğinin arkasındaki hikâyeyi öğrenince her şey değişiyor.', 62),
      ('hayvan',   'Bir fabl gibi okunuyor ama her bölümde bugünü düşündürüyor. Tek oturuşta biter.', 108)
    ) as v(key, content, ago)
  loop
    insert into public.reviews (user_id, book_id, content, created_at)
    select v_uid, db.book_id, b.content, now() - make_interval(days => b.ago)
      from demo_books db where db.key = b.key;
  end loop;

  -- Quotes (public-domain / very short lines).
  for b in
    select * from (values
      ('kucuk',  'İnsan ancak yüreğiyle doğruyu görebilir.'),
      ('hayvan', 'Bütün hayvanlar eşittir ama bazı hayvanlar ötekilerden daha eşittir.'),
      ('gilgamis', 'Ölümsüzlüğü aradı, insan olmayı buldu.')
    ) as v(key, content)
  loop
    insert into public.quotes (user_id, book_id, content)
    select v_uid, db.book_id, b.content from demo_books db where db.key = b.key;
  end loop;

  -- Notes (original text).
  for b in
    select * from (values
      ('gilgamis', 'Siduri''nin Meyhanesi', 10, 'Siduri, Gılgamış''a ölümsüzlük yerine anı yaşamayı öğütlüyor. Destanın en insani sahnesi burası.', array['gılgamış','siduri']),
      ('gilgamis', 'Enkidu''nun dönüşümü', 3, 'Vahşi doğadan şehre geçiş, uygarlığın bedelini de beraberinde getiriyor. Dostluk temasının başladığı yer.', array['gılgamış','dostluk']),
      ('kirke',    'Aiaia adası', 112, 'Sürgün bir ceza gibi başlıyor ama Kirke''nin kendi gücünü keşfettiği yere dönüşüyor.', array['kirke','mitoloji']),
      ('suc_ceza', 'Sıradan ve olağanüstü insanlar', 260, 'Raskolnikov''un makalesindeki fikir tüm romanın ahlaki sorusunu özetliyor. Porfiri ile konuşmayı tekrar oku.', array['dostoyevski','felsefe']),
      ('savas',    'Austerlitz', 340, 'Prens Andrey''in gökyüzüne bakıp her şeyin anlamsızlaştığı an. Savaş sahneleri bu kadar sakin anlatılabilir mi?', array['tolstoy','savaş'])
    ) as v(key, title, page, content, tags)
  loop
    insert into public.book_notes (user_id, book_id, page_number, note_title, note_content, tags)
    select v_uid, db.book_id, b.page, b.title, b.content, b.tags
      from demo_books db where db.key = b.key;
  end loop;

  -- Public lists.
  insert into public.lists (user_id, title, description, is_public)
  values (v_uid, 'Mitolojiden doğan romanlar',
          'Tanrılar, kahramanlar ve onların gölgesinde kalanlar. Mitolojiye yeni başlayanlar için.', true)
  returning id into v_list;

  i := 0;
  for b in select * from (values ('gilgamis'), ('kirke'), ('akhilleus')) as v(key) loop
    insert into public.list_items (list_id, book_id, book_title, book_author, cover_image_url, order_index)
    select v_list, db.book_id, db.title, db.author, db.cover, i from demo_books db where db.key = b.key;
    if found then i := i + 1; end if;
  end loop;

  insert into public.lists (user_id, title, description, is_public)
  values (v_uid, 'Türk edebiyatından başyapıtlar',
          'Okumadan geçilmemesi gereken romanlar. Kısa olandan uzun olana doğru sıralı.', true)
  returning id into v_list;

  i := 0;
  for b in select * from (values ('kurk'), ('saatleri'), ('ince_memed'), ('tutunamay'), ('roma')) as v(key) loop
    insert into public.list_items (list_id, book_id, book_title, book_author, cover_image_url, order_index)
    select v_list, db.book_id, db.title, db.author, db.cover, i from demo_books db where db.key = b.key;
    if found then i := i + 1; end if;
  end loop;

  insert into public.lists (user_id, title, description, is_public)
  values (v_uid, 'Rus klasiklerine giriş',
          'Dostoyevski ve Tolstoy''a nereden başlanır? Önce bunlar.', true)
  returning id into v_list;

  i := 0;
  for b in select * from (values ('suc_ceza'), ('savas')) as v(key) loop
    insert into public.list_items (list_id, book_id, book_title, book_author, cover_image_url, order_index)
    select v_list, db.book_id, db.title, db.author, db.cover, i from demo_books db where db.key = b.key;
    if found then i := i + 1; end if;
  end loop;

  raise notice 'Seeded % books for %', (select count(*) from demo_books), v_email;
end;
$$;
