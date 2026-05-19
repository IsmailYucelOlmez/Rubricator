/// <reference types="jsr:@supabase/functions-js/edge-runtime.d.ts" />

/**
 * Direct Postgres access for edge functions (service tasks, cron, cache refresh).
 * Requires secret `DB_SUPABASE_PASSWORD` (database password from the dashboard).
 */
export function databaseUrlFromEnv(): string | null {  const password = Deno.env.get("DB_SUPABASE_PASSWORD")?.trim();
  if (!password) return null;

  const supabaseUrl = Deno.env.get("SUPABASE_URL")?.trim();
  if (!supabaseUrl) return null;

  try {
    const host = new URL(supabaseUrl).hostname;
    const projectRef = host.split(".")[0];
    if (!projectRef) return null;
    const user = "postgres";
    const dbHost = `db.${projectRef}.supabase.co`;
    const encoded = encodeURIComponent(password);
    return `postgresql://${user}:${encoded}@${dbHost}:5432/postgres`;
  } catch {
    return null;
  }
}
