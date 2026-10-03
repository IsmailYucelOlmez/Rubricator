/**
 * Local stand-in for Supabase Auth + the rubricatorApi edge function, so the
 * Virgil page can be exercised without touching production:
 *
 *   deno run --allow-net site/tools/mock_backend.ts        # http://localhost:8767
 *   SUPABASE_URL=http://localhost:8767 SUPABASE_ANON_KEY=sb_publishable_mock \
 *     deno run --allow-read --allow-write --allow-env site/build.ts
 *
 * Sign in with reader@example.com / Secret!1. Recovery code: 12345678. The
 * fifth search of the day is answered with 429 daily_limit_reached.
 */
const PORT = Number(Deno.env.get("PORT") ?? 8767);
const USER = {
  id: "00000000-0000-4000-8000-000000000001",
  email: "reader@example.com",
  user_metadata: { username: "Reader" },
};
const searches = { used: 0 };
let tokenSeq = 0;
const issued = new Map<string, string>(); // access token -> refresh token

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });

function session(expiresIn = 3600) {
  const n = ++tokenSeq;
  const access = `aaa${n}.bbb${n}.ccc${n}`;
  issued.set(access, `refresh-${n}`);
  return {
    access_token: access,
    refresh_token: `refresh-${n}`,
    expires_in: expiresIn,
    expires_at: Math.floor(Date.now() / 1000) + expiresIn,
    token_type: "bearer",
    user: USER,
  };
}

const books = [
  [
    "9780156012195",
    "The Little Prince",
    "Antoine de Saint-Exupéry",
    "Fiction",
    "http://books.google.com/books/content?id=x&printsec=frontcover&img=1&zoom=1",
    "A pilot stranded in the desert meets a small prince who has travelled from planet to planet. A gentle, funny and sad story about what grown-ups forget.",
  ],
  [
    "9780061120084",
    "To Kill a Mockingbird",
    "Harper Lee",
    "Fiction",
    null,
    "Scout Finch grows up in a sleepy Alabama town while her father defends a Black man accused of a crime. <b>Not bold</b> — this markup must render as text.",
  ],
  [
    "9780140449136",
    "The Odyssey",
    "Homer",
    "Fiction",
    "not a url",
    "Ten years after Troy, Odysseus tries to get home. ".repeat(20),
  ],
];

Deno.serve({ port: PORT }, async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: cors });
  }
  const url = new URL(req.url);
  const path = url.pathname;
  const body = req.method === "GET" ? null : await req.json().catch(() => null);
  const bearer = req.headers.get("Authorization")?.replace(/^Bearer /, "") ??
    "";

  if (
    path === "/auth/v1/token" &&
    url.searchParams.get("grant_type") === "password"
  ) {
    if (body?.email === "reader@example.com" && body?.password === "Secret!1") {
      return json(session(Number(Deno.env.get("EXPIRES_IN") ?? 3600)));
    }
    return json({
      code: 400,
      error_code: "invalid_credentials",
      msg: "Invalid login credentials",
    }, 400);
  }
  if (
    path === "/auth/v1/token" &&
    url.searchParams.get("grant_type") === "refresh_token"
  ) {
    if ([...issued.values()].includes(body?.refresh_token)) {
      return json(session());
    }
    return json({
      code: 400,
      error_code: "refresh_token_not_found",
      msg: "Invalid Refresh Token",
    }, 400);
  }
  // Contact form (supabase/functions/contact): "ratelimit@example.com" → 429,
  // a message containing "fail" → 502, otherwise ok.
  if (path === "/functions/v1/contact") {
    if (body?.email === "ratelimit@example.com") {
      return json({ error: "rate_limited" }, 429);
    }
    if (String(body?.message ?? "").includes("fail")) {
      return json({ error: "send_failed" }, 502);
    }
    if (String(body?.message ?? "").trim().length < 10) {
      return json({ error: "invalid", fields: { message: "too_short" } }, 400);
    }
    return json({ ok: true });
  }
  if (path === "/auth/v1/signup") {
    if (body?.email === "taken@example.com") {
      return json({ ...USER, identities: [] });
    }
    return json({ id: "new", email: body?.email, identities: [{}] });
  }
  if (path === "/auth/v1/recover") return json({});
  if (path === "/auth/v1/verify") {
    return body?.token === "12345678" ? json(session()) : json({
      code: 403,
      error_code: "otp_expired",
      msg: "Token has expired or is invalid",
    }, 403);
  }
  if (
    path === "/auth/v1/user" && (req.method === "PUT" || req.method === "GET")
  ) {
    return issued.has(bearer)
      ? json(USER)
      : json({ error: "unauthorized" }, 401);
  }
  if (path === "/auth/v1/logout") return json({});

  if (!issued.has(bearer)) return json({ error: "unauthorized" }, 401);

  if (path === "/rest/v1/rpc/get_virgil_usage_today") {
    return json([{
      recommendations_count: searches.used,
      uploads_count: 0,
      recommendations_limit: 5,
      uploads_limit: 3,
    }]);
  }
  if (path === "/functions/v1/rubricatorApi/api/v1/semantic/search") {
    if (typeof body?.query !== "string" || body.query.trim().length < 3) {
      return json({ error: "invalid_query" }, 400);
    }
    if (searches.used >= 5) {
      return json(
        { error: "daily_limit_reached", action: "recommendation" },
        429,
      );
    }
    searches.used++;
    await new Promise((r) => setTimeout(r, 600));
    const wantsNone = body.query.includes("nothing");
    return json({
      results: wantsNone ? [] : books.map((
        [isbn13, title, author, category, coverImageUrl, description],
      ) => ({
        isbn13,
        title,
        author,
        category,
        coverImageUrl,
        description,
        similarity: 0.8,
        source: "local",
      })).concat([{
        isbn13: "",
        title: "No ISBN",
        author: "",
        category: "",
        coverImageUrl: null,
        description: "",
        similarity: 0,
        source: "local",
      }]),
    });
  }
  return json({ error: "not_found" }, 404);
});
console.log(`mock backend on http://localhost:${PORT}`);
