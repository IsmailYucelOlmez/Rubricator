import { assertEquals } from "jsr:@std/assert@1";

import { type ContactMessage, createHandler, validate } from "./handler.ts";

const ORIGIN = "https://rubricator.site";
const env = { get: (_: string) => undefined };

function setup(allow = true) {
  const sent: ContactMessage[] = [];
  const handler = createHandler({
    env,
    allow: () => Promise.resolve(allow),
    send: (m) => {
      sent.push(m);
      return Promise.resolve();
    },
  });
  return { handler, sent };
}

function post(body: unknown, origin: string | null = ORIGIN) {
  const headers: Record<string, string> = {
    "content-type": "application/json",
  };
  if (origin) headers.origin = origin;
  return new Request("https://x.supabase.co/functions/v1/contact", {
    method: "POST",
    headers,
    body: typeof body === "string" ? body : JSON.stringify(body),
  });
}

const valid = {
  name: "Okur",
  email: "okur@example.com",
  message: "Merhaba, uygulama hakkında bir sorum var.",
  lang: "tr",
};

Deno.test("a valid message is sent to support with the sender as data only", async () => {
  const { handler, sent } = setup();
  const res = await handler(post(valid));
  assertEquals(res.status, 200);
  assertEquals(res.headers.get("access-control-allow-origin"), ORIGIN);
  assertEquals(sent, [{ ...valid, lang: "tr" }]);
});

Deno.test("requests without an allowed Origin are rejected", async () => {
  const { handler, sent } = setup();
  assertEquals((await handler(post(valid, null))).status, 403);
  assertEquals(
    (await handler(post(valid, "https://evil.example"))).status,
    403,
  );
  assertEquals(sent.length, 0);
});

Deno.test("preflight is answered for allowed origins", async () => {
  const { handler } = setup();
  const res = await handler(
    new Request("https://x/functions/v1/contact", {
      method: "OPTIONS",
      headers: { origin: ORIGIN },
    }),
  );
  assertEquals(res.status, 204);
});

Deno.test("invalid fields come back as stable codes", async () => {
  const { handler, sent } = setup();
  const res = await handler(post({ email: "nope", message: "short" }));
  assertEquals(res.status, 400);
  assertEquals((await res.json()).fields, {
    email: "invalid",
    message: "too_short",
  });
  assertEquals(sent.length, 0);
});

Deno.test("the honeypot looks successful but sends nothing", async () => {
  const { handler, sent } = setup();
  const res = await handler(post({ ...valid, website: "http://spam" }));
  assertEquals(res.status, 200);
  assertEquals(sent.length, 0);
});

Deno.test("over the per-IP limit → 429, nothing sent", async () => {
  const { handler, sent } = setup(false);
  assertEquals((await handler(post(valid))).status, 429);
  assertEquals(sent.length, 0);
});

Deno.test("oversized and non-JSON bodies are refused", async () => {
  const { handler } = setup();
  assertEquals((await handler(post("{not json"))).status, 400);
  const big = { ...valid, message: "x".repeat(13_000) };
  assertEquals((await handler(post(big))).status, 413);
});

Deno.test("a failing mail provider is a 502", async () => {
  const handler = createHandler({
    env,
    allow: () => Promise.resolve(true),
    send: () => Promise.reject(new Error("down")),
  });
  assertEquals((await handler(post(valid))).status, 502);
});

Deno.test("validate trims, defaults lang and caps lengths", () => {
  const r = validate({ ...valid, name: "  A  ", lang: "de" });
  assertEquals(r.ok && r.value.name, "A");
  assertEquals(r.ok && r.value.lang, "en");
  const long = validate({ ...valid, name: "x".repeat(101) });
  assertEquals(!long.ok && long.fields.name, "too_long");
});

function appSetup(user: { id: string; email: string | null } | null) {
  const sent: ContactMessage[] = [];
  const keys: string[] = [];
  const handler = createHandler({
    env,
    getUser: (token) => Promise.resolve(token === "a.b.c" ? user : null),
    allow: (key) => {
      keys.push(key);
      return Promise.resolve(true);
    },
    send: (m) => {
      sent.push(m);
      return Promise.resolve();
    },
  });
  return { handler, sent, keys };
}

function appPost(body: unknown, token: string | null = "a.b.c") {
  const headers: Record<string, string> = {
    "content-type": "application/json",
  };
  if (token) headers.authorization = `Bearer ${token}`;
  return new Request("https://x.supabase.co/functions/v1/contact", {
    method: "POST",
    headers,
    body: JSON.stringify(body),
  });
}

Deno.test("the app (no Origin) sends as the signed-in user's account email", async () => {
  const { handler, sent } = appSetup({ id: "u1", email: "me@example.com" });
  const res = await handler(
    appPost({ ...valid, email: "someone-else@example.com" }),
  );
  assertEquals(res.status, 200);
  assertEquals(sent, [{
    ...valid,
    lang: "tr",
    email: "me@example.com",
    userId: "u1",
  }]);
});

Deno.test("app requests are rate-limited per user, not per IP", async () => {
  const a = appSetup({ id: "u1", email: "me@example.com" });
  const b = appSetup({ id: "u2", email: "you@example.com" });
  await a.handler(appPost(valid));
  await b.handler(appPost(valid));
  assertEquals(a.keys.length, 1);
  assertEquals(a.keys[0] === b.keys[0], false);
});

Deno.test("no Origin and no valid session is refused", async () => {
  const { handler, sent } = appSetup(null);
  assertEquals((await handler(appPost(valid))).status, 401);
  assertEquals((await handler(appPost(valid, null))).status, 403);
  assertEquals(sent.length, 0);
});
