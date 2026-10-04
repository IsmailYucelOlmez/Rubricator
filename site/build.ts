/**
 * Builds the static site into site/dist (git-ignored).
 *
 *   deno run --allow-read --allow-write --allow-env site/build.ts
 *
 * Optional environment:
 *   SITE_URL     absolute URL without trailing slash, e.g. https://rubricator.site
 *                or https://<user>.github.io/<repo>. Enables canonical/hreflang,
 *                og:image, sitemap.xml and an absolute-URL 404 page.
 *   SUPABASE_URL, SUPABASE_ANON_KEY
 *                public project URL and publishable key for the Virgil page. Without
 *                them the page builds but shows "not available".
 *   SITE_DOMAIN  custom domain (e.g. rubricator.site); writes the CNAME file
 *                GitHub Pages needs.
 *   SENTRY_DSN_WEB  Sentry DSN for the website (a separate project from the
 *                app). Enables error reporting on the pages that run code
 *                (static/js/monitoring.js). SENTRY_ENVIRONMENT (default
 *                "production") and SENTRY_RELEASE (default GITHUB_SHA) are
 *                optional.
 *   OUT_DIR      output directory (default site/dist).
 */
import { LANGS, outputPath, type PageRef, renderPage } from "./src/layout.ts";
import { fromFileUrl, resolve, toFileUrl } from "jsr:@std/path@1";
import { PAGES, privacyFragment } from "./src/pages.ts";

const root = new URL("./", import.meta.url);
const repoRoot = new URL("../", import.meta.url);
async function write(
  outDir: URL,
  relPath: string,
  data: string | Uint8Array,
) {
  const target = new URL(relPath, outDir);
  await Deno.mkdir(new URL("./", target), { recursive: true });
  if (typeof data === "string") await Deno.writeTextFile(target, data);
  else await Deno.writeFile(target, data);
}

async function copy(outDir: URL, from: URL, to: string) {
  await write(outDir, to, await Deno.readFile(from));
}

/** Wraps bare tables so they scroll sideways on narrow screens. */
const wrapTables = (html: string) =>
  html.replaceAll("<table>", '<div class="table-wrap"><table>')
    .replaceAll("</table>", "</table></div>");

export interface BuildOptions {
  /** Output directory (default: OUT_DIR env, else site/dist). */
  outPath?: string;
  /** Absolute site URL without trailing slash (default: SITE_URL env). */
  siteUrl?: string;
  /** Custom domain for the CNAME file (default: SITE_DOMAIN env). */
  siteDomain?: string;
  /** Supabase project URL (default: SUPABASE_URL env). */
  supabaseUrl?: string;
  /** Supabase publishable (anon) key (default: SUPABASE_ANON_KEY env). */
  supabaseAnonKey?: string;
  /** Sentry DSN for the website (default: SENTRY_DSN_WEB env). */
  sentryDsn?: string;
  /** Sentry release (default: SENTRY_RELEASE env, else GITHUB_SHA). */
  sentryRelease?: string;
}

export async function build(options: BuildOptions = {}) {
  const outPath = options.outPath ?? Deno.env.get("OUT_DIR") ??
    fromFileUrl(new URL("dist", root));
  const outDir = new URL(toFileUrl(resolve(outPath)).href + "/");
  const siteUrl = (options.siteUrl ?? Deno.env.get("SITE_URL"))?.replace(
    /\/+$/,
    "",
  ) || undefined;
  const siteDomain = (options.siteDomain ?? Deno.env.get("SITE_DOMAIN"))
    ?.trim() || undefined;

  const supabaseUrl =
    (options.supabaseUrl ?? Deno.env.get("SUPABASE_URL"))?.trim().replace(
      /\/+$/,
      "",
    ) || undefined;
  const supabaseAnonKey =
    (options.supabaseAnonKey ?? Deno.env.get("SUPABASE_ANON_KEY"))?.trim() ||
    undefined;
  // https only; plain http is accepted for a local mock/dev backend.
  if (
    supabaseUrl &&
    !/^(https:\/\/[^\s/]+|http:\/\/(localhost|127\.0\.0\.1)(:\d+)?)$/.test(
      supabaseUrl,
    )
  ) {
    throw new Error(
      "SUPABASE_URL must look like https://<project>.supabase.co",
    );
  }

  const sentryDsn =
    (options.sentryDsn ?? Deno.env.get("SENTRY_DSN_WEB"))?.trim() || undefined;
  if (sentryDsn && !/^https:\/\/[^\s@/]+@[^\s/]+\/\d+$/.test(sentryDsn)) {
    throw new Error("SENTRY_DSN_WEB must look like https://<key>@<host>/<id>");
  }
  const sentryRelease = (options.sentryRelease ??
    Deno.env.get("SENTRY_RELEASE") ?? Deno.env.get("GITHUB_SHA"))?.trim() ||
    undefined;
  const sentryEnvironment = Deno.env.get("SENTRY_ENVIRONMENT")?.trim() ||
    "production";

  try {
    await Deno.remove(outDir, { recursive: true });
  } catch { /* first build */ }

  for (const lang of LANGS) {
    privacyFragment[lang] = wrapTables(
      await Deno.readTextFile(
        new URL(`src/content/privacy-policy.${lang}.html`, root),
      ),
    );
  }

  const ctx = {
    pages: PAGES,
    siteUrl,
    supabaseUrl,
    supabaseAnonKey,
    sentry: sentryDsn
      ? { dsn: sentryDsn, environment: sentryEnvironment, release: sentryRelease }
      : undefined,
    year: new Date().getFullYear(),
  };
  const written: { page: PageRef; lang: string; file: string }[] = [];

  for (const page of PAGES) {
    for (const lang of LANGS) {
      if (outputPath(page, lang) === null) continue;
      const { file, html } = renderPage(page, lang, ctx);
      await write(outDir, file, html);
      written.push({ page, lang, file });
    }
  }

  // The old /privacy-policy/ URL keeps redirecting to /privacy-policy.html.
  await write(
    outDir,
    "privacy-policy/index.html",
    `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'none'">
  <meta http-equiv="refresh" content="0; url=../privacy-policy.html">
  <meta name="robots" content="noindex">
  <title>Privacy Policy | Rubricator</title>
  <link rel="canonical" href="${
      siteUrl ? siteUrl + "/privacy-policy.html" : "../privacy-policy.html"
    }">
</head>
<body>
  <p><a href="../privacy-policy.html">Privacy Policy</a></p>
</body>
</html>
`,
  );

  // Static assets.
  await copy(outDir, new URL("static/site.css", root), "assets/site.css");
  for await (const entry of Deno.readDir(new URL("static/fonts/", root))) {
    if (entry.isFile) {
      await copy(
        outDir,
        new URL(`static/fonts/${entry.name}`, root),
        `assets/fonts/${entry.name}`,
      );
    }
  }
  // Vendored third-party code (Sentry SDK + its licence), kept out of js/.
  for await (const entry of Deno.readDir(new URL("static/vendor/", root))) {
    if (entry.isFile) {
      await copy(
        outDir,
        new URL(`static/vendor/${entry.name}`, root),
        `assets/vendor/${entry.name}`,
      );
    }
  }
  for await (const entry of Deno.readDir(new URL("static/js/", root))) {
    if (entry.isFile && entry.name.endsWith(".js")) {
      await copy(
        outDir,
        new URL(`static/js/${entry.name}`, root),
        `assets/js/${entry.name}`,
      );
    }
  }
  await copy(
    outDir,
    new URL("web/icons/Icon-192.png", repoRoot),
    "img/icon-192.png",
  );
  await copy(
    outDir,
    new URL("web/icons/Icon-512.png", repoRoot),
    "img/icon-512.png",
  );
  await copy(outDir, new URL("web/favicon.png", repoRoot), "img/favicon.png");

  // Hosting files.
  await write(outDir, ".nojekyll", "");
  if (siteDomain) await write(outDir, "CNAME", siteDomain + "\n");
  await write(
    outDir,
    "robots.txt",
    `User-agent: *\nAllow: /\n${
      siteUrl ? `\nSitemap: ${siteUrl}/sitemap.xml\n` : ""
    }`,
  );

  if (siteUrl) {
    const urlOf = (file: string) =>
      `${siteUrl}/${file.replace(/(^|\/)index\.html$/, "$1")}`;
    const entries = written.filter(({ page }) => !page.noindex).map(
      ({ page, file }) => {
        const alternates = LANGS.flatMap((l) => {
          const f = outputPath(page, l);
          return f
            ? [
              `    <xhtml:link rel="alternate" hreflang="${l}" href="${
                urlOf(f)
              }"/>`,
            ]
            : [];
        }).join("\n");
        return `  <url>\n    <loc>${
          urlOf(file)
        }</loc>\n${alternates}\n  </url>`;
      },
    );
    await write(
      outDir,
      "sitemap.xml",
      `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xhtml="http://www.w3.org/1999/xhtml">\n${
        entries.join("\n")
      }\n</urlset>\n`,
    );
  }

  return { written: written.map((w) => w.file), outDir };
}

if (import.meta.main) {
  const { written, outDir: out } = await build();
  console.log(`built ${written.length} pages into ${out.pathname}`);
  for (const f of written) console.log("  " + f);
}
