import { assert, assertEquals } from "jsr:@std/assert@1";

import { isServiceRequest, timingSafeEqual } from "./service_auth.ts";

const env = (vars: Record<string, string>) => ({ get: (k: string) => vars[k] });
const req = (auth?: string) =>
  new Request("https://x.supabase.co/functions/v1/f", {
    method: "POST",
    headers: auth ? { Authorization: auth } : {},
  });

Deno.test("service role key is accepted", () => {
  assert(
    isServiceRequest(
      req("Bearer srv-key"),
      env({ SUPABASE_SERVICE_ROLE_KEY: "srv-key" }),
    ),
  );
});

Deno.test("CRON_SECRET is accepted as an alternative", () => {
  const e = env({
    SUPABASE_SERVICE_ROLE_KEY: "srv-key",
    CRON_SECRET: "cron-key",
  });
  assert(isServiceRequest(req("Bearer cron-key"), e));
  assert(isServiceRequest(req("bearer srv-key"), e));
});

Deno.test("missing, malformed, wrong or prefix/extended tokens are rejected", () => {
  const e = env({ SUPABASE_SERVICE_ROLE_KEY: "srv-key" });
  for (
    const bad of [
      undefined,
      "",
      "Bearer",
      "srv-key",
      "Basic srv-key",
      "Bearer wrong",
      "Bearer srv-ke",
      "Bearer srv-key2",
      "Bearer srv-key extra",
    ]
  ) {
    assertEquals(isServiceRequest(req(bad), e), false, String(bad));
  }
});

Deno.test("anon / publishable keys are not service credentials", () => {
  const e = env({ SUPABASE_SERVICE_ROLE_KEY: "srv-key" });
  assertEquals(isServiceRequest(req("Bearer sb_publishable_abc"), e), false);
  assertEquals(isServiceRequest(req("Bearer a.b.c"), e), false);
});

Deno.test("no secret configured -> nothing is accepted (fails closed)", () => {
  assertEquals(isServiceRequest(req("Bearer anything"), env({})), false);
  assertEquals(
    isServiceRequest(req("Bearer "), env({ SUPABASE_SERVICE_ROLE_KEY: "  " })),
    false,
  );
});

Deno.test("timingSafeEqual", () => {
  assert(timingSafeEqual("abc", "abc"));
  assert(!timingSafeEqual("abc", "abd"));
  assert(!timingSafeEqual("abc", "abcd"));
  assert(!timingSafeEqual("", "a"));
  assert(timingSafeEqual("", ""));
});
