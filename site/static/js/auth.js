// Minimal Supabase Auth (GoTrue) client for the Virgil page: password sign-in,
// sign-up, recovery by one-time code, token refresh and sign-out. It talks to
// the same REST endpoints supabase-js does, without shipping the library.
//
// The session lives in localStorage (see the privacy policy, "Local storage").
// Nothing here touches the DOM, so it can be unit tested with fakes.

export const SESSION_KEY = "rubricator.web.session";
const REFRESH_MARGIN_SECONDS = 60;

export class AuthError extends Error {
  /** @param {string} code GoTrue error_code, or "network" / "unknown". */
  constructor(code, status, message) {
    super(message || code);
    this.name = "AuthError";
    this.code = code;
    this.status = status;
  }
}

/**
 * @typedef {{accessToken: string, refreshToken: string, expiresAt: number,
 *   user: {id: string, email: string, username: string}}} Session
 */

function toSession(data, nowMs) {
  if (!data || typeof data.access_token !== "string" || !data.refresh_token) {
    return null;
  }
  const expiresAt = typeof data.expires_at === "number"
    ? data.expires_at
    : Math.floor(nowMs / 1000) + Number(data.expires_in || 3600);
  const user = data.user ?? {};
  return {
    accessToken: data.access_token,
    refreshToken: data.refresh_token,
    expiresAt,
    user: {
      id: String(user.id ?? ""),
      email: String(user.email ?? ""),
      username: String(user.user_metadata?.username ?? ""),
    },
  };
}

/**
 * @param {{url: string, anonKey: string,
 *   storage?: Pick<Storage, "getItem" | "setItem" | "removeItem">,
 *   fetchFn?: typeof fetch, now?: () => number}} options
 */
export function createAuth(options) {
  const url = options.url.replace(/\/+$/, "");
  const anonKey = options.anonKey;
  const fetchFn = options.fetchFn ?? ((...args) => fetch(...args));
  const now = options.now ?? (() => Date.now());
  const memory = new Map();
  const listeners = new Set();

  // Storage can throw (blocked site data, private windows): fall back to memory
  // so signing in still works for this page load.
  const store = {
    get() {
      try {
        const raw = options.storage?.getItem(SESSION_KEY);
        if (raw) return JSON.parse(raw);
      } catch { /* fall through to memory */ }
      return memory.get(SESSION_KEY) ?? null;
    },
    set(session) {
      memory.set(SESSION_KEY, session);
      try {
        options.storage?.setItem(SESSION_KEY, JSON.stringify(session));
      } catch { /* memory only */ }
    },
    clear() {
      memory.delete(SESSION_KEY);
      try {
        options.storage?.removeItem(SESSION_KEY);
      } catch { /* ignore */ }
    },
  };

  const notify = () => {
    const session = store.get();
    for (const listener of listeners) listener(session);
  };

  async function request(path, { method = "POST", body, token } = {}) {
    const headers = { apikey: anonKey, "Content-Type": "application/json" };
    if (token) headers.Authorization = `Bearer ${token}`;
    let response;
    try {
      response = await fetchFn(`${url}${path}`, {
        method,
        headers,
        body: body === undefined ? undefined : JSON.stringify(body),
      });
    } catch {
      throw new AuthError("network", 0, "Network error");
    }
    let data = null;
    try {
      const text = await response.text();
      data = text ? JSON.parse(text) : null;
    } catch { /* non-JSON body */ }
    if (!response.ok) {
      const code = typeof data?.error_code === "string"
        ? data.error_code
        : typeof data?.error === "string"
        ? data.error
        : response.status === 429
        ? "over_request_rate_limit"
        : "unknown";
      throw new AuthError(
        code,
        response.status,
        data?.msg ?? data?.error_description ?? data?.message ?? code,
      );
    }
    return data;
  }

  const save = (data) => {
    const session = toSession(data, now());
    if (!session) throw new AuthError("unknown", 0, "Invalid session response");
    store.set(session);
    notify();
    return session;
  };

  let refreshing = null;

  async function doRefresh(stale) {
    // Another tab may already have rotated the refresh token.
    const current = store.get();
    if (
      current && current.refreshToken !== stale.refreshToken &&
      current.expiresAt - now() / 1000 > REFRESH_MARGIN_SECONDS
    ) return current;
    try {
      const data = await request("/auth/v1/token?grant_type=refresh_token", {
        body: { refresh_token: (current ?? stale).refreshToken },
      });
      return save(data);
    } catch (error) {
      // A rejected refresh token means the session is over; a network error
      // keeps it so the user can simply retry.
      if (error instanceof AuthError && error.status >= 400 && error.status < 500 && error.status !== 429) {
        store.clear();
        notify();
        return null;
      }
      throw error;
    }
  }

  return {
    /** @returns {Session | null} */
    getSession: () => store.get(),

    /** Calls back with the session (or null) whenever it changes. */
    onChange(listener) {
      listeners.add(listener);
      return () => listeners.delete(listener);
    },

    /** Re-reads the stored session (used after another tab changed it). */
    reload: notify,

    /**
     * A token valid for at least a minute, refreshing when needed; null when
     * signed out. `force` refreshes even a token that looks valid (after a 401).
     */
    async getAccessToken(force = false) {
      const session = store.get();
      if (!session) return null;
      if (!force && session.expiresAt - now() / 1000 > REFRESH_MARGIN_SECONDS) {
        return session.accessToken;
      }
      refreshing ??= doRefresh(session).finally(() => {
        refreshing = null;
      });
      return (await refreshing)?.accessToken ?? null;
    },

    async signIn(email, password) {
      const data = await request("/auth/v1/token?grant_type=password", {
        body: { email: email.trim(), password },
      });
      return save(data);
    },

    /**
     * @returns {Promise<{session: Session | null}>} session is null while the
     * account still has to be confirmed by email.
     */
    async signUp({ email, password, username, policyVersion }) {
      const data = await request("/auth/v1/signup", {
        body: {
          email: email.trim(),
          password,
          data: {
            username: username.trim(),
            privacy_policy_accepted_at: new Date(now()).toISOString(),
            privacy_policy_version: policyVersion,
          },
        },
      });
      return { session: data?.access_token ? save(data) : null };
    },

    /** Emails an 8-digit recovery code (same flow as the mobile app). */
    async sendRecoveryCode(email) {
      await request("/auth/v1/recover", { body: { email: email.trim() } });
    },

    /** Verifies the emailed code, sets the new password and signs in. */
    async resetPassword({ email, code, newPassword }) {
      const verified = await request("/auth/v1/verify", {
        body: { type: "recovery", email: email.trim(), token: code.trim() },
      });
      if (!verified?.access_token) {
        throw new AuthError("otp_expired", 400, "Recovery verification failed");
      }
      await request("/auth/v1/user", {
        method: "PUT",
        token: verified.access_token,
        body: { password: newPassword },
      });
      return save(verified);
    },

    async signOut() {
      const session = store.get();
      store.clear();
      notify();
      if (!session) return;
      try {
        await request("/auth/v1/logout?scope=local", {
          token: session.accessToken,
        });
      } catch { /* the local session is already gone */ }
    },
  };
}

/** Same rules as the mobile app (lib/core/validation/form_validators.dart). */
export function validatePassword(value) {
  if (!value) return "empty";
  if (value.length < 6) return "tooShort";
  if (!/[A-Z]/.test(value)) return "missingUppercase";
  if (!/[a-z]/.test(value)) return "missingLowercase";
  if (!/\p{P}/u.test(value)) return "missingPunctuation";
  return null;
}

export function isValidEmail(value) {
  const v = value.trim();
  return v.includes("@") && v.length >= 3;
}
