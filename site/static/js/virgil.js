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
/** The API takes at most this many ISBNs per side of a refinement. */
export const MAX_REFINEMENT_ISBNS = 5;
const ISBN = /^[0-9]{9,12}[0-9X]$/;

/** Only results with a real ISBN can be marked (same rule as the API/RPC). */
export function isVotableIsbn(isbn) {
  return ISBN.test(String(isbn ?? "").trim().toUpperCase());
}

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

/**
 * The whole description, tidied: runs of spaces collapse, paragraph breaks
 * stay (the dialog shows them with `white-space: pre-line`).
 */
function tidy(text) {
  return String(text ?? "")
    .replace(/\r\n?/g, "\n")
    .split("\n")
    .map((line) => line.replace(/\s+/g, " ").trim())
    .join("\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim();
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
      description: tidy(item.description),
      category: item.category ? String(item.category) : "",
      cover: httpsUrl(item.coverImageUrl),
      similarity: typeof item.similarity === "number" ? item.similarity : null,
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
      throw new VirgilError(
        error?.name === "AbortError" ? "timeout" : "network",
      );
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
        data?.error === "daily_limit_reached"
          ? "daily_limit_reached"
          : "rate_limited",
        429,
      );
    }
    if (response.status === 400) throw new VirgilError("invalid_query", 400);
    throw new VirgilError("server", response.status);
  }

  return {
    /**
     * `feedback` (optional): ISBNs marked relevant / irrelevant for this query;
     * the API steers toward / away from them and leaves the irrelevant out.
     * @param {{query: string, category?: string, language?: string,
     *   feedback?: {relevant: string[], irrelevant: string[]} | null}} options
     */
    async search(
      { query, category = "All", language = "en", feedback = null },
    ) {
      const refined = feedback &&
        (feedback.relevant.length > 0 || feedback.irrelevant.length > 0);
      const data = await call(
        "/functions/v1/rubricatorApi/api/v1/semantic/search",
        {
          body: {
            query: query.trim(),
            mode: "advanced",
            category,
            tone: "All",
            limit: 16,
            language,
            ...(refined
              ? {
                feedback: {
                  relevant: feedback.relevant.slice(-MAX_REFINEMENT_ISBNS),
                  irrelevant: feedback.irrelevant.slice(-MAX_REFINEMENT_ISBNS),
                },
              }
              : {}),
          },
        },
      );
      return normalizeResults(data);
    },

    /**
     * The user's marks for a query, as a Map isbn13 -> 1 | -1. Votes are
     * stored per (query, language), like the app. Fails open (empty map).
     * @param {{query: string, language: string}} key
     * @returns {Promise<Map<string, number>>}
     */
    async votes({ query, language }) {
      const marks = new Map();
      try {
        const rows = await call("/rest/v1/rpc/get_my_semantic_feedback", {
          body: { p_query: query, p_language: language },
        });
        for (const row of Array.isArray(rows) ? rows : []) {
          const vote = Number(row?.vote);
          if (typeof row?.isbn13 === "string" && (vote === 1 || vote === -1)) {
            marks.set(row.isbn13, vote);
          }
        }
      } catch { /* no marks shown; voting still works */ }
      return marks;
    },

    /**
     * Sets (1 / -1) or removes (0) the user's mark on one result.
     * @param {{query: string, language: string, isbn13: string, vote: number,
     *   position?: number, similarity?: number | null, category?: string}} mark
     */
    async vote(
      { query, language, isbn13, vote, position, similarity, category },
    ) {
      await call("/rest/v1/rpc/submit_semantic_feedback", {
        body: {
          p_query: query,
          p_isbn13: isbn13,
          p_vote: vote,
          p_language: language,
          p_result_position: position ?? null,
          p_similarity: similarity ?? null,
          p_mode: "advanced",
          p_category: category && category !== "All" ? category : null,
          p_tone: null,
        },
      });
    },

    /** Today's recommendation quota, or null when it can't be read. */
    async usage() {
      try {
        const rows = await call("/rest/v1/rpc/get_virgil_usage_today", {
          body: {},
        });
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
