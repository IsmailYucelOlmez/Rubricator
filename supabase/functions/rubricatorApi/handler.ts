/**
 * Request handling for the `rubricatorApi` edge function, kept free of I/O so
 * it can be unit-tested with fakes (see handler_test.ts). `index.ts` wires the
 * real Supabase / fetch dependencies.
 *
 * This function proxies to the Gemini-backed FastAPI using a server-side
 * secret, so it must never be an open relay. Every request therefore:
 *   1. matches an allow-listed method + path (nothing else is forwarded),
 *   2. comes from an allowed browser origin (native apps send no Origin),
 *   3. carries a valid Supabase user JWT (see AUTH_MODE below),
 *   4. stays within a per-route body-size cap, and
 *   5. for costly routes, consumes the user's daily Virgil quota server-side.
 *
 * AUTH_MODE (secret, default "enforce") controls step 3 for requests WITHOUT a
 * valid user JWT:
 *   - "enforce" (default): rejected with 401.
 *   - "monitor" (opt-in, temporary rollout aid): forwarded as before (no quota, since there is no user) and
 *     logged as `unauthenticated_request_allowed`. Older app builds bake the
 *     session token into their HTTP client once, so it expires after ~1h and
 *     they would start failing; monitor mode lets them keep working until
 *     enough users have updated. Requests WITH a valid JWT always get quota.
 * Steps 1, 2 and 4 apply in both modes.
 */

import {
  allowedOrigins,
  corsHeaders,
  isAllowedOrigin,
} from "../_shared/origin_policy.ts";

export type QuotaAction = "recommendation" | "upload" | "trbook_description";

/**
 * What a successful authorisation spent: a daily unit, or one call of an open
 * per-query search ticket. Needed to give exactly that back on failure.
 */
export type Charge = "unit" | "ticket";

export interface Deps {
  env: { get(name: string): string | undefined };
  /** Verifies a user JWT; returns the user id, or null when invalid/expired. */
  getUserId(token: string, apikey: string | null): Promise<string | null>;
  /**
   * Spends quota for the user (see authorize_virgil_action_ex in the migration).
   * Resolves "denied" when the daily limit is reached; throws on infra failure.
   */
  authorize(
    userId: string,
    action: QuotaAction,
    queryHash: string | null,
  ): Promise<Charge | "denied">;
  /** Gives back what authorize() spent. Best effort: errors are swallowed. */
  refund(
    userId: string,
    action: QuotaAction,
    charge: Charge,
    queryHash: string | null,
  ): Promise<void>;
  fetchUpstream(url: string, init: RequestInit): Promise<Response>;
  sha256Hex(text: string): Promise<string>;
  warn(message: string, data?: Record<string, unknown>): void;
}

interface Route {
  method: string;
  pattern: RegExp;
  maxBytes: number;
  /**
   * Upstream timeout. Kept below the apps' own HTTP timeouts so a call the
   * user already gave up on is refunded instead of silently spent.
   */
  timeoutMs: number;
  /** Quota action to consume before forwarding. */
  action?: QuotaAction;
  /** Route is a semantic search: hash the query so repeats share a ticket. */
  searchQuery?: boolean;
}

const KB = 1024;
const MB = 1024 * KB;
const SESSION = "[A-Za-z0-9_-]{1,64}";

/** The only upstream endpoints the apps use. Everything else is a 404. */
export const ROUTES: readonly Route[] = [
  {
    method: "POST",
    pattern: /^\/api\/v1\/semantic\/search$/,
    maxBytes: 16 * KB,
    timeoutMs: 25000,
    action: "recommendation",
    searchQuery: true,
  },
  {
    method: "POST",
    pattern: /^\/api\/v1\/sessions$/,
    maxBytes: 25 * MB, // document uploads are capped at 20 MB by the app
    timeoutMs: 55000,
    action: "upload",
  },
  {
    method: "GET",
    pattern: new RegExp(`^/api/v1/sessions/${SESSION}$`),
    maxBytes: 0,
    timeoutMs: 30_000,
  },
  {
    method: "DELETE",
    pattern: new RegExp(`^/api/v1/sessions/${SESSION}$`),
    maxBytes: 0,
    timeoutMs: 30_000,
  },
  {
    method: "POST",
    pattern: new RegExp(`^/api/v1/sessions/${SESSION}/chat$`),
    maxBytes: 16 * KB,
    timeoutMs: 80_000, // the app waits up to 90 s for an answer
  },
  {
    method: "POST",
    pattern: /^\/api\/v1\/trbooks\/generate-description$/,
    maxBytes: 8 * KB,
    timeoutMs: 25_000,
    action: "trbook_description",
  },
];

export function normalizeQuery(query: string): string {
  return query.normalize("NFKC").toLowerCase().replace(/\s+/g, " ").trim();
}

export function matchRoute(method: string, pathname: string): {
  route: Route | null;
  pathKnown: boolean;
} {
  let pathKnown = false;
  for (const route of ROUTES) {
    if (!route.pattern.test(pathname)) continue;
    pathKnown = true;
    if (route.method === method) return { route, pathKnown };
  }
  return { route: null, pathKnown };
}

/**
 * Extracts the path the FastAPI expects. Supports the deployed function name
 * and the legacy `semantic-api` alias.
 */
export function upstreamPath(pathname: string): string {
  for (
    const prefix of [
      "/functions/v1/rubricatorApi",
      "/functions/v1/semantic-api",
      "/rubricatorApi",
      "/semantic-api",
    ]
  ) {
    const idx = pathname.indexOf(prefix);
    if (idx >= 0) {
      const suffix = pathname.slice(idx + prefix.length);
      return suffix.length > 0 ? suffix : "/";
    }
  }
  const apiIdx = pathname.indexOf("/api/");
  return apiIdx >= 0 ? pathname.slice(apiIdx) : pathname || "/";
}

export type AuthMode = "enforce" | "monitor";

export function authMode(env: Deps["env"]): AuthMode {
  return env.get("AUTH_MODE")?.trim().toLowerCase() === "monitor"
    ? "monitor"
    : "enforce";
}

export { allowedOrigins, isAllowedOrigin };

const JWT_SHAPE = /^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/;

/** Bearer token, only when it looks like a JWT (publishable keys are not). */
export function bearerJwt(header: string | null): string | null {
  const match = header?.match(/^Bearer\s+(\S+)$/i);
  const token = match?.[1];
  if (!token || token.length > 4096 || !JWT_SHAPE.test(token)) return null;
  return token;
}

function json(
  body: unknown,
  status: number,
  extra: Record<string, string> = {},
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...extra },
  });
}

export function createHandler(deps: Deps): (req: Request) => Promise<Response> {
  return async (req: Request): Promise<Response> => {
    const origin = req.headers.get("Origin");
    if (origin && !isAllowedOrigin(origin, allowedOrigins(deps.env))) {
      return json({ error: "origin_not_allowed" }, 403);
    }
    const cors = corsHeaders(origin, "GET, POST, DELETE, OPTIONS");
    const reply = (body: unknown, status: number) => json(body, status, cors);

    if (req.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: cors });
    }

    const pathname = upstreamPath(new URL(req.url).pathname);
    const { route, pathKnown } = matchRoute(req.method, pathname);
    if (!route) {
      return reply(
        { error: pathKnown ? "method_not_allowed" : "not_found" },
        pathKnown ? 405 : 404,
      );
    }

    // Authentication: a real Supabase user session is required.
    const token = bearerJwt(req.headers.get("Authorization"));
    const userId = token
      ? await deps.getUserId(token, req.headers.get("apikey"))
      : null;
    if (!userId) {
      if (authMode(deps.env) === "enforce") {
        return reply({ error: "unauthorized" }, 401);
      }
      deps.warn("unauthenticated_request_allowed", {
        method: req.method,
        path: pathname,
        hadBearer: token !== null,
        origin,
      });
    }

    // Body size cap (declared length first, then the bytes actually read).
    const declared = Number(req.headers.get("Content-Length"));
    if (Number.isFinite(declared) && declared > route.maxBytes) {
      return reply({ error: "payload_too_large" }, 413);
    }
    let body: ArrayBuffer | undefined;
    if (route.maxBytes > 0) {
      body = await req.arrayBuffer();
      if (body.byteLength > route.maxBytes) {
        return reply({ error: "payload_too_large" }, 413);
      }
    }

    // Search: derive the ticket key from the normalised query text.
    let queryHash: string | null = null;
    if (route.searchQuery) {
      let query: unknown;
      try {
        query = JSON.parse(new TextDecoder().decode(body ?? new ArrayBuffer(0)))
          ?.query;
      } catch {
        return reply({ error: "invalid_json" }, 400);
      }
      const normalized = typeof query === "string" ? normalizeQuery(query) : "";
      if (normalized.length < 3 || normalized.length > 500) {
        return reply({ error: "invalid_query" }, 400);
      }
      queryHash = await deps.sha256Hex(normalized);
    }

    const baseUrl = (deps.env.get("SEMANTIC_API_BASE_URL") ??
      deps.env.get("RUBRICATOR_API_BASE_URL") ??
      deps.env.get("API_BASE_URL"))?.trim().replace(/\/$/, "");
    const apiKey = (deps.env.get("SEMANTIC_API_KEY") ??
      deps.env.get("RUBRICATOR_API_KEY") ??
      deps.env.get("API_KEY"))?.trim();
    if (!baseUrl || !apiKey) {
      return reply({ error: "upstream_not_configured" }, 500);
    }

    // Quota is spent before forwarding, so a call that fails on our side or
    // upstream is given back below. Fails closed on infra errors.
    let charge: Charge | null = null;
    if (route.action && userId) {
      try {
        const spent = await deps.authorize(userId, route.action, queryHash);
        if (spent === "denied") {
          return reply(
            { error: "daily_limit_reached", action: route.action },
            429,
          );
        }
        charge = spent;
      } catch {
        return reply({ error: "quota_check_failed" }, 503);
      }
    }
    const giveBack = async () => {
      if (!charge || !userId || !route.action) return;
      try {
        await deps.refund(userId, route.action, charge, queryHash);
      } catch {
        deps.warn("quota_refund_failed", { action: route.action });
      }
    };

    // Only these headers reach the upstream; the caller's own Authorization
    // (their user JWT) is deliberately not forwarded.
    const headers = new Headers({
      Authorization: `Bearer ${apiKey}`,
      Accept: req.headers.get("Accept") ?? "application/json",
    });
    const contentType = req.headers.get("Content-Type");
    if (contentType && body) headers.set("Content-Type", contentType);
    // The API rate-limits per account, not per IP (every request reaches it from
    // this function's egress IP). Only the id verified above is ever sent; a
    // client-supplied X-User-Id is dropped with the rest of the caller's headers.
    if (userId) headers.set("X-User-Id", userId);

    try {
      const upstream = await deps.fetchUpstream(`${baseUrl}${pathname}`, {
        method: req.method,
        headers,
        body,
        signal: AbortSignal.timeout(route.timeoutMs),
      });
      // 5xx and 429 mean the user was not served (crash, timeout, capacity or
      // the API's own rate limit): refund. 4xx are the caller's problem.
      if (upstream.status >= 500 || upstream.status === 429) await giveBack();
      const responseHeaders = new Headers(cors);
      responseHeaders.set(
        "Content-Type",
        upstream.headers.get("Content-Type") ?? "application/json",
      );
      return new Response(upstream.body, {
        status: upstream.status,
        headers: responseHeaders,
      });
    } catch (error) {
      await giveBack();
      const timedOut = error instanceof DOMException &&
        error.name === "TimeoutError";
      return reply(
        { error: timedOut ? "upstream_timeout" : "upstream_unreachable" },
        timedOut ? 504 : 502,
      );
    }
  };
}
