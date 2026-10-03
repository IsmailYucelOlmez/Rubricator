import "jsr:@supabase/functions-js@2/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

import { createHandler } from "./handler.ts";

/**
 * Permanent, self-service account deletion (profile page → "Delete account").
 * See handler.ts for the rules.
 *
 * Flow: the app calls `signInWithOtp(shouldCreateUser: false)` for the
 * signed-in user's email, so the "Magic Link" email template must show
 * `{{ .Token }}`. The user types the code, the app posts it here with their
 * session JWT, and this function verifies it before deleting anything.
 *
 * `verify_jwt` is false in config.toml because the apps use `sb_publishable_*`
 * keys (not JWTs); the handler verifies the session JWT itself.
 *
 * Secrets: optional ALLOWED_ORIGINS. SUPABASE_URL, SUPABASE_ANON_KEY and
 * SUPABASE_SERVICE_ROLE_KEY are provided by the platform.
 */

const auth = { persistSession: false, autoRefreshToken: false };
const PROFILE_PHOTOS_BUCKET = "profile-photos";

function requireEnv(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing env ${name}`);
  return value;
}

const adminClient = () =>
  createClient(
    requireEnv("SUPABASE_URL"),
    requireEnv("SUPABASE_SERVICE_ROLE_KEY"),
    { auth },
  );

function publicClient(apikey: string | null) {
  // GoTrue needs an API key alongside the token; prefer the platform's anon
  // key and fall back to the one the caller sent (only a valid project key
  // gets an answer, so this does not widen access).
  const key = Deno.env.get("SUPABASE_ANON_KEY")?.trim() || apikey?.trim();
  if (!key) return null;
  return createClient(requireEnv("SUPABASE_URL"), key, { auth });
}

const handler = createHandler({
  env: Deno.env,

  async getUser(token, apikey) {
    const client = publicClient(apikey);
    if (!client) return null;
    const { data, error } = await client.auth.getUser(token);
    if (error || !data.user) return null;
    return { id: data.user.id, email: data.user.email ?? null };
  },

  async verifyOtp(email, code) {
    const client = publicClient(null) ?? adminClient();
    const { data, error } = await client.auth.verifyOtp({
      email,
      token: code,
      type: "email",
    });
    return error || !data.user ? null : data.user.id;
  },

  async deleteAccount(userId) {
    const admin = adminClient();
    // Avatars live under `<userId>/` (see AuthService.uploadProfilePhoto).
    const bucket = admin.storage.from(PROFILE_PHOTOS_BUCKET);
    const { data: files, error: listError } = await bucket.list(userId, {
      limit: 1000,
    });
    if (listError) throw new Error(listError.message);
    if (files && files.length > 0) {
      const { error } = await bucket.remove(
        files.map((f) => `${userId}/${f.name}`),
      );
      if (error) throw new Error(error.message);
    }
    const { error } = await admin.auth.admin.deleteUser(userId);
    if (error) throw new Error(error.message);
  },

  log(event, detail) {
    console.log(JSON.stringify({ event, ...detail }));
  },
});

Deno.serve(handler);
