import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const GOOGLE_BOOKS_BASE = "https://www.googleapis.com/books/v1";
const TABLE = "genre_books_cache";
const MAX_RESULTS = 15;

const GENRE_KEYS = [
  "popular_fiction",
  "fantasy",
  "science_fiction",
  "romance",
  "mystery",
  "thriller",
  "horror",
] as const;

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

async function fetchGoogleBooks(
  apiKey: string,
  q: string,
): Promise<CachedBook[]> {
  const url = new URL(`${GOOGLE_BOOKS_BASE}/volumes`);
  url.searchParams.set("q", q);
  url.searchParams.set("printType", "books");
  url.searchParams.set("maxResults", String(MAX_RESULTS));
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
  return books;
}

function queryForGenreKey(genreKey: string): string {
  if (genreKey === "popular_fiction") {
    return buildSubjectQuery("fiction");
  }
  return buildSubjectQuery(subjectQueryTerm(genreKey));
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST" && req.method !== "GET") {
    return jsonResponse({ error: "Method not allowed" }, 405);
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
    try {
      const books = await fetchGoogleBooks(apiKey, queryForGenreKey(genreKey));
      if (books.length === 0) {
        throw new Error(`No books returned for ${genreKey}`);
      }

      const { error } = await supabase.from(TABLE).upsert({
        genre_key: genreKey,
        books_json: books,
        total_count: books.length,
        last_fetch_at: new Date().toISOString(),
        last_fetch_status: "success",
        last_fetch_error: null,
        fetch_completed: true,
        is_active: true,
      });

      if (error) throw error;
      results[genreKey] = { status: "success", count: books.length };
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      results[genreKey] = { status: "error", error: message };
      await supabase.from(TABLE).upsert({
        genre_key: genreKey,
        last_fetch_at: new Date().toISOString(),
        last_fetch_status: "error",
        last_fetch_error: message,
        fetch_completed: false,
        is_active: true,
      });
    }
  }

  return jsonResponse({ warmed: results }, 200);
});
