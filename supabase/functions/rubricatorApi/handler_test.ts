import { assert, assertEquals } from "jsr:@std/assert@1";

import { allowedOrigins } from "../_shared/origin_policy.ts";
import {
  authMode,
  bearerJwt,
  createHandler,
  type Deps,
  isAllowedOrigin,
  normalizeQuery,
  type QuotaAction,
  ROUTES,
} from "./handler.ts";

// A syntactically valid (unsigned) JWT: the fake getUserId decides validity.
const JWT = "aaa.bbb.ccc";
const ORIGIN = "https://ismailyucelolmez.github.io";
const BASE = "https://x.supabase.co/functions/v1/rubricatorApi";

interface Calls {
  warn: string[];
  authorize: [string, QuotaAction, string | null][];
  refund: [string, QuotaAction, string, string | null][];
  upstream: { url: string; init: RequestInit }[];
}

function harness(opts: {
  user?: string | null;
  allow?: boolean;
  charge?: "unit" | "ticket";
  refundThrows?: boolean;
  upstreamThrows?: unknown;
  authorizeThrows?: boolean;
  env?: Record<string, string>;
  upstreamStatus?: number;
} = {}) {
  const calls: Calls = { authorize: [], refund: [], upstream: [], warn: [] };
  const env: Record<string, string> = {
    SEMANTIC_API_BASE_URL: "https://api.example.com/",
    SEMANTIC_API_KEY: "upstream-secret",
    AUTH_MODE: "enforce",
    ...opts.env,
  };
  const deps: Deps = {
    env: { get: (k) => env[k] },
    getUserId: (token) =>
      Promise.resolve(
        token === JWT ? (opts.user === undefined ? "user-1" : opts.user) : null,
      ),
    authorize: (uid, action, hash) => {
      calls.authorize.push([uid, action, hash]);
      if (opts.authorizeThrows) return Promise.reject(new Error("db down"));
      return Promise.resolve(
        (opts.allow ?? true) ? (opts.charge ?? "unit") : "denied",
      );
    },
    refund: (uid, action, charge, hash) => {
      calls.refund.push([uid, action, charge, hash]);
      return opts.refundThrows
        ? Promise.reject(new Error("db down"))
        : Promise.resolve();
    },
    fetchUpstream: (url, init) => {
      calls.upstream.push({ url, init });
      if (opts.upstreamThrows) return Promise.reject(opts.upstreamThrows);
      return Promise.resolve(
        new Response('{"ok":true}', {
          status: opts.upstreamStatus ?? 200,
          headers: { "Content-Type": "application/json" },
        }),
      );
    },
    sha256Hex: (t) => Promise.resolve(`hash(${t})`),
    warn: (message) => calls.warn.push(message),
  };
  return { handle: createHandler(deps), calls };
}

function req(
  path: string,
  init: RequestInit & { auth?: string | null } = {},
): Request {
  const { auth = `Bearer ${JWT}`, headers, ...rest } = init;
  const h = new Headers(headers);
  if (auth) h.set("Authorization", auth);
  return new Request(`${BASE}${path}`, { ...rest, headers: h });
}

const search = (query: unknown, extra: RequestInit = {}) =>
  req("/api/v1/semantic/search", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ query, limit: 16 }),
    ...extra,
  });

// --- authentication ---------------------------------------------------------

Deno.test("missing Authorization -> 401, nothing forwarded", async () => {
  const { handle, calls } = harness();
  const res = await handle(
    req("/api/v1/semantic/search", {
      method: "POST",
      auth: null,
      body: '{"query":"dark fantasy"}',
    }),
  );
  assertEquals(res.status, 401);
  assertEquals(calls.upstream.length, 0);
  assertEquals(calls.authorize.length, 0);
});

Deno.test("publishable/anon key (not a JWT) is rejected", async () => {
  const { handle, calls } = harness();
  const res = await handle(
    req("/api/v1/semantic/search", {
      method: "POST",
      auth: "Bearer sb_publishable_abcdef",
      body: '{"query":"dark fantasy"}',
    }),
  );
  assertEquals(res.status, 401);
  assertEquals(calls.upstream.length, 0);
  assertEquals(calls.authorize.length, 0);
});

Deno.test("JWT that GoTrue rejects -> 401", async () => {
  const { handle, calls } = harness({ user: null });
  const res = await handle(search("dark fantasy"));
  assertEquals(res.status, 401);
  assertEquals(calls.upstream.length, 0);
});

// --- monitor mode (default) --------------------------------------------------

Deno.test("monitor mode: unauthenticated request is forwarded, no quota, logged", async () => {
  const { handle, calls } = harness({ env: { AUTH_MODE: "monitor" } });
  const res = await handle(
    req("/api/v1/semantic/search", {
      method: "POST",
      auth: null,
      body: '{"query":"dark fantasy"}',
    }),
  );
  assertEquals(res.status, 200);
  assertEquals(calls.upstream.length, 1);
  assertEquals(calls.authorize.length, 0);
  assertEquals(calls.warn, ["unauthenticated_request_allowed"]);
});

Deno.test("monitor mode: expired/invalid JWT is treated as unauthenticated but allowed", async () => {
  const { handle, calls } = harness({
    user: null,
    env: { AUTH_MODE: "monitor" },
  });
  const res = await handle(search("dark fantasy"));
  assertEquals(res.status, 200);
  assertEquals(calls.authorize.length, 0);
  assertEquals(calls.warn.length, 1);
});

Deno.test("monitor mode: a valid JWT still gets quota enforced", async () => {
  const { handle, calls } = harness({
    allow: false,
    env: { AUTH_MODE: "monitor" },
  });
  const res = await handle(search("dark fantasy"));
  assertEquals(res.status, 429);
  assertEquals(calls.upstream.length, 0);
  assertEquals(calls.warn.length, 0);
});

Deno.test("monitor mode still enforces allow-list, origin and size caps", async () => {
  const { handle, calls } = harness({ env: { AUTH_MODE: "monitor" } });
  assertEquals(
    (await handle(req("/api/v1/admin", { method: "GET", auth: null }))).status,
    404,
  );
  assertEquals(
    (await handle(
      req("/api/v1/sessions/abc", {
        method: "GET",
        auth: null,
        headers: { Origin: "https://evil.example" },
      }),
    )).status,
    403,
  );
  assertEquals(
    (await handle(
      req("/api/v1/semantic/search", {
        method: "POST",
        auth: null,
        body: "x".repeat(17 * 1024),
      }),
    )).status,
    413,
  );
  assertEquals(calls.upstream.length, 0);
});

Deno.test("AUTH_MODE defaults to enforce; only an explicit 'monitor' relaxes it", () => {
  assertEquals(authMode({ get: () => undefined }), "enforce");
  assertEquals(authMode({ get: () => "" }), "enforce");
  assertEquals(authMode({ get: () => "strict" }), "enforce");
  assertEquals(authMode({ get: () => " Monitor " }), "monitor");
});

Deno.test("with AUTH_MODE unset, unauthenticated requests are rejected", async () => {
  const { handle, calls } = harness({ env: { AUTH_MODE: "" } });
  const res = await handle(
    req("/api/v1/semantic/search", {
      method: "POST",
      auth: null,
      body: '{"query":"dark fantasy"}',
    }),
  );
  assertEquals(res.status, 401);
  assertEquals(calls.upstream.length, 0);
});

// --- routing ----------------------------------------------------------------

Deno.test("unknown path -> 404, unknown method on known path -> 405", async () => {
  const { handle, calls } = harness();
  assertEquals(
    (await handle(req("/api/v1/admin", { method: "GET" }))).status,
    404,
  );
  assertEquals((await handle(req("/", { method: "GET" }))).status, 404);
  assertEquals(
    (await handle(req("/api/v1/semantic/search", { method: "GET" }))).status,
    405,
  );
  assertEquals(
    (await handle(req("/api/v1/sessions/abc", { method: "PUT" }))).status,
    405,
  );
  assertEquals(calls.upstream.length, 0);
});

Deno.test("path traversal / odd session ids never reach the upstream", async () => {
  const { handle, calls } = harness();
  for (
    const path of [
      "/api/v1/sessions/../secret",
      "/api/v1/sessions/a%2F..%2Fb",
      "/api/v1/sessions/a b",
      "/api/v1/sessions/" + "x".repeat(65),
    ]
  ) {
    const res = await handle(req(path, { method: "GET" }));
    assert(
      res.status === 404 || res.status === 405,
      `${path} -> ${res.status}`,
    );
  }
  assertEquals(calls.upstream.length, 0);
});

Deno.test("query string is not forwarded", async () => {
  const { handle, calls } = harness();
  await handle(req("/api/v1/sessions/abc123?admin=1", { method: "GET" }));
  assertEquals(
    calls.upstream[0].url,
    "https://api.example.com/api/v1/sessions/abc123",
  );
});

// --- forwarding -------------------------------------------------------------

Deno.test("forwards with the upstream key, not the caller's token", async () => {
  const { handle, calls } = harness();
  const res = await handle(search("Dark   Fantasy"));
  assertEquals(res.status, 200);
  const sent = calls.upstream[0];
  assertEquals(sent.url, "https://api.example.com/api/v1/semantic/search");
  const h = new Headers(sent.init.headers);
  assertEquals(h.get("Authorization"), "Bearer upstream-secret");
  assertEquals(h.get("Content-Type"), "application/json");
  assert(!JSON.stringify([...h.entries()]).includes(JWT));
});

Deno.test("forwards the verified user id, never a client-supplied one", async () => {
  const { handle, calls } = harness({ user: "user-1" });
  await handle(
    search("dark fantasy", { headers: { "X-User-Id": "someone-else" } }),
  );
  const h = new Headers(calls.upstream[0].init.headers);
  assertEquals(h.get("X-User-Id"), "user-1");
});

Deno.test("no verified user (monitor mode) -> no X-User-Id, even if the client sent one", async () => {
  const { handle, calls } = harness({ env: { AUTH_MODE: "monitor" } });
  await handle(
    req("/api/v1/sessions/abc", {
      method: "GET",
      auth: null,
      headers: { "X-User-Id": "spoofed" },
    }),
  );
  const h = new Headers(calls.upstream[0].init.headers);
  assertEquals(h.get("X-User-Id"), null);
});

Deno.test("upstream status and body pass through", async () => {
  const { handle } = harness({ upstreamStatus: 422 });
  const res = await handle(req("/api/v1/sessions/abc", { method: "GET" }));
  assertEquals(res.status, 422);
  assertEquals(await res.json(), { ok: true });
});

Deno.test("missing upstream secrets -> 500", async () => {
  const { handle, calls } = harness({
    env: { SEMANTIC_API_BASE_URL: "", SEMANTIC_API_KEY: "" },
  });
  const res = await handle(req("/api/v1/sessions/abc", { method: "GET" }));
  assertEquals(res.status, 500);
  assertEquals(calls.upstream.length, 0);
});

// --- quota ------------------------------------------------------------------

Deno.test("search consumes 'recommendation' keyed by the normalised query", async () => {
  const { handle, calls } = harness();
  await handle(search("  Dark   FANTASY "));
  await handle(search("dark fantasy"));
  assertEquals(calls.authorize.length, 2);
  assertEquals(calls.authorize[0], [
    "user-1",
    "recommendation",
    "hash(dark fantasy)",
  ]);
  assertEquals(calls.authorize[0][2], calls.authorize[1][2]);
});

Deno.test("limit reached -> 429 with a machine-readable error, upstream untouched", async () => {
  const { handle, calls } = harness({ allow: false });
  const res = await handle(search("dark fantasy"));
  assertEquals(res.status, 429);
  assertEquals(await res.json(), {
    error: "daily_limit_reached",
    action: "recommendation",
  });
  assertEquals(calls.upstream.length, 0);
});

Deno.test("quota backend failure fails closed -> 503", async () => {
  const { handle, calls } = harness({ authorizeThrows: true });
  const res = await handle(search("dark fantasy"));
  assertEquals(res.status, 503);
  assertEquals(calls.upstream.length, 0);
});

Deno.test("invalid search bodies are 400 and cost nothing", async () => {
  const { handle, calls } = harness();
  assertEquals((await handle(search("ab"))).status, 400);
  assertEquals((await handle(search(42))).status, 400);
  assertEquals((await handle(search("x".repeat(501)))).status, 400);
  const badJson = await handle(
    req("/api/v1/semantic/search", { method: "POST", body: "{nope" }),
  );
  assertEquals(badJson.status, 400);
  assertEquals(calls.authorize.length, 0);
  assertEquals(calls.upstream.length, 0);
});

Deno.test("document upload consumes 'upload' with no query hash", async () => {
  const { handle, calls } = harness();
  const res = await handle(
    req("/api/v1/sessions", {
      method: "POST",
      headers: { "Content-Type": "multipart/form-data; boundary=x" },
      body: "--x--",
    }),
  );
  assertEquals(res.status, 200);
  assertEquals(calls.authorize, [["user-1", "upload", null]]);
  const h = new Headers(calls.upstream[0].init.headers);
  assertEquals(h.get("Content-Type"), "multipart/form-data; boundary=x");
});

Deno.test("chat / get / delete need auth but spend no quota", async () => {
  const { handle, calls } = harness();
  await handle(
    req("/api/v1/sessions/abc/chat", { method: "POST", body: '{"q":1}' }),
  );
  await handle(req("/api/v1/sessions/abc", { method: "GET" }));
  await handle(req("/api/v1/sessions/abc", { method: "DELETE" }));
  assertEquals(calls.authorize.length, 0);
  assertEquals(calls.upstream.length, 3);
});

// --- refunds ----------------------------------------------------------------

Deno.test("upstream 5xx / 429 refunds exactly what was spent", async () => {
  for (const status of [500, 502, 503, 504, 429]) {
    const { handle, calls } = harness({ upstreamStatus: status });
    const res = await handle(search("dark fantasy"));
    assertEquals(res.status, status);
    assertEquals(calls.refund, [[
      "user-1",
      "recommendation",
      "unit",
      "hash(dark fantasy)",
    ]], String(status));
  }
});

Deno.test("a search-ticket call is refunded as a ticket call", async () => {
  const { handle, calls } = harness({ charge: "ticket", upstreamStatus: 503 });
  await handle(search("dark fantasy"));
  assertEquals(calls.refund[0][2], "ticket");
});

Deno.test("successful and 4xx responses are not refunded", async () => {
  for (const status of [200, 201, 400, 404, 413, 415, 422]) {
    const { handle, calls } = harness({ upstreamStatus: status });
    await handle(search("dark fantasy"));
    assertEquals(calls.refund.length, 0, String(status));
  }
});

Deno.test("network failure -> 502 and refund; timeout -> 504 and refund", async () => {
  const net = harness({ upstreamThrows: new TypeError("connection reset") });
  assertEquals((await net.handle(search("dark fantasy"))).status, 502);
  assertEquals(net.calls.refund.length, 1);

  const slow = harness({
    upstreamThrows: new DOMException("x", "TimeoutError"),
  });
  assertEquals((await slow.handle(search("dark fantasy"))).status, 504);
  assertEquals(slow.calls.refund.length, 1);
});

Deno.test("a failing refund never changes the response", async () => {
  const { handle, calls } = harness({
    upstreamStatus: 503,
    refundThrows: true,
  });
  const res = await handle(search("dark fantasy"));
  assertEquals(res.status, 503);
  assertEquals(calls.warn, ["quota_refund_failed"]);
});

Deno.test("routes without quota, and quota denials, never refund", async () => {
  const free = harness({ upstreamStatus: 503 });
  await free.handle(req("/api/v1/sessions/abc", { method: "GET" }));
  assertEquals(free.calls.refund.length, 0);
  const denied = harness({ allow: false });
  assertEquals((await denied.handle(search("dark fantasy"))).status, 429);
  assertEquals(denied.calls.refund.length, 0);
});

Deno.test("upload failures refund the 'upload' unit", async () => {
  const { handle, calls } = harness({ upstreamStatus: 503 });
  await handle(
    req("/api/v1/sessions", {
      method: "POST",
      headers: { "Content-Type": "multipart/form-data; boundary=x" },
      body: "--x--",
    }),
  );
  assertEquals(calls.refund, [["user-1", "upload", "unit", null]]);
});

// --- Turkish-book description quota ------------------------------------------

Deno.test("generate-description consumes 'trbook_description' (no query hash)", async () => {
  const { handle, calls } = harness();
  const res = await handle(
    req("/api/v1/trbooks/generate-description", {
      method: "POST",
      body: '{"title":"a"}',
    }),
  );
  assertEquals(res.status, 200);
  assertEquals(calls.authorize, [["user-1", "trbook_description", null]]);
});

Deno.test("generate-description over its daily limit -> 429 with the action", async () => {
  const { handle, calls } = harness({ allow: false });
  const res = await handle(
    req("/api/v1/trbooks/generate-description", { method: "POST", body: "{}" }),
  );
  assertEquals(res.status, 429);
  assertEquals(await res.json(), {
    error: "daily_limit_reached",
    action: "trbook_description",
  });
  assertEquals(calls.upstream.length, 0);
});

Deno.test("upstream timeouts stay below the apps' own HTTP timeouts", () => {
  // Flutter Dio receiveTimeout: search/description 30 s, document chat 90 s.
  assert(ROUTES.find((r) => r.searchQuery)!.timeoutMs < 30_000);
  assert(
    ROUTES.find((r) => r.action === "trbook_description")!.timeoutMs < 30_000,
  );
  assert(ROUTES.every((r) => r.timeoutMs > 0 && r.timeoutMs < 90_000));
});

// --- size caps --------------------------------------------------------------

Deno.test("oversized bodies -> 413 before quota or upstream", async () => {
  const { handle, calls } = harness();
  const big = "x".repeat(17 * 1024);
  const res = await handle(
    req("/api/v1/semantic/search", { method: "POST", body: big }),
  );
  assertEquals(res.status, 413);
  const declared = await handle(
    req("/api/v1/sessions/abc/chat", {
      method: "POST",
      headers: { "Content-Length": String(10 * 1024 * 1024) },
      body: "{}",
    }),
  );
  assertEquals(declared.status, 413);
  assertEquals(calls.authorize.length, 0);
  assertEquals(calls.upstream.length, 0);
});

// --- CORS -------------------------------------------------------------------

Deno.test("allowed origin: preflight + actual response carry CORS headers", async () => {
  const { handle } = harness();
  const pre = await handle(
    req("/api/v1/semantic/search", {
      method: "OPTIONS",
      headers: { Origin: ORIGIN },
    }),
  );
  assertEquals(pre.status, 204);
  assertEquals(pre.headers.get("Access-Control-Allow-Origin"), ORIGIN);
  assertEquals(pre.headers.get("Vary"), "Origin");

  const res = await handle(
    search("dark fantasy", { headers: { Origin: ORIGIN } }),
  );
  assertEquals(res.headers.get("Access-Control-Allow-Origin"), ORIGIN);
});

Deno.test("disallowed origin -> 403 (preflight and request)", async () => {
  const { handle, calls } = harness();
  const evil = { Origin: "https://evil.example" };
  const pre = await handle(
    req("/api/v1/semantic/search", { method: "OPTIONS", headers: evil }),
  );
  assertEquals(pre.status, 403);
  assertEquals(pre.headers.get("Access-Control-Allow-Origin"), null);
  const res = await handle(search("dark fantasy", { headers: evil }));
  assertEquals(res.status, 403);
  assertEquals(calls.upstream.length, 0);
});

Deno.test("native apps (no Origin header) are unaffected and get no CORS headers", async () => {
  const { handle } = harness();
  const res = await handle(search("dark fantasy"));
  assertEquals(res.status, 200);
  assertEquals(res.headers.get("Access-Control-Allow-Origin"), null);
});

Deno.test("ALLOWED_ORIGINS adds a custom domain", async () => {
  const { handle } = harness({
    env: {
      ALLOWED_ORIGINS: "https://rubricator.app, https://www.rubricator.app",
    },
  });
  const res = await handle(
    search("dark fantasy", { headers: { Origin: "https://rubricator.app" } }),
  );
  assertEquals(res.status, 200);
});

// --- helpers ----------------------------------------------------------------

Deno.test("the production domain is allowed by default, no ALLOWED_ORIGINS needed", () => {
  const allowed = allowedOrigins({ get: () => undefined });
  assert(isAllowedOrigin("https://rubricator.site", allowed));
  assert(isAllowedOrigin("https://www.rubricator.site", allowed));
  assert(!isAllowedOrigin("https://rubricator.site.evil.io", allowed));
  assert(!isAllowedOrigin("http://rubricator.site", allowed), "must be https");
});

Deno.test("isAllowedOrigin: exact, any-port localhost, lookalikes rejected", () => {
  const allowed = ["https://a.com", "http://localhost:*"];
  assert(isAllowedOrigin("https://a.com", allowed));
  assert(isAllowedOrigin("http://localhost:8765", allowed));
  assert(isAllowedOrigin("http://localhost", allowed));
  assert(!isAllowedOrigin("https://a.com.evil.io", allowed));
  assert(!isAllowedOrigin("http://a.com", allowed));
  assert(!isAllowedOrigin("http://localhost.evil.io", allowed));
  assert(!isAllowedOrigin("http://localhostx:80", allowed));
});

Deno.test("bearerJwt only accepts JWT-shaped tokens", () => {
  assertEquals(bearerJwt("Bearer a.b.c"), "a.b.c");
  assertEquals(bearerJwt("bearer a.b.c"), "a.b.c");
  assertEquals(bearerJwt("Bearer sb_publishable_x"), null);
  assertEquals(bearerJwt("Bearer a.b"), null);
  assertEquals(bearerJwt("a.b.c"), null);
  assertEquals(bearerJwt(null), null);
  assertEquals(bearerJwt("Bearer " + "a.".repeat(2100) + "c"), null);
});

Deno.test("normalizeQuery folds case, whitespace and unicode forms", () => {
  assertEquals(normalizeQuery("  Dark \n FANTASY  "), "dark fantasy");
  assertEquals(normalizeQuery("ＡＢＣ"), "abc");
});
