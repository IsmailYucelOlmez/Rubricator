/**
 * Request handling for the `contact` edge function: the website's contact form
 * sends a message here and it is emailed to the support address. Kept free of
 * I/O so it can be unit-tested with fakes (see handler_test.ts); `index.ts`
 * wires the real Supabase / Resend dependencies.
 *
 * Anyone can call this without an account, so it must not become a spam relay:
 *   1. only POST from an allowed browser origin (no Origin header = rejected:
 *      the apps don't use this endpoint),
 *   2. a small body cap and strict field validation,
 *   3. a honeypot field (bots fill it; we answer "ok" and send nothing),
 *   4. a per-IP rate limit (hashed IP, see migration contact_rate_limit),
 *   5. the email always goes to our own address; the sender's address is only
 *      used as Reply-To, never as a recipient.
 */

import {
  allowedOrigins,
  corsHeaders,
  isAllowedOrigin,
} from "../_shared/origin_policy.ts";

export interface ContactMessage {
  name: string;
  email: string;
  message: string;
  lang: "en" | "tr";
}

export interface Deps {
  env: { get(name: string): string | undefined };
  /** Records the attempt; false when this IP hash is over its limit. */
  allow(ipHash: string): Promise<boolean>;
  send(message: ContactMessage): Promise<void>;
  log?(event: string, detail?: Record<string, unknown>): void;
}

export const MAX_BODY_BYTES = 12_000;
export const LIMITS = {
  name: 100,
  email: 254,
  messageMin: 10,
  messageMax: 5000,
};

// Deliberately simple: one "@", something on both sides, a dot in the domain.
const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function json(
  status: number,
  body: Record<string, unknown>,
  cors: Record<string, string>,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
}

/** sha-256 of the client IP (salted), so raw IPs are never stored. */
export async function hashIp(ip: string, salt: string): Promise<string> {
  const data = new TextEncoder().encode(`${salt}:${ip}`);
  const digest = await crypto.subtle.digest("SHA-256", data);
  return [...new Uint8Array(digest)]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

function clientIp(req: Request): string {
  const forwarded = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim();
  return forwarded || req.headers.get("x-real-ip")?.trim() || "unknown";
}

type Field = "name" | "email" | "message";

/** Field-level problems use stable codes; the website maps them to text. */
export function validate(
  body: unknown,
): { ok: true; value: ContactMessage; honeypot: boolean } | {
  ok: false;
  fields: Partial<Record<Field, string>>;
} {
  const b = (body && typeof body === "object" ? body : {}) as Record<
    string,
    unknown
  >;
  const str = (v: unknown) => (typeof v === "string" ? v.trim() : "");
  const name = str(b.name);
  const email = str(b.email);
  const message = str(b.message);
  const fields: Partial<Record<Field, string>> = {};
  if (name.length > LIMITS.name) fields.name = "too_long";
  if (!email) fields.email = "required";
  else if (email.length > LIMITS.email || !EMAIL.test(email)) {
    fields.email = "invalid";
  }
  if (!message) fields.message = "required";
  else if (message.length < LIMITS.messageMin) fields.message = "too_short";
  else if (message.length > LIMITS.messageMax) fields.message = "too_long";
  if (Object.keys(fields).length) return { ok: false, fields };
  return {
    ok: true,
    value: { name, email, message, lang: b.lang === "tr" ? "tr" : "en" },
    honeypot: str(b.website) !== "",
  };
}

export function createHandler(deps: Deps) {
  const log = deps.log ?? (() => {});
  return async (req: Request): Promise<Response> => {
    const origin = req.headers.get("origin");
    if (!origin || !isAllowedOrigin(origin, allowedOrigins(deps.env))) {
      return json(403, { error: "forbidden_origin" }, {});
    }
    const cors = corsHeaders(origin, "POST, OPTIONS");
    if (req.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: cors });
    }
    if (req.method !== "POST") {
      return json(405, { error: "method_not_allowed" }, cors);
    }

    const length = Number(req.headers.get("content-length") ?? "0");
    if (length > MAX_BODY_BYTES) return json(413, { error: "too_large" }, cors);
    const raw = await req.text();
    if (raw.length > MAX_BODY_BYTES) {
      return json(413, { error: "too_large" }, cors);
    }

    let body: unknown;
    try {
      body = JSON.parse(raw);
    } catch {
      return json(400, { error: "invalid_json" }, cors);
    }
    const checked = validate(body);
    if (!checked.ok) {
      return json(400, { error: "invalid", fields: checked.fields }, cors);
    }

    // A bot filled the hidden field: look successful, send nothing.
    if (checked.honeypot) {
      log("contact_honeypot");
      return json(200, { ok: true }, cors);
    }

    const ipHash = await hashIp(
      clientIp(req),
      deps.env.get("CONTACT_IP_SALT") ?? "",
    );
    if (!(await deps.allow(ipHash))) {
      log("contact_rate_limited");
      return json(429, { error: "rate_limited" }, cors);
    }

    try {
      await deps.send(checked.value);
    } catch (error) {
      log("contact_send_failed", { message: String(error) });
      return json(502, { error: "send_failed" }, cors);
    }
    return json(200, { ok: true }, cors);
  };
}
