/**
 * Request handling for the `delete-account` edge function: a signed-in user
 * permanently deletes their own account from the profile page. Kept free of
 * I/O so it can be unit-tested with fakes (see handler_test.ts); `index.ts`
 * wires the real Supabase dependencies.
 *
 * Rules:
 *   1. the caller's identity comes only from their session JWT (never from the
 *      body), so nobody can delete someone else's account,
 *   2. the request must carry the email OTP the app just sent to that user's
 *      address; it is verified here, server-side, and the verified user must
 *      be the caller (a stolen access token alone is not enough),
 *   3. native apps send no Origin header; browsers must be on the allow-list.
 *
 * Deleting the auth user cascades to every public table (all foreign keys to
 * auth.users are `on delete cascade`, search_logs is `set null`); storage
 * objects are not covered by that, so `deleteAccount` removes them first.
 */

import {
  allowedOrigins,
  corsHeaders,
  isAllowedOrigin,
} from "../_shared/origin_policy.ts";

export interface CallerUser {
  id: string;
  email: string | null;
}

export interface Deps {
  env: { get(name: string): string | undefined };
  /** The user behind a session JWT, or null when it is invalid/expired. */
  getUser(token: string, apikey: string | null): Promise<CallerUser | null>;
  /** Verifies an email OTP; the id of the user it belongs to, or null. */
  verifyOtp(email: string, code: string): Promise<string | null>;
  /** Removes the user's storage objects and then the auth user. */
  deleteAccount(userId: string): Promise<void>;
  log?(event: string, detail?: Record<string, unknown>): void;
}

export const MAX_BODY_BYTES = 1_000;

// GoTrue email OTPs are 6–10 digits depending on the project setting.
const OTP = /^\d{6,10}$/;
const JWT_SHAPE = /^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/;

export function bearerJwt(header: string | null): string | null {
  const token = header?.match(/^Bearer\s+(\S+)$/i)?.[1];
  if (!token || token.length > 4096 || !JWT_SHAPE.test(token)) return null;
  return token;
}

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

export function createHandler(deps: Deps) {
  const log = deps.log ?? (() => {});
  return async (req: Request): Promise<Response> => {
    const origin = req.headers.get("origin");
    if (origin && !isAllowedOrigin(origin, allowedOrigins(deps.env))) {
      return json(403, { error: "forbidden_origin" }, {});
    }
    const cors = corsHeaders(origin, "POST, OPTIONS");
    if (req.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: cors });
    }
    if (req.method !== "POST") {
      return json(405, { error: "method_not_allowed" }, cors);
    }

    const token = bearerJwt(req.headers.get("authorization"));
    const caller = token
      ? await deps.getUser(token, req.headers.get("apikey"))
      : null;
    if (!caller) return json(401, { error: "unauthorized" }, cors);
    if (!caller.email) {
      // Every account here signs up with email; without one there is no OTP.
      return json(400, { error: "no_email" }, cors);
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
    const code = typeof (body as { code?: unknown })?.code === "string"
      ? (body as { code: string }).code.trim()
      : "";
    if (!OTP.test(code)) return json(400, { error: "invalid_code" }, cors);

    const verifiedId = await deps.verifyOtp(caller.email, code);
    if (verifiedId !== caller.id) {
      log("delete_account_bad_code", { userId: caller.id });
      return json(400, { error: "invalid_code" }, cors);
    }

    try {
      await deps.deleteAccount(caller.id);
    } catch (error) {
      log("delete_account_failed", {
        userId: caller.id,
        message: String(error),
      });
      return json(500, { error: "delete_failed" }, cors);
    }
    log("delete_account_done", { userId: caller.id });
    return json(200, { ok: true }, cors);
  };
}
