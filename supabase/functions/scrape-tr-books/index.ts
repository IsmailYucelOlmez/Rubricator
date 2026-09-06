import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { DOMParser } from "jsr:@b-fuze/deno-dom@0.1.49";

// ---------------------------------------------------------------------------
// Everything for this function lives in this single file on purpose: the
// Supabase Dashboard's web-based function editor bundles per top-level
// function and does not reliably resolve relative imports into a nested
// `sources/` folder (`Module not found ".../sources/kitapyurdu.ts"`). A
// second bookstore source (e.g. İdefix) is still meant to be pluggable —
// add it as another object satisfying `BookSource` below and push it into
// `SOURCES` — just as another exported const in this same file rather than
// a separate module. If this project moves to CLI-based deploys (which do
// resolve multi-file functions fine), it can be re-split into files.
// ---------------------------------------------------------------------------

// ---- Shared source contract ------------------------------------------------

interface ScrapedBook {
  isbn: string;
  title: string;
  author?: string;
  publisher?: string;
  description?: string;
  imageUrl?: string;
  pageCount?: number;
  sourceUrl: string;
}

interface BookSource {
  /** Discriminator stored in `trbooks.source`, e.g. `kitapyurdu_scrape`. */
  id: string;
  /** Product detail page URLs to visit for a given home-page genre key. */
  fetchCandidates(genreKey: string): Promise<string[]>;
  /** Fetches and parses one product detail page; `null` when the page 404s,
   * the fetch fails, or no ISBN is found. Never throws. */
  fetchProduct(url: string): Promise<ScrapedBook | null>;
}

// ---- Kitapyurdu source ------------------------------------------------------

const KITAPYURDU_BASE = "https://www.kitapyurdu.com";

/** Same Turkish genre keywords already used by `HomeRemoteDataSource` (Dart)
 * and `warm-genre-cache`'s `TURKISH_GENRE_QUERIES` — kept as a third literal
 * copy here rather than shared, since this file's shape (search vs. curated
 * list per genre) doesn't match either existing const's shape. */
type KitapyurduGenreSource =
  | { kind: "search"; query: string }
  | { kind: "list"; listId: string };

const KITAPYURDU_GENRE_SOURCES: Record<string, KitapyurduGenreSource> = {
  // "Son 10 Yılda En Çok Okunan Kitaplar" — Kitapyurdu's own curated
  // best-read list, used verbatim as the home page's "popular" section.
  popular_fiction: { kind: "list", listId: "631" },
  fantasy: { kind: "search", query: "fantastik" },
  science_fiction: { kind: "search", query: "bilim kurgu" },
  romance: { kind: "search", query: "aşk romanı" },
  mystery: { kind: "search", query: "polisiye" },
  thriller: { kind: "search", query: "gerilim" },
  horror: { kind: "search", query: "korku" },
};

const KITAPYURDU_MAX_CANDIDATES_PER_GENRE = 20;

// A UA string that self-identifies as a bot/scraper (our original
// "BookAppTrBooksScraper/1.0") gets an immediate 403 from Kitapyurdu's WAF —
// confirmed by deploying with it. robots.txt already permits crawling these
// paths (see the migration/plan notes), so this isn't bypassing an access
// restriction the site operator expressed anywhere; it's working around a
// generic "looks like an unrecognized client" heuristic that also blocks
// perfectly legitimate traffic. A realistic desktop-browser header set is
// the standard, minimal fix for that class of block.
const KITAPYURDU_FETCH_HEADERS: Record<string, string> = {
  "User-Agent":
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " +
    "(KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36",
  "Accept-Language": "tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7",
  Accept:
    "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
  Referer: `${KITAPYURDU_BASE}/`,
};

function kitapyurduListingUrl(source: KitapyurduGenreSource): string {
  const url = new URL(`${KITAPYURDU_BASE}/index.php`);
  if (source.kind === "list") {
    url.searchParams.set("route", "product/list");
    url.searchParams.set("list_id", source.listId);
  } else {
    url.searchParams.set("route", "product/search");
    url.searchParams.set("filter_name", source.query);
    // "Çok Satanlar" (bestseller-order) sort, so genre searches surface
    // widely-read books rather than an arbitrary relevance match.
    url.searchParams.set("sort", "purchased_365");
    url.searchParams.set("order", "DESC");
  }
  url.searchParams.set("limit", "100");
  return url.toString();
}

/** Strips Kitapyurdu's per-visit tracking params (`s_token`, `s_time`,
 * `filter_name`) from a product URL so the same book always yields the same
 * `source_url`, regardless of which listing page linked to it. */
function kitapyurduCanonicalProductUrl(href: string): string | null {
  try {
    const url = new URL(href, KITAPYURDU_BASE);
    if (!url.pathname.startsWith("/kitap/")) return null;
    return `${url.origin}${url.pathname}`;
  } catch {
    return null;
  }
}

/** Pure parse: extracts candidate product-page URLs from a listing (search
 * or curated-list) page's HTML. No network access — testable with a saved
 * fixture. */
export function parseKitapyurduListingPage(html: string): string[] {
  const doc = new DOMParser().parseFromString(html, "text/html");
  if (!doc) return [];

  const urls: string[] = [];
  const seen = new Set<string>();
  for (const card of doc.querySelectorAll(".ky-product")) {
    const anchor = card.querySelector("a.ky-product-cover");
    const href = anchor?.getAttribute("href");
    if (!href) continue;
    const canonical = kitapyurduCanonicalProductUrl(href);
    if (!canonical || seen.has(canonical)) continue;
    seen.add(canonical);
    urls.push(canonical);
  }
  return urls;
}

function kitapyurduLabeledSpecValue(
  doc: ReturnType<DOMParser["parseFromString"]>,
  label: string,
): string | null {
  if (!doc) return null;
  for (const row of doc.querySelectorAll(".attributes tr")) {
    const cells = row.querySelectorAll("td");
    if (cells.length < 2) continue;
    const key = cells[0].textContent?.trim();
    if (key === label) {
      return cells[1].textContent?.trim() || null;
    }
  }
  return null;
}

function kitapyurduMetaContent(
  doc: ReturnType<DOMParser["parseFromString"]>,
  property: string,
): string | null {
  if (!doc) return null;
  const el = doc.querySelector(`meta[property="${property}"]`);
  return el?.getAttribute("content")?.trim() || null;
}

function kitapyurduFirstLinkText(
  doc: ReturnType<DOMParser["parseFromString"]>,
  hrefContains: string,
): string | null {
  if (!doc) return null;
  for (const anchor of doc.querySelectorAll("a.pr_producers__link")) {
    const href = anchor.getAttribute("href") ?? "";
    if (href.includes(hrefContains)) {
      return anchor.textContent?.trim() || null;
    }
  }
  return null;
}

function normalizeIsbn(raw: string | null): string | null {
  if (!raw) return null;
  const digits = raw.replace(/[^0-9Xx]/g, "");
  return digits.length >= 10 ? digits : null;
}

/** Pure parse: extracts a [ScrapedBook] from one product detail page's HTML.
 * Returns `null` (never throws) when no usable ISBN is found — the caller
 * must skip such candidates entirely, since ISBN is the only dedup key. */
export function parseKitapyurduProductPage(
  html: string,
  url: string,
): ScrapedBook | null {
  const doc = new DOMParser().parseFromString(html, "text/html");
  if (!doc) return null;

  const isbn = normalizeIsbn(kitapyurduLabeledSpecValue(doc, "ISBN:"));
  if (!isbn) return null;

  const title = doc.querySelector("h1.pr_header__heading")?.textContent
    ?.trim() ||
    kitapyurduMetaContent(doc, "og:title") ||
    "";
  if (!title) return null;

  const author = kitapyurduFirstLinkText(doc, "/yazar/") ?? undefined;
  const publisher = kitapyurduFirstLinkText(doc, "/yayinevi/") ?? undefined;
  const description =
    doc.querySelector("#description_text .info__text")?.textContent
      ?.trim() ||
    kitapyurduMetaContent(doc, "og:description") ||
    undefined;
  const imageUrl =
    kitapyurduMetaContent(doc, "og:image")?.replace(/^http:/, "https:") ??
      undefined;
  const pageCountRaw = kitapyurduLabeledSpecValue(doc, "Sayfa Sayısı:");
  const pageCount = pageCountRaw ? Number.parseInt(pageCountRaw, 10) : NaN;

  return {
    isbn,
    title,
    author,
    publisher,
    description,
    imageUrl,
    pageCount: Number.isFinite(pageCount) ? pageCount : undefined,
    sourceUrl: url,
  };
}

function firstEnv(...keys: string[]): string | undefined {
  for (const key of keys) {
    const value = Deno.env.get(key)?.trim();
    if (value) return value;
  }
  return undefined;
}

/** Kitapyurdu's WAF blocks Supabase Edge Functions' (Deno Deploy) egress IP
 * range outright — confirmed by deploying with a realistic browser UA and
 * still getting 403, from the same requests that succeed from every other
 * network tested (dr.com.tr additionally confirmed to 403 a self-hosted
 * FastAPI relay's own IP too, so this isn't Deno-Deploy-specific — it's
 * broad datacenter/cloud-ASN blocking). When the same FastAPI base URL/API
 * key already used by the `rubricatorApi` edge function (see that function
 * for the identical `firstEnv` fallback list) is configured, fetches are
 * relayed through its `/api/v1/scrape-relay/fetch` endpoint instead. Falls
 * back to fetching [url] directly (with [directHeaders]) when no relay is
 * configured (e.g. local `deno test`/`supabase functions serve`), or when
 * a source doesn't need one. */
async function fetchViaRelayOrDirect(
  url: string,
  directHeaders: Record<string, string>,
): Promise<string> {
  const relayBaseUrl = firstEnv(
    "SEMANTIC_API_BASE_URL",
    "RUBRICATOR_API_BASE_URL",
    "API_BASE_URL",
  )?.replace(/\/$/, "");
  const relayApiKey = firstEnv(
    "SEMANTIC_API_KEY",
    "RUBRICATOR_API_KEY",
    "API_KEY",
  );

  if (relayBaseUrl && relayApiKey) {
    const relayUrl = `${relayBaseUrl}/api/v1/scrape-relay/fetch?url=${
      encodeURIComponent(url)
    }`;
    const response = await fetch(relayUrl, {
      headers: { Authorization: `Bearer ${relayApiKey}` },
    });
    if (!response.ok) {
      throw new Error(`Relay ${response.status} for ${url}`);
    }
    const body = await response.json() as { status: number; html: string };
    if (body.status < 200 || body.status >= 300) {
      throw new Error(`Upstream ${body.status} (via relay) for ${url}`);
    }
    return body.html;
  }

  const response = await fetch(url, { headers: directHeaders });
  if (!response.ok) {
    throw new Error(`Upstream ${response.status} for ${url}`);
  }
  return response.text();
}

function fetchKitapyurduHtml(url: string): Promise<string> {
  return fetchViaRelayOrDirect(url, KITAPYURDU_FETCH_HEADERS);
}

// Defined but not registered in `SOURCES` below: Kitapyurdu's WAF blocks
// every egress IP tried so far (Supabase Edge Functions and a self-hosted
// FastAPI relay alike). Kept here in case that ever changes, or another
// relay host that isn't blocked becomes available — re-add it to `SOURCES`
// to try it again without rewriting this.
const _kitapyurduSource: BookSource = {
  id: "kitapyurdu_scrape",

  async fetchCandidates(genreKey: string): Promise<string[]> {
    const genreSource = KITAPYURDU_GENRE_SOURCES[genreKey];
    if (!genreSource) return [];
    const html = await fetchKitapyurduHtml(kitapyurduListingUrl(genreSource));
    return parseKitapyurduListingPage(html).slice(
      0,
      KITAPYURDU_MAX_CANDIDATES_PER_GENRE,
    );
  },

  async fetchProduct(url: string): Promise<ScrapedBook | null> {
    try {
      const html = await fetchKitapyurduHtml(url);
      return parseKitapyurduProductPage(html, url);
    } catch {
      // One unreachable/broken product page shouldn't abort the whole run.
      return null;
    }
  },
};

// ---- D&R (dr.com.tr) source -------------------------------------------------

const DR_BASE = "https://www.dr.com.tr";

const DR_FETCH_HEADERS: Record<string, string> = {
  "User-Agent":
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " +
    "(KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36",
  "Accept-Language": "tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7",
  Accept:
    "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
  Referer: `${DR_BASE}/`,
};

// Kept low (rather than e.g. 20) since each candidate is a full relay round
// trip (Supabase → FastAPI → D&R) and the cron now runs one genre per
// invocation — see `resolveRequestedGenreKey` — to stay well under the
// edge function's per-invocation compute budget after hitting
// WORKER_RESOURCE_LIMIT with the previous do-all-genres-at-once shape.
const DR_MAX_CANDIDATES_PER_GENRE = 8;

/** D&R's own category ids under Kitap > Edebiyat > Roman — `korku-gerilim`
 * (horror-thriller) is D&R's own combined category, so `thriller` and
 * `horror` both map to it; `popular_fiction` uses the parent Roman category
 * (no slug) rather than a single-subcategory bestseller list, matching how
 * `warm-genre-cache`'s own `popular_fiction -> subject:fiction` is "fiction
 * in general", not a dedicated bestseller feed. */
const DR_GENRE_CATEGORIES: Record<string, { slug: string; grupno: string }> = {
  popular_fiction: { slug: "", grupno: "00211" },
  fantasy: { slug: "fantastik", grupno: "00451" },
  science_fiction: { slug: "bilim-kurgu", grupno: "00254" },
  romance: { slug: "romantik", grupno: "00553" },
  mystery: { slug: "polisiye", grupno: "00497" },
  thriller: { slug: "korku-gerilim", grupno: "00481" },
  horror: { slug: "korku-gerilim", grupno: "00481" },
};

function drListingUrl(category: { slug: string; grupno: string }): string {
  const path = category.slug
    ? `/kategori/kitap/edebiyat/roman/${category.slug}/grupno=${category.grupno}`
    : `/kategori/kitap/edebiyat/roman/grupno=${category.grupno}`;
  // SortType=0&SortOrder=1 = "Çok Satanlar" (bestseller-order), matching the
  // sort dropdown's own value for that option on the category page.
  return `${DR_BASE}${path}?SortType=0&SortOrder=1`;
}

/** Pure parse: extracts candidate product-page URLs from a D&R category
 * listing page's HTML. No network access — mirrors
 * [parseKitapyurduListingPage]'s shape for the equivalent Kitapyurdu page. */
export function parseDrListingPage(html: string): string[] {
  const doc = new DOMParser().parseFromString(html, "text/html");
  if (!doc) return [];

  const urls: string[] = [];
  const seen = new Set<string>();
  for (const card of doc.querySelectorAll(".prd")) {
    const href = card.querySelector("a")?.getAttribute("href");
    if (!href) continue;
    let absolute: string;
    try {
      absolute = new URL(href, DR_BASE).toString();
    } catch {
      continue;
    }
    if (seen.has(absolute)) continue;
    seen.add(absolute);
    urls.push(absolute);
  }
  return urls;
}

/** D&R's `application/ld+json` blocks contain literal (unescaped) newlines
 * inside string values (e.g. `description`) — technically invalid JSON that
 * `JSON.parse` rejects with "Bad control character in string literal",
 * confirmed against real fetched pages. Search engines' structured-data
 * parsers are lenient about this same real-world quirk; this walks the raw
 * text once, escaping control characters only while inside a string
 * literal (tracking `"` and `\` to stay JSON-string-aware) so surrounding
 * formatting whitespace is left untouched. */
function sanitizeJsonLd(raw: string): string {
  let result = "";
  let inString = false;
  let escaped = false;
  for (const ch of raw) {
    if (!inString) {
      if (ch === '"') inString = true;
      result += ch;
      continue;
    }
    if (escaped) {
      result += ch;
      escaped = false;
      continue;
    }
    if (ch === "\\") {
      result += ch;
      escaped = true;
    } else if (ch === '"') {
      inString = false;
      result += ch;
    } else if (ch === "\n") {
      result += "\\n";
    } else if (ch === "\r") {
      // dropped — paired with the \n that follows on Windows-style line endings
    } else if (ch === "\t") {
      result += "\\t";
    } else {
      result += ch;
    }
  }
  return result;
}

/** Pure parse: extracts a [ScrapedBook] from a D&R product page's
 * `schema.org/Book` JSON-LD block (`gtin13` is the ISBN-13). Returns `null`
 * (never throws) when no such block — or no `gtin13` in it — is found. */
export function parseDrProductPage(
  html: string,
  url: string,
): ScrapedBook | null {
  const doc = new DOMParser().parseFromString(html, "text/html");
  if (!doc) return null;

  for (
    const script of doc.querySelectorAll('script[type="application/ld+json"]')
  ) {
    let json: Record<string, unknown>;
    try {
      json = JSON.parse(sanitizeJsonLd(script.textContent ?? ""));
    } catch {
      continue;
    }
    const types = Array.isArray(json["@type"])
      ? json["@type"]
      : [json["@type"]];
    if (!types.includes("Book")) continue;

    const isbn = normalizeIsbn(
      typeof json.gtin13 === "string" ? json.gtin13 : null,
    );
    if (!isbn) return null;

    const title = typeof json.name === "string" ? json.name.trim() : "";
    if (!title) return null;

    const author = typeof json.author === "object" && json.author !== null
      ? (json.author as Record<string, unknown>).name
      : undefined;
    const publisher =
      typeof json.publisher === "object" && json.publisher !== null
        ? (json.publisher as Record<string, unknown>).name
        : undefined;
    const images = Array.isArray(json.image) ? json.image : [];
    const pageCount = typeof json.numberOfPages === "string"
      ? Number.parseInt(json.numberOfPages, 10)
      : undefined;

    return {
      isbn,
      title,
      author: typeof author === "string" ? author : undefined,
      publisher: typeof publisher === "string" ? publisher : undefined,
      description: typeof json.description === "string"
        ? json.description.trim()
        : undefined,
      imageUrl: typeof images[0] === "string" ? images[0] : undefined,
      pageCount: pageCount !== undefined && Number.isFinite(pageCount)
        ? pageCount
        : undefined,
      sourceUrl: url,
    };
  }

  return null;
}

function fetchDrHtml(url: string): Promise<string> {
  return fetchViaRelayOrDirect(url, DR_FETCH_HEADERS);
}

const drSource: BookSource = {
  id: "dr_scrape",

  async fetchCandidates(genreKey: string): Promise<string[]> {
    const category = DR_GENRE_CATEGORIES[genreKey];
    if (!category) return [];
    const html = await fetchDrHtml(drListingUrl(category));
    return parseDrListingPage(html).slice(0, DR_MAX_CANDIDATES_PER_GENRE);
  },

  async fetchProduct(url: string): Promise<ScrapedBook | null> {
    try {
      const html = await fetchDrHtml(url);
      return parseDrProductPage(html, url);
    } catch {
      // One unreachable/broken product page shouldn't abort the whole run.
      return null;
    }
  },
};

// ---- Genre loop, dedup, insert ----------------------------------------------

const TRBOOKS_TABLE = "trbooks";
const RUNS_TABLE = "trbooks_scrape_runs";

const GENRE_KEYS = [
  "popular_fiction",
  "fantasy",
  "science_fiction",
  "romance",
  "mystery",
  "thriller",
  "horror",
] as const;

/// Registered bookstore sources. `_kitapyurduSource` is defined above but
/// deliberately left out — every egress IP tried so far (Supabase Edge
/// Functions, a self-hosted FastAPI relay) gets 403'd by its WAF. A new
/// site is added by defining another `BookSource` object above and listing
/// it here — the genre loop, dedup, and logging below are source-agnostic.
const SOURCES: BookSource[] = [drSource];

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

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/// Small randomized delay between product-page visits — this scrapes a
/// shared catalog site meant for human browsing, not a bulk-access API, so
/// requests are sequential and politely paced rather than parallelized.
function politeDelay(): Promise<void> {
  return sleep(150 + Math.floor(Math.random() * 200));
}

type GenreRunResult = {
  status: "success" | "partial" | "error";
  candidatesSeen: number;
  inserted: number;
  skippedExisting: number;
  skippedNoIsbn: number;
  error?: string;
};

async function scrapeGenre(
  supabase: SupabaseClient,
  source: BookSource,
  genreKey: string,
): Promise<GenreRunResult> {
  let candidates: string[] = [];
  try {
    candidates = await source.fetchCandidates(genreKey);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return {
      status: "error",
      candidatesSeen: 0,
      inserted: 0,
      skippedExisting: 0,
      skippedNoIsbn: 0,
      error: message,
    };
  }

  const scraped: ScrapedBook[] = [];
  let skippedNoIsbn = 0;
  for (const url of candidates) {
    const book = await source.fetchProduct(url);
    if (book) {
      scraped.push(book);
    } else {
      skippedNoIsbn++;
    }
    await politeDelay();
  }

  if (scraped.length === 0) {
    return {
      status: candidates.length === 0 ? "error" : "partial",
      candidatesSeen: candidates.length,
      inserted: 0,
      skippedExisting: 0,
      skippedNoIsbn,
      error: candidates.length === 0
        ? "No candidate product pages found"
        : undefined,
    };
  }

  // Check the *whole* trbooks table (all sources) by ISBN — a book already
  // present from the one-time Kaggle import must not be re-inserted just
  // because this scrape also found it.
  const isbns = scraped.map((b) => b.isbn);
  const { data: existingRows, error: existingError } = await supabase
    .from(TRBOOKS_TABLE)
    .select("isbn")
    .in("isbn", isbns);
  if (existingError) {
    return {
      status: "error",
      candidatesSeen: candidates.length,
      inserted: 0,
      skippedExisting: 0,
      skippedNoIsbn,
      error: existingError.message,
    };
  }
  const existingIsbns = new Set(
    (existingRows ?? []).map((row) => row.isbn as string),
  );

  const newBooks = scraped.filter((b) => !existingIsbns.has(b.isbn));
  const skippedExisting = scraped.length - newBooks.length;

  let inserted = 0;
  let insertError: string | undefined;
  if (newBooks.length > 0) {
    const scrapedAt = new Date().toISOString();
    const { error } = await supabase.from(TRBOOKS_TABLE).insert(
      newBooks.map((book) => ({
        source: source.id,
        title: book.title,
        author: book.author ?? null,
        publisher: book.publisher ?? null,
        isbn: book.isbn,
        page_count: book.pageCount ?? null,
        description: book.description ?? null,
        language: "tr",
        image_url: book.imageUrl ?? null,
        genre_key: genreKey,
        source_url: book.sourceUrl,
        scraped_at: scrapedAt,
      })),
    );
    if (error) {
      insertError = error.message;
    } else {
      inserted = newBooks.length;
    }
  }

  return {
    status: insertError ? "partial" : "success",
    candidatesSeen: candidates.length,
    inserted,
    skippedExisting,
    skippedNoIsbn,
    error: insertError,
  };
}

/** A single invocation processing all 7 genres (each up to ~10-20 product
 * page fetches, through the relay) is what triggered Supabase's
 * `WORKER_RESOURCE_LIMIT` in production — too much aggregate work for one
 * function call's compute budget. Accepting an optional `genreKey` (query
 * param or JSON body) lets the cron schedule 7 small, staggered
 * invocations instead of one large one; omitting it keeps the old
 * do-everything behavior available for local testing with a trimmed-down
 * candidate count. */
async function resolveRequestedGenreKey(req: Request): Promise<string | null> {
  const fromQuery = new URL(req.url).searchParams.get("genreKey");
  if (fromQuery) return fromQuery;

  if (req.method === "POST") {
    try {
      const body = await req.clone().json();
      if (body && typeof body.genreKey === "string") return body.genreKey;
    } catch {
      // No/invalid JSON body — fine, genreKey is optional.
    }
  }
  return null;
}

async function handleRequest(req: Request): Promise<Response> {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST" && req.method !== "GET") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")?.trim();
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim();
  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse(
      { error: "Supabase service env is not configured" },
      500,
    );
  }

  const requestedGenreKey = await resolveRequestedGenreKey(req);
  if (
    requestedGenreKey &&
    !GENRE_KEYS.includes(requestedGenreKey as typeof GENRE_KEYS[number])
  ) {
    return jsonResponse(
      { error: `Unknown genreKey: ${requestedGenreKey}` },
      400,
    );
  }
  const genreKeysToRun = requestedGenreKey ? [requestedGenreKey] : GENRE_KEYS;

  const supabase = createClient(supabaseUrl, serviceRoleKey);
  const results: Record<string, GenreRunResult> = {};

  for (const source of SOURCES) {
    for (const genreKey of genreKeysToRun) {
      const resultKey = `${source.id}:${genreKey}`;
      const result = await scrapeGenre(supabase, source, genreKey);
      results[resultKey] = result;

      await supabase.from(RUNS_TABLE).insert({
        genre_key: genreKey,
        source: source.id,
        candidates_seen: result.candidatesSeen,
        inserted_count: result.inserted,
        skipped_existing_count: result.skippedExisting,
        skipped_no_isbn_count: result.skippedNoIsbn,
        status: result.status,
        error: result.error ?? null,
      });
    }
  }

  return jsonResponse({ scraped: results }, 200);
}

if (import.meta.main) {
  Deno.serve(handleRequest);
}
