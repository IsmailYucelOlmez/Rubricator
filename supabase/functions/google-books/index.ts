import "jsr:@supabase/functions-js@2/edge-runtime.d.ts";

import { createHandler } from "./handler.ts";

/**
 * Narrow proxy to the Google Books API that adds the server-side API key.
 * See handler.ts for what it allows and why. Optional secret ALLOWED_ORIGINS
 * (comma-separated browser origins) extends the built-in allow-list.
 */
Deno.serve(createHandler({
  env: Deno.env,
  fetchUpstream: (url, init) => fetch(url, init),
  log: (message, data) => console.warn(message, JSON.stringify(data ?? {})),
}));
