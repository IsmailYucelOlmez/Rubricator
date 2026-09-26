// Virgil recommendation calls: the same edge function and request the mobile
// app uses (POST /functions/v1/rubricatorApi/api/v1/semantic/search).

export const GENRES = [
  "All",
  "Fiction",
  "Nonfiction",
  "Children's Fiction",
  "Children's Nonfiction",
];

export const MIN_QUERY_LENGTH = 3;
export const MAX_QUERY_LENGTH = 500;
const SEARCH_TIMEOUT_MS = 35_000;
const DESCRIPTION_LIMIT = 420;

export class VirgilError extends Error {
  /**
   * @param {"unauthorized" | "daily_limit_reached" | "rate_limited" |
   *   "invalid_query" | "network" | "timeout" | "server"} code
   */
  constructor(code, status = 0) {
    super(code);
    this.name = "VirgilError";
    this.code = code;
    this.status = status;
  }
}

/** Cover URLs from some catalogs are plain http; the page is https. */
export function httpsUrl(value) {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  if (!trimmed) return null;
  const upgraded = trimmed.replace(/^http:\/\//i, "https://");
  try {
    const parsed = new URL(upgraded);
    return parsed.protocol === "https:" ? parsed.href : null;
  } catch {
    return null;
  }
}

function clip(text, limit) {
  const clean = String(text ?? "").replace(/\s+/g, " ").trim();
  if (clean.length <= limit) return clean;
  return clean.slice(0, limit).replace(/\s+\S*$/, "") + "…";
}

/** Keeps the fields the page shows and drops results without an ISBN. */
export function normalizeResults(payload) {
  const raw = Array.isArray(payload?.results) ? payload.results : [];
  return raw
    .filter((item) => item && typeof item === "object")
    .map((item) => ({
      isbn13: String(item.isbn13 ?? ""),
      title: String(item.title ?? "").trim(),
      author: String(item.author ?? "").trim(),
      description: clip(item.description, DESCRIPTION_LIMIT),
      category: item.category ? String(item.category) : "",
      cover: httpsUrl(item.coverImageUrl),
    }))
    .filter((item) => item.isbn13 !== "");
}

/**
 * @param {{url: string, anonKey: string,
 *   getToken: (force?: boolean) => Promise<string | null>,
 *   fetchFn?: typeof fetch}} options
 */
export function createVirgil(options) {
  const base = options.url.replace(/\/+$/, "");
  const fetchFn = options.fetchFn ?? ((...args) => fetch(...args));

  async function call(path, { body, rpc = false, force = false }) {
    const token = await options.getToken(force);
    if (!token) throw new VirgilError("unauthorized", 401);
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), SEARCH_TIMEOUT_MS);
    let response;
    try {
      response = await fetchFn(`${base}${path}`, {
        method: "POST",
        headers: {
          apikey: options.anonKey,
          Authorization: `Bearer ${token}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(body),
        signal: controller.signal,
      });
    } catch (error) {
      throw new VirgilError(error?.name === "AbortError" ? "timeout" : "network");
    } finally {
      clearTimeout(timer);
    }
    if (response.status === 401 && !force) {
      // The access token may have been revoked: refresh once and retry.
      return call(path, { body, rpc, force: true });
    }
    let data = null;
    try {
      data = await response.json();
    } catch { /* empty or non-JSON body */ }
    if (response.ok) return data;
    if (response.status === 401) throw new VirgilError("unauthorized", 401);
    if (response.status === 429) {
      throw new VirgilError(
        data?.error === "daily_limit_reached" ? "daily_limit_reached" : "rate_limited",
        429,
      );
    }
    if (response.status === 400) throw new VirgilError("invalid_query", 400);
    throw new VirgilError("server", response.status);
  }

  return {
    async search({ query, category = "All", language = "en" }) {
      const data = await call("/functions/v1/rubricatorApi/api/v1/semantic/search", {
        body: {
          query: query.trim(),
          mode: "advanced",
          category,
          tone: "All",
          limit: 16,
          language,
        },
      });
      return normalizeResults(data);
    },

    /** Today's recommendation quota, or null when it can't be read. */
    async usage() {
      try {
        const rows = await call("/rest/v1/rpc/get_virgil_usage_today", { body: {} });
        const row = Array.isArray(rows) ? rows[0] : rows;
        if (typeof row?.recommendations_count !== "number") return null;
        return {
          used: row.recommendations_count,
          limit: Number(row.recommendations_limit) || 5,
        };
      } catch {
        return null;
      }
    },
  };
}
