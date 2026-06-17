import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const GOOGLE_BOOKS_BASE = "https://www.googleapis.com/books/v1";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "GET") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const apiKey = Deno.env.get("GOOGLE_BOOKS_API_KEY")?.trim();
  if (!apiKey) {
    return jsonResponse({ error: "GOOGLE_BOOKS_API_KEY is not configured" }, 500);
  }

  const incoming = new URL(req.url);
  const prefix = "/google-books";
  const idx = incoming.pathname.indexOf(prefix);
  const suffix = idx >= 0
    ? incoming.pathname.slice(idx + prefix.length)
    : "";
  const googlePath = suffix.length > 0 ? suffix : "/volumes";

  const target = new URL(`${GOOGLE_BOOKS_BASE}${googlePath}`);
  incoming.searchParams.forEach((value, key) => {
    if (key !== "key") {
      target.searchParams.set(key, value);
    }
  });
  target.searchParams.set("key", apiKey);

  try {
    const upstream = await fetch(target.toString(), {
      method: "GET",
      headers: { Accept: "application/json" },
    });
    const text = await upstream.text();
    return new Response(text, {
      status: upstream.status,
      headers: {
        ...corsHeaders,
        "Content-Type": upstream.headers.get("Content-Type") ??
          "application/json",
        "Cache-Control": "public, s-maxage=300, stale-while-revalidate=86400",
      },
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return jsonResponse({ error: `Upstream request failed: ${message}` }, 502);
  }
});
