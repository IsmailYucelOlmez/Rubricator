/**
 * Browser-origin allow-list shared by the public edge functions.
 *
 * Native apps send no Origin header and are never affected. Browsers get an
 * exact match against the built-in defaults plus the optional ALLOWED_ORIGINS
 * secret (comma-separated). `scheme://host:*` allows any port (local dev).
 */

export interface EnvLike {
  get(name: string): string | undefined;
}

/**
 * Browser origins always allowed, in addition to ALLOWED_ORIGINS.
 *
 * `ismailyucelolmez.github.io` stays here during the migration to the custom
 * domain (GitHub Pages 301s it there, but caches and old links may still
 * resolve it directly for a while) — remove once traffic there is gone.
 */
export const DEFAULT_ALLOWED_ORIGINS = [
  "https://rubricator.site",
  "https://www.rubricator.site",
  "https://ismailyucelolmez.github.io",
  "http://localhost:*",
  "http://127.0.0.1:*",
];

export function allowedOrigins(env: EnvLike): string[] {
  const extra = (env.get("ALLOWED_ORIGINS") ?? "")
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean);
  return [...DEFAULT_ALLOWED_ORIGINS, ...extra];
}

function escapeRegExp(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

/** Exact match, or `scheme://host:*` for any port. */
export function isAllowedOrigin(origin: string, allowed: string[]): boolean {
  return allowed.some((entry) =>
    entry.endsWith(":*")
      ? new RegExp(`^${escapeRegExp(entry.slice(0, -2))}(:\\d+)?$`).test(origin)
      : entry === origin
  );
}

/** CORS response headers for an (already allowed) request origin. */
export function corsHeaders(
  origin: string | null,
  methods: string,
): Record<string, string> {
  if (!origin) return {};
  return {
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": methods,
    "Access-Control-Max-Age": "600",
    "Vary": "Origin",
  };
}
