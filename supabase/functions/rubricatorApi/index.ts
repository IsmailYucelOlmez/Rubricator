import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "GET, POST, PUT, PATCH, DELETE, OPTIONS",
};

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function firstEnv(...keys: string[]): string | undefined {
  for (const key of keys) {
    const value = Deno.env.get(key)?.trim();
    if (value) return value;
  }
  return undefined;
}

/**
 * Resolve the FastAPI path from the incoming edge URL.
 * Supports deployed name `rubricatorApi` and legacy `semantic-api`.
 */
function upstreamPath(pathname: string): string {
  for (const prefix of [
    "/functions/v1/rubricatorApi",
    "/functions/v1/semantic-api",
    "/rubricatorApi",
    "/semantic-api",
  ]) {
    const idx = pathname.indexOf(prefix);
    if (idx >= 0) {
      const suffix = pathname.slice(idx + prefix.length);
      return suffix.length > 0 ? suffix : "/";
    }
  }

  // Fallback: forward from `/api/...` if present.
  const apiIdx = pathname.indexOf("/api/");
  if (apiIdx >= 0) {
    return pathname.slice(apiIdx);
  }

  return pathname || "/";
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const baseUrl = firstEnv(
    "SEMANTIC_API_BASE_URL",
    "RUBRICATOR_API_BASE_URL",
    "API_BASE_URL",
  )?.replace(/\/$/, "");
  const apiKey = firstEnv(
    "SEMANTIC_API_KEY",
    "RUBRICATOR_API_KEY",
    "API_KEY",
  );

  if (!baseUrl) {
    return jsonResponse({
      error:
        "Upstream base URL secret missing (tried SEMANTIC_API_BASE_URL, RUBRICATOR_API_BASE_URL, API_BASE_URL)",
    }, 500);
  }
  if (!apiKey) {
    return jsonResponse({
      error:
        "Upstream API key secret missing (tried SEMANTIC_API_KEY, RUBRICATOR_API_KEY, API_KEY)",
    }, 500);
  }

  const incoming = new URL(req.url);
  const path = upstreamPath(incoming.pathname);
  const target = new URL(`${baseUrl}${path}`);
  target.search = incoming.search;

  const headers = new Headers();
  headers.set("Authorization", `Bearer ${apiKey}`);
  headers.set("Accept", req.headers.get("Accept") ?? "application/json");

  const contentType = req.headers.get("Content-Type");
  if (contentType) {
    headers.set("Content-Type", contentType);
  }

  const hasBody = req.method !== "GET" && req.method !== "HEAD";

  try {
    const body = hasBody ? await req.arrayBuffer() : undefined;
    const upstream = await fetch(target.toString(), {
      method: req.method,
      headers,
      body,
    });

    const responseHeaders = new Headers(corsHeaders);
    const upstreamContentType = upstream.headers.get("Content-Type");
    if (upstreamContentType) {
      responseHeaders.set("Content-Type", upstreamContentType);
    } else {
      responseHeaders.set("Content-Type", "application/json");
    }

    return new Response(upstream.body, {
      status: upstream.status,
      headers: responseHeaders,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return jsonResponse({ error: `Upstream request failed: ${message}` }, 502);
  }
});
