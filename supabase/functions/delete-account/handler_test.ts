import { assertEquals } from "jsr:@std/assert@1";

import { type CallerUser, createHandler } from "./handler.ts";

const env = { get: (_: string) => undefined };
const JWT = "aaa.bbb.ccc";
const ALICE: CallerUser = { id: "alice-id", email: "alice@example.com" };

function setup(opts: {
  caller?: CallerUser | null;
  otpOwner?: string | null;
  failDelete?: boolean;
} = {}) {
  const deleted: string[] = [];
  const verified: Array<[string, string]> = [];
  const handler = createHandler({
    env,
    getUser: (token) =>
      Promise.resolve(token === JWT ? (opts.caller ?? ALICE) : null),
    verifyOtp: (email, code) => {
      verified.push([email, code]);
      return Promise.resolve(
        opts.otpOwner === undefined ? ALICE.id : opts.otpOwner,
      );
    },
    deleteAccount: (id) => {
      if (opts.failDelete) return Promise.reject(new Error("boom"));
      deleted.push(id);
      return Promise.resolve();
    },
  });
  return { handler, deleted, verified };
}

function post(
  body: unknown,
  { token = JWT, origin }: { token?: string | null; origin?: string } = {},
) {
  const headers: Record<string, string> = {
    "content-type": "application/json",
  };
  if (token) headers.authorization = `Bearer ${token}`;
  if (origin) headers.origin = origin;
  return new Request("https://x.supabase.co/functions/v1/delete-account", {
    method: "POST",
    headers,
    body: typeof body === "string" ? body : JSON.stringify(body),
  });
}

Deno.test("a valid code deletes the caller's own account", async () => {
  const { handler, deleted, verified } = setup();
  const res = await handler(post({ code: "12345678" }));
  assertEquals(res.status, 200);
  assertEquals(deleted, [ALICE.id]);
  assertEquals(verified, [[ALICE.email!, "12345678"]]);
});

Deno.test("no or invalid session is rejected before any OTP check", async () => {
  const { handler, deleted, verified } = setup();
  assertEquals(
    (await handler(post({ code: "12345678" }, { token: null }))).status,
    401,
  );
  assertEquals(
    (await handler(post({ code: "12345678" }, { token: "x.y.z" }))).status,
    401,
  );
  assertEquals(deleted, []);
  assertEquals(verified, []);
});

Deno.test("a wrong or malformed code deletes nothing", async () => {
  const { handler, deleted } = setup({ otpOwner: null });
  const wrong = await handler(post({ code: "12345678" }));
  assertEquals(wrong.status, 400);
  assertEquals(await wrong.json(), { error: "invalid_code" });
  assertEquals((await handler(post({ code: "12ab" }))).status, 400);
  assertEquals((await handler(post({}))).status, 400);
  assertEquals((await handler(post("not json"))).status, 400);
  assertEquals(deleted, []);
});

Deno.test("a code that belongs to another user deletes nothing", async () => {
  const { handler, deleted } = setup({ otpOwner: "mallory-id" });
  assertEquals((await handler(post({ code: "12345678" }))).status, 400);
  assertEquals(deleted, []);
});

Deno.test("browsers must come from an allowed origin; apps send none", async () => {
  const { handler, deleted } = setup();
  const evil = await handler(
    post({ code: "12345678" }, { origin: "https://evil.example" }),
  );
  assertEquals(evil.status, 403);
  const site = await handler(
    post({ code: "12345678" }, { origin: "https://rubricator.site" }),
  );
  assertEquals(site.status, 200);
  assertEquals(
    site.headers.get("access-control-allow-origin"),
    "https://rubricator.site",
  );
  assertEquals(deleted, [ALICE.id]);
});

Deno.test("only POST is accepted", async () => {
  const { handler } = setup();
  const res = await handler(
    new Request("https://x/functions/v1/delete-account", { method: "GET" }),
  );
  assertEquals(res.status, 405);
});

Deno.test("a failed deletion is reported as a server error", async () => {
  const { handler } = setup({ failDelete: true });
  const res = await handler(post({ code: "12345678" }));
  assertEquals(res.status, 500);
  assertEquals(await res.json(), { error: "delete_failed" });
});
