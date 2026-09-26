// Behavioural test for the Virgil server-side quota migration
// (20260925000000_virgil_server_side_quota.sql), run against a real Postgres
// engine in-process (PGlite) with minimal stand-ins for Supabase's roles and
// auth.uid(). No Docker or network needed.
//
//   npm install --no-save @electric-sql/pglite
//   node supabase/tests/virgil_quota_pglite.mjs
//
// It replays the migrations that define the quota functions, so run it
// from a checkout where they apply cleanly on an empty database.
import { PGlite } from '@electric-sql/pglite';
import { readFileSync } from 'node:fs';

const MIG = new URL('../migrations/', import.meta.url);
const db = new PGlite();
let pass = 0, fail = 0;
const ok = (name, cond, extra = '') => {
  if (cond) { pass++; console.log('  ok   ', name); }
  else { fail++; console.log('  FAIL ', name, extra); }
};
const U = '11111111-1111-1111-1111-111111111111';
const V = '22222222-2222-2222-2222-222222222222';

// --- minimal Supabase stand-ins ---------------------------------------------
await db.exec(`
  create role anon nologin; create role authenticated nologin; create role service_role nologin bypassrls;
  create schema auth;
  create table auth.users (id uuid primary key);
  create function auth.uid() returns uuid language sql stable as
    $$ select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid $$;
  grant usage on schema auth to anon, authenticated, service_role;
  grant usage on schema public to anon, authenticated, service_role;
  insert into auth.users values ('${U}'), ('${V}');
`);
for (const f of ['20260727000000_virgil_usage_daily.sql', '20260730000000_virgil_recommendations_limit_5.sql', '20260925000000_virgil_server_side_quota.sql', '20260926000001_virgil_quota_refund_and_trbooks.sql']) {
  await db.exec(readFileSync(new URL(f, MIG), 'utf8'));
}
// what Supabase grants by default on public tables/functions
await db.exec(`grant all on all tables in schema public to service_role;`);

const as = async (role, uid, sql, params = []) => {
  await db.exec(`set role ${role}; select set_config('request.jwt.claim.sub', '${uid ?? ''}', false);`);
  try { return await db.query(sql, params); }
  finally { await db.exec('reset role;'); }
};
const asErr = async (role, uid, sql) => { try { await as(role, uid, sql); return null; } catch (e) { return String(e.message); } };
const count = async (uid) => (await db.query(`select coalesce(recommendations_count,0) r, coalesce(uploads_count,0) u from public.virgil_usage_daily where user_id=$1`, [uid])).rows[0] ?? { r: 0, u: 0 };
const auth = async (uid, action, hash = null) => (await as('service_role', null, `select public.authorize_virgil_action('${uid}', '${action}', ${hash ? `'${hash}'` : 'null'}) as ok`)).rows[0].ok;
const check = async (uid, action) => (await as('authenticated', uid, `select public.try_consume_virgil_usage('${action}') as ok`)).rows[0].ok;

console.log('\n1. old-client RPC is check-only');
ok('check returns true with no usage', await check(U, 'recommendation') === true);
ok('check does not increment', (await count(U)).r === 0);
ok('check for upload true', await check(U, 'upload') === true);

console.log('\n2. permissions');
ok('authenticated cannot run authorize_virgil_action', /permission denied/i.test(await asErr('authenticated', U, `select public.authorize_virgil_action('${U}','recommendation',null)`) ?? ''));
ok('anon cannot run authorize_virgil_action', /permission denied/i.test(await asErr('anon', null, `select public.authorize_virgil_action('${U}','recommendation',null)`) ?? ''));
ok('anon cannot run the check RPC', /permission denied|not_authenticated/i.test(await asErr('anon', null, `select public.try_consume_virgil_usage('recommendation')`) ?? ''));
ok('authenticated cannot read tickets', /permission denied/i.test(await asErr('authenticated', U, `select * from public.virgil_search_tickets`) ?? ''));
ok('check RPC rejects unauthenticated JWT-less caller', /not_authenticated/.test(await asErr('authenticated', null, `select public.try_consume_virgil_usage('recommendation')`) ?? ''));

console.log('\n3. first search consumes one unit and opens a ticket');
ok('authorize true', await auth(U, 'recommendation', 'h1') === true);
ok('count is 1', (await count(U)).r === 1);
const t = (await db.query(`select calls_left, expires_at > now() as live, expires_at < now() + interval '31 minutes' as short from public.virgil_search_tickets where user_id=$1 and query_hash='h1'`, [U])).rows[0];
ok('ticket has 9 calls left, ~30 min TTL', t.calls_left === 9 && t.live && t.short, JSON.stringify(t));

console.log('\n4. repeats of the same query are free until the ticket runs out');
let allFree = true;
for (let i = 0; i < 9; i++) allFree = allFree && (await auth(U, 'recommendation', 'h1')) === true;
ok('9 more calls allowed', allFree);
ok('count still 1', (await count(U)).r === 1);
ok('11th call consumes a second unit', await auth(U, 'recommendation', 'h1') === true && (await count(U)).r === 2);

console.log('\n5. different queries each cost a unit; hard limit is 5');
ok('h2 allowed (3)', await auth(U, 'recommendation', 'h2') === true);
ok('h3 allowed (4)', await auth(U, 'recommendation', 'h3') === true);
ok('h4 allowed (5)', await auth(U, 'recommendation', 'h4') === true);
ok('h5 denied at limit', await auth(U, 'recommendation', 'h5') === false);
ok('count stays 5', (await count(U)).r === 5);
ok('denied search left no ticket', (await db.query(`select 1 from public.virgil_search_tickets where user_id=$1 and query_hash='h5'`, [U])).rows.length === 0);
ok('an open ticket still works at the limit', await auth(U, 'recommendation', 'h4') === true);
ok('old-client check now false', await check(U, 'recommendation') === false);

console.log('\n6. no query hash => always a unit');
ok('user V no-hash allowed', await auth(V, 'recommendation') === true && (await count(V)).r === 1);
ok('again costs another', await auth(V, 'recommendation') === true && (await count(V)).r === 2);

console.log('\n7. uploads: limit 3, independent of recommendations');
ok('3 uploads allowed', [1, 2, 3].every(async () => true) && (await auth(U, 'upload')) && (await auth(U, 'upload')) && (await auth(U, 'upload')));
ok('4th denied', await auth(U, 'upload') === false);
ok('upload count 3, recs untouched', (await count(U)).u === 3 && (await count(U)).r === 5);
ok('old-client upload check false', await check(U, 'upload') === false);

console.log('\n8. expired ticket is not honoured');
await db.query(`update public.virgil_usage_daily set recommendations_count = 0 where user_id=$1`, [V]);
await auth(V, 'recommendation', 'e1');
await db.query(`update public.virgil_search_tickets set expires_at = now() - interval '1 minute' where user_id=$1 and query_hash='e1'`, [V]);
const before = (await count(V)).r;
ok('expired ticket -> consumes again', await auth(V, 'recommendation', 'e1') === true && (await count(V)).r === before + 1);
ok('ticket renewed with 9 calls', (await db.query(`select calls_left from public.virgil_search_tickets where user_id=$1 and query_hash='e1'`, [V])).rows[0].calls_left === 9);

console.log('\n9. usage report and argument validation');
const rep = (await as('authenticated', U, `select * from public.get_virgil_usage_today()`)).rows[0];
ok('get_virgil_usage_today reports 5/3 limits and counts', rep.recommendations_limit === 5 && rep.uploads_limit === 3 && rep.recommendations_count === 5 && rep.uploads_count === 3, JSON.stringify(rep));
ok('null user rejected', /not_authenticated/.test(await asErr('service_role', null, `select public.authorize_virgil_action(null,'recommendation',null)`) ?? ''));
ok('unknown action rejected', /invalid_action/.test(await asErr('service_role', null, `select public.authorize_virgil_action('${U}','bogus',null)`) ?? ''));
ok('check RPC rejects unknown action', /invalid_action/.test(await asErr('authenticated', U, `select public.try_consume_virgil_usage('bogus')`) ?? ''));

console.log('\n10. old-client flow (check, then server spends) never double-charges');
const W = '33333333-3333-3333-3333-333333333333';
await db.exec(`insert into auth.users values ('${W}')`);
for (let i = 1; i <= 5; i++) {
  const allowed = await check(W, 'recommendation');
  const spent = allowed ? await auth(W, 'recommendation', `q${i}`) : false;
  if (!(allowed && spent)) { ok(`search ${i} allowed`, false); break; }
}
ok('5 searches -> count exactly 5', (await count(W)).r === 5);
ok('6th blocked on the client check', await check(W, 'recommendation') === false);

// ---------------------------------------------------------------------------
// Follow-up migration: trbook_description quota, refunds, _ex variant.
// ---------------------------------------------------------------------------
const ex = async (uid, action, hash = null) => (await as('service_role', null, `select public.authorize_virgil_action_ex('${uid}', '${action}', ${hash ? `'${hash}'` : 'null'}) as r`)).rows[0].r;
const refund = async (uid, action, kind, hash = null) => as('service_role', null, `select public.refund_virgil_action('${uid}', '${action}', '${kind}', ${hash ? `'${hash}'` : 'null'})`);
const cnt = async (uid) => (await db.query(`select recommendations_count r, uploads_count u, trbook_descriptions_count t from public.virgil_usage_daily where user_id=$1`, [uid])).rows[0];
const ticketLeft = async (uid, h) => (await db.query(`select calls_left from public.virgil_search_tickets where user_id=$1 and query_hash=$2`, [uid, h])).rows[0]?.calls_left ?? null;
const X = '44444444-4444-4444-4444-444444444444';
await db.exec(`insert into auth.users values ('${X}')`);

console.log('\n11. trbook_description: its own daily limit of 10');
let allOk = true;
for (let i = 0; i < 10; i++) allOk = allOk && (await ex(X, 'trbook_description')) === 'unit';
ok('10 generations allowed', allOk && (await cnt(X)).t === 10);
ok('11th denied', await ex(X, 'trbook_description') === 'denied' && (await cnt(X)).t === 10);
ok('independent of the other counters', (await cnt(X)).r === 0 && (await cnt(X)).u === 0);
ok('boolean wrapper agrees (denied -> false)', await auth(X, 'trbook_description') === false);
ok('the old-client check RPC understands the new action', await check(X, 'trbook_description') === false);
ok('...and says yes for a user with no usage yet', await check('22222222-2222-2222-2222-222222222222', 'trbook_description') === true);

console.log('\n12. authorize_virgil_action_ex reports what was spent');
const Y = '55555555-5555-5555-5555-555555555555';
await db.exec(`insert into auth.users values ('${Y}')`);
ok("first search -> 'unit'", await ex(Y, 'recommendation', 'q1') === 'unit');
ok("repeat of the same query -> 'ticket'", await ex(Y, 'recommendation', 'q1') === 'ticket');
ok("a new query -> 'unit'", await ex(Y, 'recommendation', 'q2') === 'unit');
ok("upload -> 'unit'", await ex(Y, 'upload') === 'unit');
ok('boolean wrapper true when allowed', await auth(Y, 'recommendation', 'q1') === true);

console.log('\n13. refunds give back exactly what was spent');
const Z = '66666666-6666-6666-6666-666666666666';
await db.exec(`insert into auth.users values ('${Z}')`);
await ex(Z, 'recommendation', 'r1');
ok('after a paid search: count 1, ticket 9', (await cnt(Z)).r === 1 && await ticketLeft(Z, 'r1') === 9);
await ex(Z, 'recommendation', 'r1');
ok('a ticket call leaves 8', await ticketLeft(Z, 'r1') === 8);
await refund(Z, 'recommendation', 'ticket', 'r1');
ok('refunding the ticket call -> 9 again, count untouched', await ticketLeft(Z, 'r1') === 9 && (await cnt(Z)).r === 1);
await refund(Z, 'recommendation', 'ticket', 'r1');
ok('ticket refunds are capped at 9', await ticketLeft(Z, 'r1') === 9);
await refund(Z, 'recommendation', 'unit', 'r1');
ok('refunding the paid unit -> count 0 and the ticket is dropped', (await cnt(Z)).r === 0 && await ticketLeft(Z, 'r1') === null);
ok('the retry pays again (like the failed call would have)', await ex(Z, 'recommendation', 'r1') === 'unit' && (await cnt(Z)).r === 1);
await refund(Z, 'recommendation', 'unit');
await refund(Z, 'recommendation', 'unit');
ok('counters never go below zero', (await cnt(Z)).r === 0);
await ex(Z, 'upload'); await refund(Z, 'upload', 'unit');
ok('upload refund', (await cnt(Z)).u === 0);
await ex(Z, 'trbook_description'); await refund(Z, 'trbook_description', 'unit');
ok('description refund', (await cnt(Z)).t === 0);
for (let i = 0; i < 3; i++) await ex(Z, 'upload');
const blocked = await ex(Z, 'upload') === 'denied';
await refund(Z, 'upload', 'unit');
ok('a refund at the limit frees a slot', blocked && await ex(Z, 'upload') === 'unit');
ok('refund rejects unknown kind', /invalid_kind/.test(await asErr('service_role', null, `select public.refund_virgil_action('${Z}','recommendation','weird',null)`) ?? ''));
ok('refund rejects unknown action', /invalid_action/.test(await asErr('service_role', null, `select public.refund_virgil_action('${Z}','bogus','unit',null)`) ?? ''));
ok('refund rejects a null user', /not_authenticated/.test(await asErr('service_role', null, `select public.refund_virgil_action(null,'upload','unit',null)`) ?? ''));

console.log('\n14. the new functions are service-only');
for (const fn of [`public.authorize_virgil_action_ex('${Z}','upload',null)`, `public.refund_virgil_action('${Z}','upload','unit',null)`, `public.authorize_virgil_action('${Z}','upload',null)`]) {
  const name = fn.split('(')[0];
  ok(`anon cannot call ${name}`, /permission denied/i.test(await asErr('anon', null, `select ${fn}`) ?? ''));
  ok(`authenticated cannot call ${name}`, /permission denied/i.test(await asErr('authenticated', Z, `select ${fn}`) ?? ''));
}

console.log(`\n${pass} passed, ${fail} failed`);
process.exit(fail ? 1 : 0);
