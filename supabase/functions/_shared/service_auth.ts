/**
 * Guard for edge functions that must only be invoked by the platform itself
 * (pg_cron via pg_net, or an admin with the service key). They run with the
 * service role, so an unauthenticated public endpoint would let anyone trigger
 * scraping / cache rewrites.
 *
 * `verify_jwt` is false for these functions (the apps' keys aren't JWTs), so
 * the check lives here: the caller must present `Authorization: Bearer <key>`
 * where <key> is SUPABASE_SERVICE_ROLE_KEY, or the optional CRON_SECRET (use it
 * if the key stored in Vault for the cron job differs from the env one).
 */
interface EnvLike {
  get(name: string): string | undefined;
}

/** Constant-time string comparison (does not short-circuit on a mismatch). */
export function timingSafeEqual(a: string, b: string): boolean {
  const enc = new TextEncoder();
  const x = enc.encode(a);
  const y = enc.encode(b);
  let diff = x.length ^ y.length;
  const n = Math.max(x.length, y.length);
  for (let i = 0; i < n; i++) diff |= (x[i] ?? 0) ^ (y[i] ?? 0);
  return diff === 0;
}

export function isServiceRequest(req: Request, env: EnvLike): boolean {
  const token = req.headers.get("Authorization")?.match(/^Bearer\s+(\S+)$/i)
    ?.[1];
  if (!token) return false;
  const secrets = [
    env.get("SUPABASE_SERVICE_ROLE_KEY"),
    env.get("CRON_SECRET"),
  ].map((s) => s?.trim()).filter((s): s is string => !!s);
  // Check every candidate (no early exit) to keep timing independent of which
  // secret matched.
  return secrets.reduce(
    (matched, secret) => timingSafeEqual(token, secret) || matched,
    false,
  );
}
