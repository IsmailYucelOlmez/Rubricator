import "jsr:@supabase/functions-js@2/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

import { type ContactMessage, createHandler } from "./handler.ts";

/**
 * The website's contact form → email to the support address via Resend.
 * See handler.ts for the anti-abuse rules and migration
 * 20261003000000_contact_rate_limit.sql for the per-IP limit.
 *
 * `verify_jwt` is false in config.toml: the form is used without an account
 * and the site only has the `sb_publishable_*` key (not a JWT).
 *
 * Secrets: RESEND_API_KEY (required), optional CONTACT_TO (default
 * support@rubricator.site), CONTACT_FROM (default "Rubricator website
 * <noreply@rubricator.site>", the domain must be verified in Resend),
 * CONTACT_IP_SALT and ALLOWED_ORIGINS. SUPABASE_URL and
 * SUPABASE_SERVICE_ROLE_KEY are provided by the platform.
 */

function requireEnv(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing env ${name}`);
  return value;
}

const admin = () =>
  createClient(
    requireEnv("SUPABASE_URL"),
    requireEnv("SUPABASE_SERVICE_ROLE_KEY"),
    { auth: { persistSession: false, autoRefreshToken: false } },
  );

function emailText(m: ContactMessage): string {
  return [
    `From: ${m.name || "(no name)"} <${m.email}>`,
    `Language: ${m.lang}`,
    "",
    m.message,
    "",
    "-- Sent from the contact form on rubricator.site",
  ].join("\n");
}

const handler = createHandler({
  env: Deno.env,

  async allow(ipHash) {
    const { data, error } = await admin().rpc("contact_allow", {
      p_ip_hash: ipHash,
    });
    if (error) throw new Error(error.message);
    return data === true;
  },

  async send(m) {
    const response = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${requireEnv("RESEND_API_KEY")}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: Deno.env.get("CONTACT_FROM")?.trim() ||
          "Rubricator website <noreply@rubricator.site>",
        to: [Deno.env.get("CONTACT_TO")?.trim() || "support@rubricator.site"],
        reply_to: m.email,
        subject: `[rubricator.site] ${m.name || m.email}`,
        text: emailText(m),
      }),
    });
    if (!response.ok) {
      throw new Error(`Resend ${response.status}: ${await response.text()}`);
    }
  },

  log(event, detail) {
    console.log(JSON.stringify({ event, ...detail }));
  },
});

Deno.serve(handler);
