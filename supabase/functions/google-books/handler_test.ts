import { assert, assertEquals } from "jsr:@std/assert@1";

import { createHandler, resolveRoute, sanitizeParams } from "./handler.ts";

const BASE = "https://x.supabase.co/functions/v1/google-books";
const ORIGIN = "https://ismailyucelolmez.github.io";
const KEY = "AIzaSy-SECRET-KEY";

function harness(
  opts: { env?: Record<string, string>; fail?: unknown; status?: number } = {},
) {
  const calls: { url: string; init: RequestInit }[] = [];
  const logs: string[] = [];
  const env: Record<string, string> = {
    GOOGLE_BOOKS_API_KEY: KEY,
    ...opts.env,
  };
  const handle = createHandler({
    env: { get: (k) => env[k] },
    fetchUpstream: (url, init) => {
      calls.push({ url, init });
      if (opts.fail) return Promise.reject(opts.fail);
      return Promise.resolve(
        new Response('{"items":[]}', {
          status: opts.status ?? 200,
          headers: { "Content-Type": "application/json; charset=UTF-8" },
        }),
      );
    },
    log: (m) => logs.push(m),
  });
  return { handle, calls, logs };
}
const get = (path: string, headers: Record<string, string> = {}) =>
  new Request(`${BASE}${path}`, { headers });

// --- routing ----------------------------------------------------------------

Deno.test("only /volumes and /volumes/{id} are routable", () => {
  assertEquals(resolveRoute("/functions/v1/google-books"), { kind: "list" });
  assertEquals(resolveRoute("/functions/v1/google-books/"), { kind: "list" });
  assertEquals(resolveRoute("/functions/v1/google-books/volumes"), {
    kind: "list",
  });
  assertEquals(resolveRoute("/functions/v1/google-books/volumes/"), {
    kind: "list",
  });
  assertEquals(resolveRoute("/functions/v1/google-books/volumes/abc_DEF-12"), {
    kind: "volume",
    id: "abc_DEF-12",
  });
  for (
    const bad of [
      "/functions/v1/google-books/mylibrary/bookshelves",
      "/functions/v1/google-books/volumes/abc/associated",
      "/functions/v1/google-books/volumes/a b",
      "/functions/v1/google-books/volumes/" + "x".repeat(65),
      "/functions/v1/google-books/../customsearch/v1",
      "/functions/v1/google-books/%2e%2e/x",
      "/functions/v1/google-books/bookshelves",
    ]
  ) {
    assertEquals(resolveRoute(bad), null, bad);
  }
});

Deno.test("path traversal cannot leave the Books API", async () => {
  const { handle, calls } = harness();
  for (
    const path of [
      "/../../customsearch/v1?q=x",
      "/volumes/../../drive/v3/files",
      "/%2e%2e/%2e%2e/x",
      "/mylibrary/bookshelves?q=x",
    ]
  ) {
    const res = await handle(get(path));
    assertEquals(res.status, 404, path);
  }
  assertEquals(calls.length, 0);
});

// --- parameters -------------------------------------------------------------

Deno.test("known params pass, unknown params (incl. a caller's own key) are dropped", async () => {
  const { handle, calls } = harness();
  await handle(
    get(
      "/volumes?q=dune&printType=books&maxResults=20&langRestrict=tr&orderBy=newest&startIndex=40&key=EVIL&alt=media&callback=x",
    ),
  );
  const url = new URL(calls[0].url);
  assertEquals(
    url.origin + url.pathname,
    "https://www.googleapis.com/books/v1/volumes",
  );
  assertEquals(url.searchParams.get("q"), "dune");
  assertEquals(url.searchParams.get("maxResults"), "20");
  assertEquals(url.searchParams.get("langRestrict"), "tr");
  assertEquals(url.searchParams.get("orderBy"), "newest");
  assertEquals(url.searchParams.get("startIndex"), "40");
  assertEquals(url.searchParams.get("key"), KEY); // ours, never the caller's
  assertEquals(url.searchParams.has("alt"), false);
  assertEquals(url.searchParams.has("callback"), false);
});

Deno.test("numbers are clamped, malformed values dropped", () => {
  const r = sanitizeParams(
    { kind: "list" },
    new URLSearchParams(
      "q=x&maxResults=9999&startIndex=-5&printType=weird&orderBy=oldest&langRestrict=../&fields=items(id)&country=TURKEY",
    ),
  );
  assert(r.ok);
  if (r.ok) {
    assertEquals(r.params.get("maxResults"), "40");
    assertEquals(r.params.has("startIndex"), false);
    assertEquals(r.params.has("printType"), false);
    assertEquals(r.params.has("orderBy"), false);
    assertEquals(r.params.has("langRestrict"), false);
    assertEquals(r.params.get("fields"), "items(id)");
    assertEquals(r.params.has("country"), false);
  }
});

Deno.test("a list request needs a bounded q", async () => {
  const { handle, calls } = harness();
  assertEquals((await handle(get("/volumes"))).status, 400);
  assertEquals((await handle(get("/volumes?q=%20%20"))).status, 400);
  assertEquals(
    (await handle(get("/volumes?q=" + "a".repeat(513)))).status,
    400,
  );
  assertEquals(calls.length, 0);
});

Deno.test("volume lookup forwards only projection/fields/country", async () => {
  const { handle, calls } = harness();
  await handle(
    get("/volumes/zyTCAlFPjgYC?projection=lite&q=ignored&maxResults=5"),
  );
  const url = new URL(calls[0].url);
  assertEquals(url.pathname, "/books/v1/volumes/zyTCAlFPjgYC");
  assertEquals(url.searchParams.get("projection"), "lite");
  assertEquals(url.searchParams.has("q"), false);
  assertEquals(url.searchParams.has("maxResults"), false);
});

// --- methods, config, CORS --------------------------------------------------

Deno.test("only GET (and OPTIONS) are allowed", async () => {
  const { handle, calls } = harness();
  for (const method of ["POST", "PUT", "DELETE", "PATCH"]) {
    const res = await handle(new Request(`${BASE}/volumes?q=x`, { method }));
    assertEquals(res.status, 405, method);
  }
  assertEquals(calls.length, 0);
});

Deno.test("missing API key -> 500 without calling Google", async () => {
  const { handle, calls } = harness({ env: { GOOGLE_BOOKS_API_KEY: "" } });
  assertEquals((await handle(get("/volumes?q=x"))).status, 500);
  assertEquals(calls.length, 0);
});

Deno.test("allowed origin gets CORS headers; foreign origin gets 403; native gets none", async () => {
  const { handle, calls } = harness();
  const ok = await handle(get("/volumes?q=x", { Origin: ORIGIN }));
  assertEquals(ok.status, 200);
  assertEquals(ok.headers.get("Access-Control-Allow-Origin"), ORIGIN);
  assertEquals(ok.headers.get("Vary"), "Origin");

  const pre = await handle(
    new Request(`${BASE}/volumes`, {
      method: "OPTIONS",
      headers: { Origin: ORIGIN },
    }),
  );
  assertEquals(pre.status, 204);

  const evil = await handle(
    get("/volumes?q=x", { Origin: "https://evil.example" }),
  );
  assertEquals(evil.status, 403);
  assertEquals(evil.headers.get("Access-Control-Allow-Origin"), null);

  const native = await handle(get("/volumes?q=x"));
  assertEquals(native.headers.get("Access-Control-Allow-Origin"), null);
  assertEquals(calls.length, 2);
});

Deno.test("ALLOWED_ORIGINS extends the allow-list", async () => {
  const { handle } = harness({
    env: { ALLOWED_ORIGINS: "https://rubricator.app" },
  });
  assertEquals(
    (await handle(get("/volumes?q=x", { Origin: "https://rubricator.app" })))
      .status,
    200,
  );
});

// --- upstream ---------------------------------------------------------------

Deno.test("upstream status/body/content-type pass through with caching headers", async () => {
  const { handle } = harness({ status: 429 });
  const res = await handle(get("/volumes?q=x"));
  assertEquals(res.status, 429);
  assertEquals(await res.json(), { items: [] });
  assertEquals(
    res.headers.get("Content-Type"),
    "application/json; charset=UTF-8",
  );
  assert(res.headers.get("Cache-Control")?.includes("s-maxage=300"));
});

Deno.test("upstream failures never leak the API key", async () => {
  const boom = new TypeError(
    `error sending request for url (https://www.googleapis.com/books/v1/volumes?q=x&key=${KEY})`,
  );
  const { handle, logs } = harness({ fail: boom });
  const res = await handle(get("/volumes?q=x"));
  const text = await res.text();
  assertEquals(res.status, 502);
  assert(!text.includes(KEY), "key leaked in the response");
  assertEquals(logs, ["upstream_failed"]);
});

Deno.test("upstream timeout -> 504", async () => {
  const { handle } = harness({
    fail: new DOMException("timed out", "TimeoutError"),
  });
  assertEquals((await handle(get("/volumes?q=x"))).status, 504);
});
