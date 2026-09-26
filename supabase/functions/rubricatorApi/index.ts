import "jsr:@supabase/functions-js@2/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

import { createHandler, type Deps } from "./handler.ts";

/**
 * Authenticated, quota-enforcing proxy to the FastAPI (semantic search,
 * document chat, Turkish-book descriptions). See handler.ts for the rules and
 * migration 20260925000000_virgil_server_side_quota.sql for the quota RPC.
 *
 * `verify_jwt` stays false in config.toml because the apps use `sb_publishable_*`
 * keys, which are not JWTs; the handler verifies the user's session JWT itself.
 *
 * Secrets: SEMANTIC_API_BASE_URL / SEMANTIC_API_KEY (upstream),
 * optional ALLOWED_ORIGINS (comma-separated browser origins) and
 * AUTH_MODE ("enforce" by default; "monitor" is a temporary opt-in).
 * SUPABASE_URL, SUPABASE_ANON_KEY and SUPABASE_SERVICE_ROLE_KEY are provided by
 * the platform.
 */

const auth = { persistSession: false, autoRefreshToken: false };

function requireEnv(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing env ${name}`);
  return value;
}

function adminClient() {
  return createClient(
    requireEnv("SUPABASE_URL"),
    requireEnv("SUPABASE_SERVICE_ROLE_KEY"),
    { auth },
  );
}

const deps: Deps = {
  env: Deno.env,

  async getUserId(token, apikey) {
    // GoTrue needs an API key alongside the token; prefer the platform's anon
    // key and fall back to the one the caller sent (only a valid project key
    // gets an answer, so this does not widen access).
    const key = Deno.env.get("SUPABASE_ANON_KEY")?.trim() || apikey?.trim();
    if (!key) return null;
    const client = createClient(requireEnv("SUPABASE_URL"), key, { auth });
    const { data, error } = await client.auth.getUser(token);
    return error || !data.user ? null : data.user.id;
  },

  async authorize(userId, action, queryHash) {
    const { data, error } = await adminClient().rpc(
      "authorize_virgil_action_ex",
      { p_uid: userId, p_action: action, p_query_hash: queryHash },
    );
    if (error) throw new Error(error.message);
    return data === "unit" || data === "ticket" ? data : "denied";
  },

  async refund(userId, action, charge, queryHash) {
    const { error } = await adminClient().rpc("refund_virgil_action", {
      p_uid: userId,
      p_action: action,
      p_kind: charge,
      p_query_hash: queryHash,
    });
    if (error) throw new Error(error.message);
  },

  fetchUpstream: (url, init) => fetch(url, init),

  warn: (message, data) => console.warn(message, JSON.stringify(data ?? {})),

  async sha256Hex(text) {
    const digest = await crypto.subtle.digest(
      "SHA-256",
      new TextEncoder().encode(text),
    );
    return Array.from(new Uint8Array(digest))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");
  },
};

Deno.serve(createHandler(deps));
