/**
 * Shared page shell for the static site: <head> (CSP, SEO, hreflang), header,
 * footer. JavaScript only on pages that declare scripts (Virgil); every URL is relative so the same output works
 * under a project path (github.io/bookapp/) and on a custom domain root.
 */
export type Lang = "en" | "tr";
export const LANGS: Lang[] = ["en", "tr"];

/** Public contact address (also used in the privacy policy). */
export const CONTACT_EMAIL = "support@rubricator.site";

/**
 * Version of the privacy policy, recorded with each web sign-up. Must equal the
 * "Last updated" date of the policy (a test checks this).
 */
export const PRIVACY_POLICY_VERSION = "2026-10-03";

export interface PageRef {
  /** Stable id used for cross-language links. */
  id: string;
  /** Output directory per language ("" = site root), no leading/trailing slash. */
  dir: Partial<Record<Lang, string>>;
  title: Record<Lang, string>;
  description: Record<Lang, string>;
  /** Trusted HTML for <main>. */
  body: (lang: Lang, ctx: BuildContext) => string;
  /**
   * Scripts (published paths, loaded as ES modules). Pages with scripts get a
   * CSP that allows them plus requests to the Supabase project and https images.
   */
  scripts?: string[];
  /** Flat file instead of <dir>/index.html (e.g. "privacy-policy.html", "404.html"). */
  file?: Partial<Record<Lang, string>>;
  /** Show in the header navigation. */
  nav?: boolean;
  noindex?: boolean;
}

/** Where a page lives in the output, e.g. "tr/hakkimizda/index.html". */
export function outputPath(page: PageRef, lang: Lang): string | null {
  const flat = page.file?.[lang];
  if (flat) return flat;
  const dir = page.dir[lang];
  if (dir === undefined) return null;
  const prefix = lang === "tr" ? "tr/" : "";
  const path = `${prefix}${dir}`.replace(/\/$/, "");
  return path === "" ? "index.html" : `${path}/index.html`;
}

/** Relative URL from one output file to another ("../tr/about/"). */
export function relativeUrl(fromFile: string, toFile: string): string {
  const fromDir = fromFile.split("/").slice(0, -1);
  const toParts = toFile.split("/");
  let common = 0;
  while (
    common < fromDir.length && common < toParts.length - 1 &&
    fromDir[common] === toParts[common]
  ) common++;
  const up = "../".repeat(fromDir.length - common);
  const rest = toParts.slice(common).join("/");
  // Link to directories, not to their index.html.
  const pretty = rest.replace(/(^|\/)index\.html$/, "$1");
  const url = up + pretty;
  return url === "" ? "./" : url;
}

const UI = {
  en: {
    skip: "Skip to content",
    home: "Home",
    virgil: "Virgil",
    about: "About",
    contact: "Contact",
    privacy: "Privacy Policy",
    deletion: "Account deletion",
    switchTo: "Türkçe",
    switchLabel: "Bu sayfayı Türkçe oku",
    navLabel: "Main",
    footerNav: "Footer",
    rights: "All rights reserved.",
    tagline: "Book discovery, reading tracking and AI recommendations.",
  },
  tr: {
    skip: "İçeriğe geç",
    home: "Ana sayfa",
    virgil: "Virgil",
    about: "Hakkımızda",
    contact: "İletişim",
    privacy: "Gizlilik Politikası",
    deletion: "Hesap silme",
    switchTo: "English",
    switchLabel: "Read this page in English",
    navLabel: "Ana menü",
    footerNav: "Alt menü",
    rights: "Tüm hakları saklıdır.",
    tagline: "Kitap keşfi, okuma takibi ve yapay zekâ önerileri.",
  },
} as const;

export interface BuildContext {
  pages: PageRef[];
  /** Absolute site URL (no trailing slash); enables canonical/OG/sitemap. */
  siteUrl?: string;
  /** Supabase project URL and publishable key for the Virgil page (both public). */
  supabaseUrl?: string;
  supabaseAnonKey?: string;
  year: number;
}

const escapeAttr = (s: string) =>
  s.replaceAll("&", "&amp;").replaceAll('"', "&quot;").replaceAll("<", "&lt;");

/**
 * The CSP is delivered by <meta> because GitHub Pages can't set headers. Plain
 * pages forbid scripts, frames, forms and any off-site resource. Pages with
 * scripts may run only their own files, talk only to the Supabase project and
 * show https images (book covers come from several catalogs).
 */
function contentSecurityPolicy(page: PageRef, ctx: BuildContext): string {
  const interactive = (page.scripts?.length ?? 0) > 0;
  const connect = ctx.supabaseUrl ? new URL(ctx.supabaseUrl).origin : "'none'";
  return [
    "default-src 'none'",
    interactive ? "img-src 'self' data: https:" : "img-src 'self' data:",
    "style-src 'self'",
    "font-src 'self'",
    ...(interactive ? ["script-src 'self'", `connect-src ${connect}`] : []),
    "base-uri 'self'",
    "form-action 'none'",
  ].join("; ");
}

export function renderPage(
  page: PageRef,
  lang: Lang,
  ctx: BuildContext,
): { file: string; html: string } {
  const file = outputPath(page, lang);
  if (file === null) throw new Error(`${page.id} has no ${lang} version`);
  const ui = UI[lang];
  // GitHub Pages serves 404.html for missing paths at ANY depth, so relative
  // URLs would break there; use absolute ones when the site URL is known.
  const rel = (to: string) =>
    page.id === "notfound" && ctx.siteUrl
      ? `${ctx.siteUrl}/${to.replace(/(^|\/)index\.html$/, "$1")}`
      : relativeUrl(file, to);
  const home = outputPath(ctx.pages.find((p) => p.id === "home")!, lang)!;

  // {{link:<page id>[:<lang>]}} -> URL of that page (English if it has no translation);
  // {{asset:<path>}} -> URL of a static file.
  const body = page.body(lang, ctx).replace(
    /\{\{(link|asset):([^}]+)\}\}/g,
    (_match, kind: string, arg: string) => {
      if (kind === "asset") return rel(arg);
      // "{{link:privacy:en}}" pins the target language.
      const [id, pinned] = arg.split(":");
      const target = ctx.pages.find((p) => p.id === id);
      const path = target
        ? (pinned
          ? outputPath(target, pinned as Lang)
          : (outputPath(target, lang) ?? outputPath(target, "en")))
        : null;
      if (!path) {
        throw new Error(`Unresolved link "${arg}" on ${page.id}/${lang}`);
      }
      return rel(path);
    },
  );

  const navLinks = ctx.pages.filter((p) => p.nav && outputPath(p, lang)).map(
    (p) => {
      const target = outputPath(p, lang)!;
      const current = p.id === page.id ? ' aria-current="page"' : "";
      return `<a href="${rel(target)}"${current}>${
        ui[p.id as "home" | "virgil" | "about" | "contact"]
      }</a>`;
    },
  ).join("\n        ");

  // Language switch: the same page in the other language, else that language's home.
  const other: Lang = lang === "en" ? "tr" : "en";
  const otherPage = outputPath(page, other);
  const switchTarget = otherPage ?? outputPath(
    ctx.pages.find((p) => p.id === "home")!,
    other,
  )!;

  const alternates = LANGS.map((l) => {
    const p = outputPath(page, l);
    return p && ctx.siteUrl
      ? `<link rel="alternate" hreflang="${l}" href="${ctx.siteUrl}/${
        p.replace(/(^|\/)index\.html$/, "$1")
      }">`
      : "";
  }).filter(Boolean).join("\n  ");

  const canonical = ctx.siteUrl
    ? `<link rel="canonical" href="${ctx.siteUrl}/${
      file.replace(/(^|\/)index\.html$/, "$1")
    }">`
    : "";
  const ogImage = ctx.siteUrl ? `${ctx.siteUrl}/img/icon-512.png` : "";
  const og = [
    `<meta property="og:type" content="website">`,
    `<meta property="og:site_name" content="Rubricator">`,
    `<meta property="og:title" content="${escapeAttr(page.title[lang])}">`,
    `<meta property="og:description" content="${
      escapeAttr(page.description[lang])
    }">`,
    `<meta property="og:locale" content="${
      lang === "tr" ? "tr_TR" : "en_US"
    }">`,
    ogImage ? `<meta property="og:image" content="${ogImage}">` : "",
    `<meta name="twitter:card" content="summary">`,
  ].filter(Boolean).join("\n  ");

  const footerLinks = [
    [ui.about, ctx.pages.find((p) => p.id === "about")],
    [ui.contact, ctx.pages.find((p) => p.id === "contact")],
    [ui.privacy, ctx.pages.find((p) => p.id === "privacy")],
    [ui.deletion, ctx.pages.find((p) => p.id === "deletion")],
  ].flatMap(([label, p]) => {
    if (!p) return [];
    const own = outputPath(p as PageRef, lang);
    // A page without a translation (e.g. the privacy policy) falls back to English.
    const target = own ?? outputPath(p as PageRef, "en");
    if (!target) return [];
    const marker = own ? "" : ' hreflang="en" lang="en"';
    return [`<a href="${rel(target)}"${marker}>${label}</a>`];
  }).join("\n        ");

  const scriptTags = (page.scripts ?? []).map((src) => `
  <script type="module" src="${rel(src)}"></script>`).join("");

  const html = `<!doctype html>
<html lang="${lang}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta http-equiv="Content-Security-Policy" content="${
    contentSecurityPolicy(page, ctx)
  }">
  <meta name="referrer" content="strict-origin-when-cross-origin">
  <title>${page.title[lang]}</title>
  <meta name="description" content="${escapeAttr(page.description[lang])}">
  <meta name="theme-color" content="#ba181b">
  ${page.noindex ? '<meta name="robots" content="noindex">' : ""}
  ${canonical}
  ${alternates}
  ${og}
  <link rel="icon" href="${rel("img/favicon.png")}" type="image/png">
  <link rel="apple-touch-icon" href="${rel("img/icon-192.png")}">
  <link rel="stylesheet" href="${rel("assets/site.css")}">
</head>
<body>
  <a class="skip-link" href="#content">${ui.skip}</a>
  <header class="site-header">
    <div class="container">
      <a class="brand" href="${rel(home)}">
        <img src="${rel("img/icon-192.png")}" width="40" height="40" alt="">
        <span class="brand-name">Rubricator</span>
      </a>
      <nav class="nav" aria-label="${ui.navLabel}">
        ${navLinks}
      </nav>
      <a class="lang-switch" href="${
    rel(switchTarget)
  }" hreflang="${other}" lang="${other}" aria-label="${ui.switchLabel}">${ui.switchTo}</a>
    </div>
  </header>
  <main id="content">
${body}
  </main>${scriptTags}
  <footer class="site-footer">
    <div class="container">
      <span>© ${ctx.year} Rubricator. ${ui.rights}</span>
      <nav aria-label="${ui.footerNav}">
        ${footerLinks}
      </nav>
    </div>
  </footer>
</body>
</html>
`;
  return { file, html };
}
