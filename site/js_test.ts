import { assert, assertEquals, assertRejects } from "jsr:@std/assert@1";

import {
  AuthError,
  createAuth,
  isValidEmail,
  SESSION_KEY,
  validatePassword,
} from "./static/js/auth.js";
import {
  createVirgil,
  httpsUrl,
  normalizeResults,
  VirgilError,
} from "./static/js/virgil.js";

const URL_ = "https://proj.supabase.co";
const KEY = "sb_publishable_test";

interface Call {
  url: string;
  method: string;
  headers: Record<string, string>;
  body: unknown;
}

/** Scripted fetch: each response is consumed in order; every call is recorded. */
function fakeFetch(
  responses: Array<Response | Error | ((call: Call) => Response)>,
) {
  const calls: Call[] = [];
  const fn = (input: string, init: RequestInit = {}) => {
    const call: Call = {
      url: String(input),
      method: init.method ?? "GET",
      headers: { ...(init.headers as Record<string, string>) },
      body: init.body ? JSON.parse(String(init.body)) : undefined,
    };
    calls.push(call);
    const next = responses.shift();
    if (!next) throw new Error(`unexpected fetch ${call.method} ${call.url}`);
    if (next instanceof Error) return Promise.reject(next);
    return Promise.resolve(typeof next === "function" ? next(call) : next);
  };
  return { fn: fn as unknown as typeof fetch, calls };
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

class MemoryStorage {
  data = new Map<string, string>();
  getItem(k: string) {
    return this.data.get(k) ?? null;
  }
  setItem(k: string, v: string) {
    this.data.set(k, v);
  }
  removeItem(k: string) {
    this.data.delete(k);
  }
}

const NOW = 1_800_000_000_000; // ms
const sessionBody = (n = 1, expiresIn = 3600) => ({
  access_token: `access-${n}`,
  refresh_token: `refresh-${n}`,
  expires_in: expiresIn,
  user: { id: "u1", email: "a@b.co", user_metadata: { username: "Ada" } },
});

function setup(
  responses: Parameters<typeof fakeFetch>[0],
  storage: MemoryStorage = new MemoryStorage(),
) {
  const f = fakeFetch(responses);
  const auth = createAuth({
    url: URL_ + "/",
    anonKey: KEY,
    storage,
    fetchFn: f.fn,
    now: () => NOW,
  });
  return { auth, storage, ...f };
}

// --- auth -------------------------------------------------------------------

Deno.test("signIn: posts credentials with the apikey only and stores the session", async () => {
  const { auth, calls, storage } = setup([json(sessionBody())]);
  const session = await auth.signIn("  a@b.co ", "Secret!1");
  assertEquals(calls[0].url, `${URL_}/auth/v1/token?grant_type=password`);
  assertEquals(calls[0].body, { email: "a@b.co", password: "Secret!1" });
  assertEquals(calls[0].headers.apikey, KEY);
  assert(
    !("Authorization" in calls[0].headers),
    "the publishable key must not be sent as a Bearer token",
  );
  assertEquals(session.user, { id: "u1", email: "a@b.co", username: "Ada" });
  assertEquals(session.expiresAt, NOW / 1000 + 3600);
  assert(storage.getItem(SESSION_KEY)?.includes("access-1"));
});

Deno.test("signIn: maps GoTrue errors, old and new format", async () => {
  const bad = setup([
    json({
      code: 400,
      error_code: "invalid_credentials",
      msg: "Invalid login credentials",
    }, 400),
  ]);
  const error = await assertRejects(
    () => bad.auth.signIn("a@b.co", "x"),
    AuthError,
  );
  assertEquals(error.code, "invalid_credentials");
  assertEquals(bad.auth.getSession(), null);

  const legacy = setup([
    json({ error: "invalid_grant", error_description: "nope" }, 400),
  ]);
  assertEquals(
    (await assertRejects(() => legacy.auth.signIn("a@b.co", "x"), AuthError))
      .code,
    "invalid_grant",
  );

  const limited = setup([new Response("slow down", { status: 429 })]);
  assertEquals(
    (await assertRejects(() => limited.auth.signIn("a@b.co", "x"), AuthError))
      .code,
    "over_request_rate_limit",
  );

  const offline = setup([new TypeError("failed to fetch")]);
  assertEquals(
    (await assertRejects(() => offline.auth.signIn("a@b.co", "x"), AuthError))
      .code,
    "network",
  );
});

Deno.test("getAccessToken: valid token is returned without a request", async () => {
  const { auth, calls } = setup([json(sessionBody())]);
  await auth.signIn("a@b.co", "x");
  assertEquals(await auth.getAccessToken(), "access-1");
  assertEquals(calls.length, 1);
});

Deno.test("getAccessToken: signed out gives null", async () => {
  const { auth, calls } = setup([]);
  assertEquals(await auth.getAccessToken(), null);
  assertEquals(calls.length, 0);
});

Deno.test("getAccessToken: refreshes a token about to expire, once for concurrent callers", async () => {
  const { auth, calls } = setup([
    json(sessionBody(1, 30)),
    json(sessionBody(2)),
  ]);
  await auth.signIn("a@b.co", "x"); // expires in 30 s: inside the 60 s margin
  const [a, b] = await Promise.all([
    auth.getAccessToken(),
    auth.getAccessToken(),
  ]);
  assertEquals([a, b], ["access-2", "access-2"]);
  assertEquals(calls.length, 2);
  assertEquals(calls[1].url, `${URL_}/auth/v1/token?grant_type=refresh_token`);
  assertEquals(calls[1].body, { refresh_token: "refresh-1" });
});

Deno.test("getAccessToken: force refreshes even a fresh token", async () => {
  const { auth } = setup([json(sessionBody(1)), json(sessionBody(2))]);
  await auth.signIn("a@b.co", "x");
  assertEquals(await auth.getAccessToken(true), "access-2");
});

Deno.test("refresh: a rejected refresh token ends the session; a network error keeps it", async () => {
  const revoked = setup([
    json(sessionBody(1, 10)),
    json({ error_code: "refresh_token_not_found" }, 400),
  ]);
  await revoked.auth.signIn("a@b.co", "x");
  const seen: unknown[] = [];
  revoked.auth.onChange((s: unknown) => seen.push(s));
  assertEquals(await revoked.auth.getAccessToken(), null);
  assertEquals(revoked.auth.getSession(), null);
  assertEquals(seen, [null]);

  const offline = setup([json(sessionBody(1, 10)), new TypeError("offline")]);
  await offline.auth.signIn("a@b.co", "x");
  await assertRejects(
    () => offline.auth.getAccessToken(),
    AuthError,
    "Network",
  );
  assertEquals(offline.auth.getSession()?.refreshToken, "refresh-1");

  const busy = setup([json(sessionBody(1, 10)), json({}, 429)]);
  await busy.auth.signIn("a@b.co", "x");
  await assertRejects(() => busy.auth.getAccessToken(), AuthError);
  assert(busy.auth.getSession(), "a rate limit must not sign the user out");
});

Deno.test("refresh: uses a session another tab already rotated instead of spending the old token", async () => {
  const { auth, calls, storage } = setup([json(sessionBody(1, 10))]);
  await auth.signIn("a@b.co", "x");
  // Another tab refreshed in the meantime and stored a fresh session.
  storage.setItem(
    SESSION_KEY,
    JSON.stringify({
      accessToken: "access-9",
      refreshToken: "refresh-9",
      expiresAt: NOW / 1000 + 3000,
      user: { id: "u1", email: "a@b.co", username: "Ada" },
    }),
  );
  // getAccessToken reads storage first, so it already sees the fresh session.
  assertEquals(await auth.getAccessToken(), "access-9");
  assertEquals(calls.length, 1);
});

Deno.test("storage that throws falls back to memory", async () => {
  const broken = {
    getItem() {
      throw new Error("blocked");
    },
    setItem() {
      throw new Error("blocked");
    },
    removeItem() {
      throw new Error("blocked");
    },
  };
  const { auth } = setup(
    [json(sessionBody())],
    broken as unknown as MemoryStorage,
  );
  await auth.signIn("a@b.co", "x");
  assertEquals(auth.getSession()?.accessToken, "access-1");
  await auth.signOut();
  assertEquals(auth.getSession(), null);
});

Deno.test("signUp: sends metadata and reports whether confirmation is pending", async () => {
  const pending = setup([
    json({ id: "new", email: "a@b.co", identities: [{}] }),
  ]);
  const result = await pending.auth.signUp({
    email: " a@b.co ",
    password: "Abcdef!",
    username: " Ada ",
    policyVersion: "2026-09-27",
  });
  assertEquals(result, { session: null });
  assertEquals(pending.calls[0].url, `${URL_}/auth/v1/signup`);
  assertEquals(pending.calls[0].body, {
    email: "a@b.co",
    password: "Abcdef!",
    data: {
      username: "Ada",
      privacy_policy_accepted_at: new Date(NOW).toISOString(),
      privacy_policy_version: "2026-09-27",
    },
  });
  assertEquals(pending.auth.getSession(), null);

  const auto = setup([json(sessionBody())]);
  const signedIn = await auto.auth.signUp({
    email: "a@b.co",
    password: "Abcdef!",
    username: "Ada",
    policyVersion: "v",
  });
  assertEquals(signedIn.session?.accessToken, "access-1");
});

Deno.test("password recovery: emails a code, verifies it, sets the password, signs in", async () => {
  const { auth, calls } = setup([
    json({}),
    json(sessionBody(3)),
    json({ id: "u1" }),
  ]);
  await auth.sendRecoveryCode(" a@b.co ");
  assertEquals(calls[0].url, `${URL_}/auth/v1/recover`);
  assertEquals(calls[0].body, { email: "a@b.co" });

  const session = await auth.resetPassword({
    email: "a@b.co",
    code: " 12345678 ",
    newPassword: "NewPass!1",
  });
  assertEquals(calls[1].url, `${URL_}/auth/v1/verify`);
  assertEquals(calls[1].body, {
    type: "recovery",
    email: "a@b.co",
    token: "12345678",
  });
  assertEquals(calls[2].method, "PUT");
  assertEquals(calls[2].url, `${URL_}/auth/v1/user`);
  assertEquals(calls[2].headers.Authorization, "Bearer access-3");
  assertEquals(calls[2].body, { password: "NewPass!1" });
  assertEquals(session.accessToken, "access-3");
  assertEquals(auth.getSession()?.accessToken, "access-3");
});

Deno.test("password recovery: a bad code fails without signing in", async () => {
  const { auth } = setup([
    json({ error_code: "otp_expired", msg: "expired" }, 403),
  ]);
  const error = await assertRejects(
    () => auth.resetPassword({ email: "a@b.co", code: "1", newPassword: "x" }),
    AuthError,
  );
  assertEquals(error.code, "otp_expired");
  assertEquals(auth.getSession(), null);
});

Deno.test("signOut: clears the session even if the server call fails", async () => {
  const { auth, calls } = setup([
    json(sessionBody()),
    new TypeError("offline"),
  ]);
  await auth.signIn("a@b.co", "x");
  await auth.signOut();
  assertEquals(auth.getSession(), null);
  assertEquals(calls[1].url, `${URL_}/auth/v1/logout?scope=local`);
  assertEquals(calls[1].headers.Authorization, "Bearer access-1");
});

Deno.test("validatePassword mirrors the mobile app's rules", () => {
  assertEquals(validatePassword(""), "empty");
  assertEquals(validatePassword("Ab!"), "tooShort");
  assertEquals(validatePassword("abcdef!"), "missingUppercase");
  assertEquals(validatePassword("ABCDEF!"), "missingLowercase");
  assertEquals(validatePassword("Abcdefg"), "missingPunctuation");
  assertEquals(validatePassword("Abcdef!"), null);
  // Like the app, only A-Z count as uppercase (Turkish "Ş" alone does not).
  assertEquals(validatePassword("Şifre123."), "missingUppercase");
  assertEquals(validatePassword("ŞiFre123."), null);
});

Deno.test("isValidEmail is as lenient as the app", () => {
  assert(isValidEmail("a@b"));
  assert(!isValidEmail("ab"));
  assert(!isValidEmail("  "));
});

// --- virgil -----------------------------------------------------------------

function virgilSetup(
  responses: Parameters<typeof fakeFetch>[0],
  tokens: Array<string | null> = ["tok"],
) {
  const f = fakeFetch(responses);
  const asked: boolean[] = [];
  const virgil = createVirgil({
    url: URL_,
    anonKey: KEY,
    fetchFn: f.fn,
    getToken: (force?: boolean) => {
      asked.push(Boolean(force));
      return Promise.resolve(tokens.length > 1 ? tokens.shift()! : tokens[0]);
    },
  });
  return { virgil, asked, ...f };
}

Deno.test("search: same request as the mobile app, with the user's token", async () => {
  const { virgil, calls } = virgilSetup([json({ results: [] })]);
  await virgil.search({
    query: "  cozy mystery ",
    category: "Fiction",
    language: "en",
  });
  assertEquals(
    calls[0].url,
    `${URL_}/functions/v1/rubricatorApi/api/v1/semantic/search`,
  );
  assertEquals(calls[0].method, "POST");
  assertEquals(calls[0].headers.apikey, KEY);
  assertEquals(calls[0].headers.Authorization, "Bearer tok");
  assertEquals(calls[0].body, {
    query: "cozy mystery",
    mode: "advanced",
    category: "Fiction",
    tone: "All",
    limit: 16,
    language: "en",
  });
});

Deno.test("search: results are normalised (https covers, no ISBN-less rows, clipped text)", async () => {
  const long = "word ".repeat(200);
  const { virgil } = virgilSetup([json({
    results: [
      {
        isbn13: "1",
        title: " A ",
        author: "B",
        description: long,
        coverImageUrl: "http://x.test/c.jpg",
        category: "Fiction",
      },
      { isbn13: "", title: "no isbn" },
      { isbn13: "2", title: "T", coverImageUrl: "javascript:alert(1)" },
      null,
    ],
  })]);
  const books = await virgil.search({ query: "abc" });
  assertEquals(books.map((b: { isbn13: string }) => b.isbn13), ["1", "2"]);
  assertEquals(books[0].cover, "https://x.test/c.jpg");
  assertEquals(books[0].title, "A");
  assert(
    books[0].description.length <= 421 && books[0].description.endsWith("…"),
  );
  assertEquals(books[1].cover, null);
});

Deno.test("httpsUrl only ever returns https URLs", () => {
  assertEquals(httpsUrl("http://a.test/x.jpg"), "https://a.test/x.jpg");
  assertEquals(httpsUrl("HTTP://a.test/x.jpg"), "https://a.test/x.jpg");
  assertEquals(httpsUrl("https://a.test/x.jpg"), "https://a.test/x.jpg");
  assertEquals(httpsUrl("data:image/png;base64,AAAA"), null);
  assertEquals(httpsUrl("javascript:alert(1)"), null);
  assertEquals(httpsUrl("//a.test/x.jpg"), null);
  assertEquals(httpsUrl(""), null);
  assertEquals(httpsUrl(undefined), null);
  assertEquals(normalizeResults(undefined), []);
});

Deno.test("search: a 401 refreshes the token once and retries", async () => {
  const { virgil, asked, calls } = virgilSetup([
    json({ error: "unauthorized" }, 401),
    json({ results: [] }),
  ], ["old", "new"]);
  await virgil.search({ query: "abc" });
  assertEquals(asked, [false, true]);
  assertEquals(calls.map((c) => c.headers.Authorization), [
    "Bearer old",
    "Bearer new",
  ]);

  const twice = virgilSetup([json({}, 401), json({}, 401)], ["old", "new"]);
  const error = await assertRejects(
    () => twice.virgil.search({ query: "abc" }),
    VirgilError,
  );
  assertEquals(error.code, "unauthorized");
  assertEquals(twice.calls.length, 2);
});

Deno.test("search: signed out never reaches the network", async () => {
  const { virgil, calls } = virgilSetup([], [null]);
  const error = await assertRejects(
    () => virgil.search({ query: "abc" }),
    VirgilError,
  );
  assertEquals(error.code, "unauthorized");
  assertEquals(calls.length, 0);
});

Deno.test("search: error responses map to stable codes", async () => {
  const cases: Array<[Response | Error, string]> = [
    [
      json({ error: "daily_limit_reached", action: "recommendation" }, 429),
      "daily_limit_reached",
    ],
    [json({ error: "something" }, 429), "rate_limited"],
    [json({ error: "invalid_query" }, 400), "invalid_query"],
    [json({ error: "upstream_not_configured" }, 500), "server"],
    [new Response("<html>bad gateway</html>", { status: 502 }), "server"],
    [json({ error: "origin_not_allowed" }, 403), "server"],
    [new TypeError("offline"), "network"],
  ];
  for (const [response, code] of cases) {
    const { virgil } = virgilSetup([response]);
    const error = await assertRejects(
      () => virgil.search({ query: "abc" }),
      VirgilError,
    );
    assertEquals(error.code, code);
  }
});

Deno.test("usage: reads the quota row, and is null when it can't", async () => {
  const ok = virgilSetup([
    json([{
      recommendations_count: 2,
      uploads_count: 0,
      recommendations_limit: 5,
      uploads_limit: 3,
    }]),
  ]);
  assertEquals(await ok.virgil.usage(), { used: 2, limit: 5 });
  assertEquals(ok.calls[0].url, `${URL_}/rest/v1/rpc/get_virgil_usage_today`);

  assertEquals(
    await virgilSetup([json({ message: "boom" }, 500)]).virgil.usage(),
    null,
  );
  assertEquals(await virgilSetup([json([])]).virgil.usage(), null);
  assertEquals(
    await virgilSetup([new TypeError("offline")]).virgil.usage(),
    null,
  );
});

// --- redirect_to (email confirmation landing) -------------------------------

Deno.test("signUp/sendRecoveryCode attach redirect_to when configured, omit it otherwise", async () => {
  const redirectTo = "https://rubricator.site/auth/confirmed/";
  const f = fakeFetch([
    json({ id: "new", email: "a@b.co", identities: [{}] }),
    json({}),
  ]);
  const auth = createAuth({
    url: URL_,
    anonKey: KEY,
    fetchFn: f.fn,
    now: () => NOW,
    redirectTo,
  });
  await auth.signUp({
    email: "a@b.co",
    password: "Abcdef!",
    username: "Ada",
    policyVersion: "v",
  });
  await auth.sendRecoveryCode("a@b.co");
  assertEquals(
    f.calls[0].url,
    `${URL_}/auth/v1/signup?redirect_to=${encodeURIComponent(redirectTo)}`,
  );
  assertEquals(
    f.calls[1].url,
    `${URL_}/auth/v1/recover?redirect_to=${encodeURIComponent(redirectTo)}`,
  );

  const bare = fakeFetch([
    json({ id: "new", email: "a@b.co", identities: [{}] }),
  ]);
  const noRedirect = createAuth({
    url: URL_,
    anonKey: KEY,
    fetchFn: bare.fn,
    now: () => NOW,
  });
  await noRedirect.signUp({
    email: "a@b.co",
    password: "Abcdef!",
    username: "Ada",
    policyVersion: "v",
  });
  assertEquals(bare.calls[0].url, `${URL_}/auth/v1/signup`);
});

// --- consumeRedirectFragment (the "you're confirmed" page) ------------------

Deno.test("consumeRedirectFragment: valid tokens fetch the user and store the session", async () => {
  const f = fakeFetch([
    json({ id: "u9", email: "new@b.co", user_metadata: { username: "New" } }),
  ]);
  const auth = createAuth({
    url: URL_,
    anonKey: KEY,
    fetchFn: f.fn,
    now: () => NOW,
  });
  const session = await auth.consumeRedirectFragment(
    "#access_token=tok-1&refresh_token=ref-1&expires_in=3600&type=signup",
  );
  assertEquals(session?.accessToken, "tok-1");
  assertEquals(session?.refreshToken, "ref-1");
  assertEquals(session?.user, { id: "u9", email: "new@b.co", username: "New" });
  assertEquals(auth.getSession()?.accessToken, "tok-1");
  assertEquals(f.calls[0].url, `${URL_}/auth/v1/user`);
  assertEquals(f.calls[0].method, "GET");
  assertEquals(f.calls[0].headers.Authorization, "Bearer tok-1");
});

Deno.test("consumeRedirectFragment: uses expires_at from the fragment when GoTrue sends one", async () => {
  const f = fakeFetch([json({ id: "u9", email: "a@b.co" })]);
  const auth = createAuth({
    url: URL_,
    anonKey: KEY,
    fetchFn: f.fn,
    now: () => NOW,
  });
  const expiresAt = NOW / 1000 + 999;
  const session = await auth.consumeRedirectFragment(
    `#access_token=tok&refresh_token=ref&expires_at=${expiresAt}`,
  );
  assertEquals(session?.expiresAt, expiresAt);
});

Deno.test("consumeRedirectFragment: no tokens (a direct visit) resolves to null without a request", async () => {
  const f = fakeFetch([]);
  const auth = createAuth({ url: URL_, anonKey: KEY, fetchFn: f.fn });
  assertEquals(await auth.consumeRedirectFragment(""), null);
  assertEquals(await auth.consumeRedirectFragment("#type=signup"), null);
  assertEquals(f.calls.length, 0);
});

Deno.test("consumeRedirectFragment: an #error=… fragment (expired/invalid link) resolves to null without a request", async () => {
  const f = fakeFetch([]);
  const auth = createAuth({ url: URL_, anonKey: KEY, fetchFn: f.fn });
  const session = await auth.consumeRedirectFragment(
    "#error=access_denied&error_description=Email+link+is+invalid",
  );
  assertEquals(session, null);
  assertEquals(f.calls.length, 0);
});

Deno.test("consumeRedirectFragment: the user fetch failing resolves to null, not a thrown error", async () => {
  const f = fakeFetch([new TypeError("offline")]);
  const auth = createAuth({ url: URL_, anonKey: KEY, fetchFn: f.fn });
  const session = await auth.consumeRedirectFragment(
    "#access_token=tok-1&refresh_token=ref-1",
  );
  assertEquals(session, null);
  assertEquals(auth.getSession(), null);
});

Deno.test("consumeRedirectFragment: the default (no explicit hash) never throws outside a browser", async () => {
  const auth = createAuth({
    url: URL_,
    anonKey: KEY,
    fetchFn: fakeFetch([]).fn,
  });
  assertEquals(await auth.consumeRedirectFragment(), null);
});
