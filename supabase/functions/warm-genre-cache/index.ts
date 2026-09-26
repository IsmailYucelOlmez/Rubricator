import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { isServiceRequest } from "../_shared/service_auth.ts";

const GOOGLE_BOOKS_BASE = "https://www.googleapis.com/books/v1";
const TABLE = "genre_books_cache";
const MAX_RESULTS = 15;
/// Larger request size for non-English langs, so there's still a healthy
/// pool left after `filterByLanguage` discards items Google mistakenly
/// included despite `langRestrict`.
const FETCH_POOL_SIZE = 40;

const GENRE_KEYS = [
  "popular_fiction",
  "fantasy",
  "science_fiction",
  "romance",
  "mystery",
  "thriller",
  "horror",
] as const;

const LANGS = ["en", "tr"] as const;

/// Google Books' `subject:` taxonomy is effectively English-only (LCSH-style
/// headings), so `subject:fantasy&langRestrict=tr` still matches the same
/// English catalog and `langRestrict` quietly fails to narrow it down —
/// Turkish genre rows end up identical to the English ones. Anding the
/// English subject with the Turkish genre word as a plain keyword (below)
/// keeps genre precision while biasing toward actually-Turkish matches;
/// `filterByLanguage` then double-checks each result's own language field.
///
/// A bare Turkish keyword alone (no `subject:` anchor) was tried first and
/// made results *worse*, not better: single generic words like "roman" or
/// "korku" match Google's full-text index broadly (any book that merely
/// mentions the word), pulling in unrelated non-fiction, dictionaries, and
/// books about unrelated senses of the word (e.g. "roman" ~ "Roman/Romani").
const TURKISH_GENRE_QUERIES: Record<string, string> = {
  popular_fiction: "roman",
  fantasy: "fantastik",
  science_fiction: "bilim kurgu",
  romance: "aşk romanı",
  mystery: "polisiye",
  thriller: "gerilim",
  horror: "korku",
};

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

type CachedBook = {
  id: string;
  title: string;
  cover_image_url: string | null;
  author_names: string;
  languages: string[];
  categories: string[];
};

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function subjectQueryTerm(genreKey: string): string {
  return genreKey.trim().replaceAll('"', " ").replaceAll("_", " ");
}

function buildSubjectQuery(subject: string): string {
  const s = subject.trim().replaceAll('"', " ");
  if (!s) return "";
  return `subject:${s.includes(" ") ? `"${s}"` : s}`;
}

function httpsThumbnail(imageLinks: Record<string, unknown> | undefined): string | null {
  if (!imageLinks) return null;
  const raw = (imageLinks.thumbnail ?? imageLinks.smallThumbnail) as string | undefined;
  if (!raw || !raw.trim()) return null;
  return raw.replace(/^http:/, "https:");
}

function parseVolume(item: Record<string, unknown>): CachedBook | null {
  const id = typeof item.id === "string" ? item.id.trim() : "";
  const volumeInfo = (item.volumeInfo ?? {}) as Record<string, unknown>;
  const titleRaw = typeof volumeInfo.title === "string" ? volumeInfo.title.trim() : "";
  const authors = volumeInfo.authors;
  let authorNames = "Unknown author";
  if (Array.isArray(authors) && authors.length > 0) {
    const first = authors[0];
    if (typeof first === "string" && first.trim()) authorNames = first.trim();
  }
  const lang = typeof volumeInfo.language === "string"
    ? volumeInfo.language.trim().toLowerCase()
    : "";
  const categoriesRaw = volumeInfo.categories;
  const categories = Array.isArray(categoriesRaw)
    ? categoriesRaw.filter((c): c is string => typeof c === "string" && c.trim().length > 0)
    : [];

  if (!id) return null;
  return {
    id,
    title: titleRaw || "Unknown title",
    cover_image_url: httpsThumbnail(volumeInfo.imageLinks as Record<string, unknown> | undefined),
    author_names: authorNames,
    languages: lang ? [lang] : [],
    categories,
  };
}

/// Keeps only books whose own `volumeInfo.language` actually matches [lang]
/// — `langRestrict` alone isn't trustworthy for subject-taxonomy queries, so
/// this is the real language gate. Falls back to the unfiltered list only if
/// filtering would empty it out entirely (better a few off-language results
/// than a permanently-erroring cache row).
function filterByLanguage(books: CachedBook[], lang: string): CachedBook[] {
  const relevant = books.filter((b) =>
    b.languages.some((l) => l.startsWith(lang))
  );
  return relevant.length > 0 ? relevant : books;
}

async function fetchGoogleBooks(
  apiKey: string,
  q: string,
  lang: string,
): Promise<CachedBook[]> {
  const requestSize = lang === "en" ? MAX_RESULTS : FETCH_POOL_SIZE;
  const url = new URL(`${GOOGLE_BOOKS_BASE}/volumes`);
  url.searchParams.set("q", q);
  url.searchParams.set("printType", "books");
  url.searchParams.set("langRestrict", lang);
  url.searchParams.set("maxResults", String(requestSize));
  url.searchParams.set("key", apiKey);

  const upstream = await fetch(url.toString(), {
    headers: { Accept: "application/json" },
  });
  if (!upstream.ok) {
    throw new Error(`Google Books ${upstream.status}: ${await upstream.text()}`);
  }

  const json = await upstream.json() as { items?: unknown[] };
  const items = Array.isArray(json.items) ? json.items : [];
  const books: CachedBook[] = [];
  for (const item of items) {
    if (item && typeof item === "object") {
      const parsed = parseVolume(item as Record<string, unknown>);
      if (parsed) books.push(parsed);
    }
  }
  return filterByLanguage(books, lang).slice(0, MAX_RESULTS);
}

function queryForGenreKey(genreKey: string, lang: string): string {
  const englishSubject = genreKey === "popular_fiction"
    ? "fiction"
    : subjectQueryTerm(genreKey);
  const subjectQuery = buildSubjectQuery(englishSubject);
  const turkishTerm = TURKISH_GENRE_QUERIES[genreKey];
  if (lang === "tr" && turkishTerm) {
    return `${subjectQuery} ${turkishTerm}`;
  }
  return subjectQuery;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST" && req.method !== "GET") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  // Runs with the service role and is only meant for pg_cron / admins: without
  // this check anyone on the internet could trigger it (verify_jwt is off).
  if (!isServiceRequest(req, Deno.env)) {
    return jsonResponse({ error: "unauthorized" }, 401);
  }

  const apiKey = Deno.env.get("GOOGLE_BOOKS_API_KEY")?.trim();
  const supabaseUrl = Deno.env.get("SUPABASE_URL")?.trim();
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim();

  if (!apiKey) {
    return jsonResponse({ error: "GOOGLE_BOOKS_API_KEY is not configured" }, 500);
  }
  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse({ error: "Supabase service env is not configured" }, 500);
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);
  const results: Record<string, { status: string; count?: number; error?: string }> = {};

  for (const genreKey of GENRE_KEYS) {
    for (const lang of LANGS) {
      const resultKey = `${genreKey}:${lang}`;
      try {
        const books = await fetchGoogleBooks(apiKey, queryForGenreKey(genreKey, lang), lang);
        if (books.length === 0) {
          throw new Error(`No books returned for ${genreKey} (${lang})`);
        }

        const { error } = await supabase.from(TABLE).upsert({
          genre_key: genreKey,
          lang,
          books_json: books,
          total_count: books.length,
          last_fetch_at: new Date().toISOString(),
          last_fetch_status: "success",
          last_fetch_error: null,
          fetch_completed: true,
          is_active: true,
        }, { onConflict: "genre_key,lang" });

        if (error) throw error;
        results[resultKey] = { status: "success", count: books.length };
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        results[resultKey] = { status: "error", error: message };
        await supabase.from(TABLE).upsert({
          genre_key: genreKey,
          lang,
          last_fetch_at: new Date().toISOString(),
          last_fetch_status: "error",
          last_fetch_error: message,
          fetch_completed: false,
          is_active: true,
        }, { onConflict: "genre_key,lang" });
      }
    }
  }

  return jsonResponse({ warmed: results }, 200);
});
