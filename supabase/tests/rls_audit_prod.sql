-- Live-database RLS audit. Paste into the Supabase SQL editor and run (read-only).
--
-- The migrations in this repo were audited by replaying them in a scratch
-- Postgres (see xdocs/rls_audit.md), which shows what THEY produce. Production
-- can differ: objects created in the dashboard, or migrations edited after they
-- ran, are invisible to that audit. This query reports the same findings on the
-- real database so the two can be compared.
--
-- Read the result as a list of things to justify. Expected/intentional rows are
-- listed in xdocs/rls_audit.md ("Bilerek açık olanlar").

select finding, object, detail
from (
  -- 1. public tables where RLS is off: anon/authenticated can read and write
  --    them freely through the REST API.
  select 'table_without_rls' as finding,
         c.relname::text as object,
         'RLS is disabled' as detail
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity

  union all
  -- 2. write policies that allow everything.
  select 'open_write_policy',
         p.tablename || '.' || p.policyname,
         p.cmd || ' to ' || p.roles::text
           || ' using=' || coalesce(p.qual, '-')
           || ' check=' || coalesce(p.with_check, '-')
  from pg_policies p
  where p.schemaname in ('public', 'storage')
    and p.cmd in ('INSERT', 'UPDATE', 'DELETE', 'ALL')
    and (p.qual = 'true' or p.with_check = 'true')

  union all
  -- 3. anything anonymous users can read.
  select 'anon_readable',
         p.tablename || '.' || p.policyname,
         p.cmd || ' using=' || coalesce(p.qual, '-')
  from pg_policies p
  where p.schemaname in ('public', 'storage')
    and p.cmd in ('SELECT', 'ALL')
    and (p.roles::text ~ 'anon' or p.roles::text ~ 'public')

  union all
  -- 4. SECURITY DEFINER functions (they bypass RLS) that anon can execute.
  --    Fine when they check auth.uid() or only return public aggregates;
  --    dangerous when they write or act on caller-supplied ids.
  select 'definer_function_callable_by_anon',
         p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')',
         case when pg_get_functiondef(p.oid) ilike '%auth.uid()%'
              then 'checks auth.uid()' else 'NO auth.uid() check' end
         || case when pg_get_functiondef(p.oid) ~* '\m(insert|update|delete)\M'
                 then ', WRITES' else '' end
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public'
    and p.prosecdef
    and has_function_privilege('anon', p.oid, 'execute')

  union all
  -- 5. views bypass RLS unless security_invoker is set.
  select 'view_without_security_invoker',
         c.relname::text,
         'anon can select: ' || has_table_privilege('anon', c.oid, 'select')::text
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relkind in ('v', 'm')
    and coalesce(c.reloptions::text, '') !~ 'security_invoker=(true|on)'

  union all
  -- 6. objects the apps use that no migration in the repo creates: their RLS
  --    was never reviewed. Check their policies in the rows above.
  select 'unmanaged_object',
         c.relname::text,
         'used by the app but not created by any migration'
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relkind = 'r'
    and c.relname in ('book_identity_cache', 'semantic_search_logs')

  union all
  select 'unmanaged_object',
         p.proname || '(' || pg_get_function_identity_arguments(p.oid) || ')',
         'used by the app but not created by any migration; SECURITY DEFINER='
           || p.prosecdef::text || ', anon can execute='
           || has_function_privilege('anon', p.oid, 'execute')::text
  from pg_proc p
  join pg_namespace n on n.oid = p.pronamespace
  where n.nspname = 'public' and p.proname = 'upsert_book_identity_cache'
) findings
order by finding, object;
