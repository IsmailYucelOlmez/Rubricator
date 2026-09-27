/**
 * Request handling for the `google-books` edge function, free of I/O so it can
 * be unit-tested (see handler_test.ts); `index.ts` wires the real fetch.
 *
 * The function adds the project's Google Books API key to requests, and it has
 * to stay callable by signed-out users (publishable key only), so it can't
 * require a user JWT. Instead it is deliberately narrow, so the key can only be
 * used for what the apps do -- book search and single-volume lookups:
 *   - only GET /volumes and GET /volumes/{id} (before, any path under
 *     https://www.googleapis.com/books/v1 was forwarded, and `..` segments
 *     could climb out of it to other Google APIs the key may be enabled for),
 *   - only known query parameters, with bounded values,
 *   - browser requests only from allowed origins (was CORS `*`),
 *   - upstream failures never echo the URL (it contains the key).
 *
 * Also restrict the key itself in Google Cloud Console (API restriction to
 * "Books API" and a daily quota): see xdocs/rubricator_api_security.md.
 */
import {
  allowedOrigins,
  corsHeaders,
  type EnvLike,
  isAllowedOrigin,
} from "../_shared/origin_policy.ts";

export interface Deps {
  env: EnvLike;
  fetchUpstream(url: string, init: RequestInit): Promise<Response>;
  log(message: string, data?: Record<string, unknown>): void;
}

export const GOOGLE_BOOKS_BASE = "https://www.googleapis.com/books/v1";
const FUNCTION_PREFIX = "/google-books";
const VOLUME_ID = /^[A-Za-z0-9_-]{1,64}$/;
const UPSTREAM_TIMEOUT_MS = 15_000;
const MAX_QUERY_LENGTH = 512;
const METHODS = "GET, OPTIONS";

export type Route = { kind: "list" } | { kind: "volume"; id: string };

/** Maps the request path to the one of the two allowed Google Books routes. */
export function resolveRoute(pathname: string): Route | null {
  const idx = pathname.indexOf(FUNCTION_PREFIX);
  // Without the function prefix (e.g. after `..` normalisation, or when run
  // locally) the whole path is judged, so it can only ever match the two routes.
  const suffix = idx >= 0
    ? pathname.slice(idx + FUNCTION_PREFIX.length)
    : pathname;
  if (suffix === "" || suffix === "/" || /^\/volumes\/?$/.test(suffix)) {
    return { kind: "list" };
  }
  const match = suffix.match(/^\/volumes\/([^/]+)$/);
  if (match && VOLUME_ID.test(match[1])) {
    return { kind: "volume", id: match[1] };
  }
  return null;
}

const enumOf = (...values: string[]) => (v: string) =>
  values.includes(v) ? v : null;
const clampInt = (min: number, max: number) => (v: string) => {
  if (!/^\d{1,6}$/.test(v)) return null;
  return String(Math.min(max, Math.max(min, Number(v))));
};
const matching = (re: RegExp) => (v: string) => re.test(v) ? v : null;

type Sanitizer = (value: string) => string | null;

const COMMON: Record<string, Sanitizer> = {
  projection: enumOf("lite", "full"),
  fields: matching(/^[A-Za-z0-9_,.()*/]{1,300}$/),
  country: matching(/^[A-Za-z]{2}$/),
};

const LIST_PARAMS: Record<string, Sanitizer> = {
  ...COMMON,
  printType: enumOf("all", "books", "magazines"),
  maxResults: clampInt(1, 40),
  startIndex: clampInt(0, 1000),
  langRestrict: matching(/^[A-Za-z]{2,3}(-[A-Za-z]{2,4})?$/),
  orderBy: enumOf("relevance", "newest"),
  filter: enumOf("partial", "full", "free-ebooks", "paid-ebooks", "ebooks"),
};

/**
 * Keeps only known parameters with valid values (unknown ones -- including any
 * caller-supplied `key` -- are dropped, out-of-range numbers are clamped).
 * A list request needs a bounded `q`.
 */
export function sanitizeParams(
  route: Route,
  incoming: URLSearchParams,
): { ok: true; params: URLSearchParams } | { ok: false; error: string } {
  const allowed = route.kind === "list" ? LIST_PARAMS : COMMON;
  const params = new URLSearchParams();
  for (const [name, sanitize] of Object.entries(allowed)) {
    const raw = incoming.get(name);
    const value = raw === null ? null : sanitize(raw);
    if (value !== null) params.set(name, value);
  }
  if (route.kind === "list") {
    const q = incoming.get("q")?.trim() ?? "";
    if (q.length === 0) return { ok: false, error: "missing_query" };
    if (q.length > MAX_QUERY_LENGTH) {
      return { ok: false, error: "query_too_long" };
    }
    params.set("q", q);
  }
  return { ok: true, params };
}

export function createHandler(deps: Deps): (req: Request) => Promise<Response> {
  return async (req: Request): Promise<Response> => {
    const origin = req.headers.get("Origin");
    if (origin && !isAllowedOrigin(origin, allowedOrigins(deps.env))) {
      return new Response(JSON.stringify({ error: "origin_not_allowed" }), {
        status: 403,
        headers: { "Content-Type": "application/json" },
      });
    }
    const cors = corsHeaders(origin, METHODS);
    const json = (body: unknown, status: number) =>
      new Response(JSON.stringify(body), {
        status,
        headers: { ...cors, "Content-Type": "application/json" },
      });

    if (req.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: cors });
    }
    if (req.method !== "GET") return json({ error: "method_not_allowed" }, 405);

    const apiKey = deps.env.get("GOOGLE_BOOKS_API_KEY")?.trim();
    if (!apiKey) return json({ error: "google_books_not_configured" }, 500);

    const incoming = new URL(req.url);
    const route = resolveRoute(incoming.pathname);
    if (!route) return json({ error: "not_found" }, 404);

    const checked = sanitizeParams(route, incoming.searchParams);
    if (!checked.ok) return json({ error: checked.error }, 400);

    const path = route.kind === "list" ? "/volumes" : `/volumes/${route.id}`;
    const target = new URL(`${GOOGLE_BOOKS_BASE}${path}`);
    checked.params.forEach((value, name) =>
      target.searchParams.set(name, value)
    );
    target.searchParams.set("key", apiKey);

    try {
      const upstream = await deps.fetchUpstream(target.toString(), {
        method: "GET",
        headers: { Accept: "application/json" },
        signal: AbortSignal.timeout(UPSTREAM_TIMEOUT_MS),
      });
      return new Response(await upstream.text(), {
        status: upstream.status,
        headers: {
          ...cors,
          "Content-Type": upstream.headers.get("Content-Type") ??
            "application/json",
          "Cache-Control": "public, s-maxage=300, stale-while-revalidate=86400",
        },
      });
    } catch (error) {
      // fetch errors quote the request URL, which contains the API key: log a
      // redacted form and never send the message to the caller.
      const message = (error instanceof Error ? error.message : String(error))
        .replaceAll(apiKey, "[redacted]");
      deps.log("upstream_failed", { route: route.kind, message });
      const timedOut = error instanceof DOMException &&
        error.name === "TimeoutError";
      return json(
        { error: timedOut ? "upstream_timeout" : "upstream_unreachable" },
        timedOut ? 504 : 502,
      );
    }
  };
}
