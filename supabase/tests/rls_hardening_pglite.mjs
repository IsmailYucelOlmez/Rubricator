// Regression test for supabase/migrations/20260926000000_rls_hardening.sql.
// Replays EVERY migration in a real Postgres engine (PGlite) with Supabase's
// default privileges and minimal auth/storage/cron stand-ins, then acts as the
// anon / authenticated / service_role roles.
//
//   npm install --no-save @electric-sql/pglite
//   node supabase/tests/rls_hardening_pglite.mjs
import { PGlite } from '@electric-sql/pglite';
import { pg_trgm } from '@electric-sql/pglite/contrib/pg_trgm';
import { readFileSync, readdirSync } from 'node:fs';

const DIR = new URL('../migrations/', import.meta.url);
const db = new PGlite({ extensions: { pg_trgm } });
let pass = 0, fail = 0;
const ok = (name, cond, extra = '') => {
  if (cond) { pass++; console.log('  ok   ', name); } else { fail++; console.log('  FAIL ', name, extra); }
};
const A = '11111111-1111-1111-1111-111111111111';
const B = '22222222-2222-2222-2222-222222222222';

await db.exec(`
  create role anon nologin; create role authenticated nologin; create role service_role nologin bypassrls;
  create schema extensions; create schema auth;
  create table auth.users (id uuid primary key default gen_random_uuid(), email text, raw_user_meta_data jsonb default '{}'::jsonb, created_at timestamptz default now());
  create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
  create function auth.role() returns text language sql stable as $$ select coalesce(nullif(current_setting('request.jwt.claim.role', true), ''), 'anon') $$;
  create function auth.jwt() returns jsonb language sql stable as $$ select '{}'::jsonb $$;
  grant usage on schema auth, extensions to anon, authenticated, service_role;
  create schema cron; create table cron.job (jobid bigserial primary key, jobname text);
  create function cron.schedule(a text, b text, c text) returns bigint language sql as $$ select 1::bigint $$;
  create function cron.unschedule(j bigint) returns boolean language sql as $$ select true $$;
  create schema net;
  create function net.http_post(url text, body jsonb default '{}', params jsonb default '{}', headers jsonb default '{}', timeout_milliseconds int default 1000) returns bigint language sql as $$ select 1::bigint $$;
  create schema vault; create table vault.decrypted_secrets (name text, decrypted_secret text);
  create schema storage;
  create table storage.buckets (id text primary key, name text, public boolean default false, file_size_limit bigint, allowed_mime_types text[]);
  create table storage.objects (id uuid primary key default gen_random_uuid(), bucket_id text references storage.buckets(id), name text, owner uuid);
  alter table storage.objects enable row level security;
  create function storage.foldername(name text) returns text[] language sql immutable as $$ select string_to_array(name, '/') $$;
  grant usage on schema storage to anon, authenticated, service_role;
  grant all on all tables in schema storage to anon, authenticated, service_role;
  grant usage on schema public to anon, authenticated, service_role;
  alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
  alter default privileges in schema public grant all on sequences to anon, authenticated, service_role;
  alter default privileges in schema public grant all on functions to anon, authenticated, service_role;
`);
for (const f of readdirSync(DIR).filter((f) => f.endsWith('.sql')).sort()) {
  await db.exec(readFileSync(new URL(f, DIR), 'utf8'));
}
await db.exec(`insert into auth.users (id) values ('${A}'), ('${B}');`);

const as = async (role, uid, sql) => {
  await db.exec(`set role ${role}; select set_config('request.jwt.claim.sub', '${uid ?? ''}', false);`);
  try { return await db.query(sql); } finally { await db.exec('reset role;'); }
};
const err = async (role, uid, sql) => { try { await as(role, uid, sql); return null; } catch (e) { return String(e.message); } };
const rows = async (role, uid, sql) => (await as(role, uid, sql)).rows;
const denied = (m) => /permission denied/i.test(m ?? '');

// ---------------------------------------------------------------------------
console.log('\n1. quotes: only the owner can update');
await db.exec(`insert into public.quotes (id, user_id, book_id, content) values
  ('aaaaaaaa-0000-0000-0000-00000000000a', '${A}', 'b1', 'A''s quote'),
  ('bbbbbbbb-0000-0000-0000-00000000000b', '${B}', 'b1', 'B''s quote')`);
const upOther = await as('authenticated', A, `update public.quotes set content='hijacked', user_id='${A}' where id='bbbbbbbb-0000-0000-0000-00000000000b' returning id`);
ok("A cannot rewrite B's quote or take it over", upOther.rows.length === 0);
const upOwn = await as('authenticated', A, `update public.quotes set content='edited' where id='aaaaaaaa-0000-0000-0000-00000000000a' returning id`);
ok('A can edit their own quote', upOwn.rows.length === 1);
ok('A cannot hand their quote to B (WITH CHECK)', /row-level security/i.test(await err('authenticated', A, `update public.quotes set user_id='${B}' where id='aaaaaaaa-0000-0000-0000-00000000000a'`) ?? ''));
ok('B\'s quote untouched', (await db.query(`select content from public.quotes where id='bbbbbbbb-0000-0000-0000-00000000000b'`)).rows[0].content === "B's quote");
ok('authenticated can still read all quotes', (await rows('authenticated', A, `select id from public.quotes`)).length === 2);
ok('anon cannot update quotes', (await as('anon', null, `update public.quotes set content='x' returning id`)).rows.length === 0);
const liked = await rows('authenticated', A, `select * from public.toggle_quote_like('bbbbbbbb-0000-0000-0000-00000000000b')`);
ok("liking B's quote via the RPC still works", liked[0]?.liked === true && liked[0]?.likes_count === 1, JSON.stringify(liked));

console.log('\n2. cron / trigger-only functions are no longer callable by API roles');
for (const fn of [`public.process_dirty_list_recommendations_batch()`, `public.compute_list_recommendations_for_user('${A}')`, `public.mark_list_recommendation_dirty('${A}')`]) {
  ok(`anon cannot call ${fn.split('(')[0]}`, denied(await err('anon', null, `select ${fn}`)));
  ok(`authenticated cannot call ${fn.split('(')[0]}`, denied(await err('authenticated', A, `select ${fn}`)));
  ok(`service_role still can call ${fn.split('(')[0]}`, (await err('service_role', null, `select ${fn}`)) === null);
}
// Trigger functions lost EXECUTE for the API roles; the triggers must still fire.
const ins = await err('authenticated', A, `insert into public.ratings (user_id, book_id, rating) values ('${A}', 'bk-1', 5)`);
ok('a normal rating insert (fires a recommendation trigger) still succeeds', ins === null, ins ?? '');
const dirty = (await db.query(`select recommendation_dirty from public.user_list_recommendation_state where user_id=$1`, [A])).rows[0];
ok('...and the trigger really marked the user dirty', dirty?.recommendation_dirty === true, JSON.stringify(dirty));

console.log('\n3. search_logs: no more reading anonymous rows');
await db.exec(`insert into public.search_logs (user_id, query) values (null, 'anon secret query'), ('${A}', 'a query'), ('${B}', 'b query')`);
ok('anon reads nothing', (await rows('anon', null, `select query from public.search_logs`)).length === 0);
const seeA = (await rows('authenticated', A, `select query from public.search_logs`)).map((r) => r.query);
ok('A sees only their own rows (not anonymous, not B)', seeA.length === 1 && seeA[0] === 'a query', JSON.stringify(seeA));
ok('anonymous inserts still work', (await err('anon', null, `insert into public.search_logs (user_id, query) values (null, 'new anon')`)) === null);
ok('authenticated inserts (own id) still work', (await err('authenticated', A, `insert into public.search_logs (user_id, query) values ('${A}', 'mine')`)) === null);
ok("cannot insert a row as someone else", /row-level security/i.test(await err('authenticated', A, `insert into public.search_logs (user_id, query) values ('${B}', 'forged')`) ?? ''));
const pop = await err('anon', null, `select * from public.search_logs_popular_queries(5)`);
ok('popular-searches RPC (SECURITY DEFINER) still works for anon', pop === null, pop ?? '');

console.log('\n4. trbooks_scrape_runs is service-only');
await db.exec(`insert into public.trbooks_scrape_runs (genre_key, source, status) values ('fantasy', 'kitapyurdu', 'success')`);
ok('anon reads nothing', (await rows('anon', null, `select id from public.trbooks_scrape_runs`)).length === 0);
ok('authenticated reads nothing', (await rows('authenticated', A, `select id from public.trbooks_scrape_runs`)).length === 0);
ok('service_role reads it', (await rows('service_role', null, `select id from public.trbooks_scrape_runs`)).length === 1);

console.log('\n5. profile-photos: no listing of other users\' files');
await db.exec(`insert into storage.objects (bucket_id, name, owner) values ('profile-photos', '${A}/avatar.png', '${A}'), ('profile-photos', '${B}/avatar.png', '${B}')`);
ok('anon cannot list', (await rows('anon', null, `select name from storage.objects where bucket_id='profile-photos'`)).length === 0);
const listA = (await rows('authenticated', A, `select name from storage.objects where bucket_id='profile-photos'`)).map((r) => r.name);
ok('A sees only their own folder (enough for upload upsert)', listA.length === 1 && listA[0].startsWith(A), JSON.stringify(listA));
ok('A can still insert into their own folder', (await err('authenticated', A, `insert into storage.objects (bucket_id, name, owner) values ('profile-photos', '${A}/new.png', '${A}')`)) === null);
ok("A cannot write into B's folder", /row-level security/i.test(await err('authenticated', A, `insert into storage.objects (bucket_id, name, owner) values ('profile-photos', '${B}/evil.png', '${A}')`) ?? ''));
ok('bucket stays public (public URLs need no policy)', (await db.query(`select public from storage.buckets where id='profile-photos'`)).rows[0].public === true);

console.log('\n6. things the apps rely on keep working');
ok('anon can still read public lists policy path (no error)', (await err('anon', null, `select id from public.lists limit 1`)) === null);
ok('anon can still read trbooks', (await err('anon', null, `select id from public.trbooks limit 1`)) === null);
ok('cache tables stay writable for the published apps (deferred lockdown)', (await err('anon', null, `insert into public.google_books_search_cache (cache_key, cache_type, books_json, result_count) values ('k','search','[]'::jsonb,0)`)) === null);
ok('the virgil quota functions are still service-only', denied(await err('authenticated', A, `select public.authorize_virgil_action('${A}','recommendation',null)`)));

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
