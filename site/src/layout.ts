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
export const PRIVACY_POLICY_VERSION = "2026-10-04";

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
    themeLabel: "Dark theme",
    navLabel: "Main",
    footerNav: "Footer",
    rights: "All rights reserved.",
    getOnPlay: "Get it on Google Play",
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
    themeLabel: "Koyu tema",
    navLabel: "Ana menü",
    footerNav: "Alt menü",
    rights: "Tüm hakları saklıdır.",
    getOnPlay: "Google Play'den indir",
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
  /** Website error reporting; only the pages with scripts load it. */
  sentry?: { dsn: string; environment: string; release?: string };
  year: number;
}

/**
 * Flags for the language switch (the flag of the language the link leads to).
 * Inline SVG: no image request, and flag colours are fixed by design, so they
 * are the one place with literal colours outside the CSS tokens.
 */
const FLAGS: Record<Lang, string> = {
  tr:
    '<svg class="flag" viewBox="0 0 30 20" aria-hidden="true"><rect width="30" height="20" fill="#E30A17"/><circle cx="10.625" cy="10" r="5" fill="#fff"/><circle cx="11.875" cy="10" r="4" fill="#E30A17"/><path fill="#fff" d="M14.583 10l4.523 1.469-2.795-3.847v4.756l2.795-3.847z"/></svg>',
  en:
    '<svg class="flag" viewBox="0 0 60 30" aria-hidden="true"><clipPath id="flag-uk"><path d="M30 15h30v15zv15H0zH0V0zV0h30z"/></clipPath><path d="M0 0v30h60V0z" fill="#012169"/><path d="M0 0l60 30m0-30L0 30" stroke="#fff" stroke-width="6"/><path d="M0 0l60 30m0-30L0 30" clip-path="url(#flag-uk)" stroke="#C8102E" stroke-width="4"/><path d="M30 0v30M0 15h60" stroke="#fff" stroke-width="10"/><path d="M30 0v30M0 15h60" stroke="#C8102E" stroke-width="6"/></svg>',
};

/** Sun (shown in dark theme) and moon (shown in light); CSS picks one. */
const THEME_ICONS =
  '<svg class="i-moon" viewBox="0 0 24 24" aria-hidden="true"><path d="M20 14.5A8 8 0 0 1 9.5 4 8 8 0 1 0 20 14.5z"/></svg><svg class="i-sun" viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4"/></svg>';

/** The app's store page (Android only so far). */
export const PLAY_STORE_URL =
  "https://play.google.com/store/apps/details?id=com.rubricator";

const escapeAttr = (s: string) =>
  s.replaceAll("&", "&amp;").replaceAll('"', "&quot;").replaceAll("<", "&lt;");

/**
 * The CSP is delivered by <meta> because GitHub Pages can't set headers. Every
 * page may run only the site's own script files (theme.js everywhere); plain
 * pages forbid frames, forms and any off-site resource. Pages with scripts may
 * also talk to the Supabase project and show https images (book covers come
 * from several catalogs).
 */
/** The Supabase project and, when configured, Sentry's ingest host. */
function connectSources(ctx: BuildContext): string {
  const origins = [
    ...(ctx.supabaseUrl ? [new URL(ctx.supabaseUrl).origin] : []),
    ...(ctx.sentry ? [new URL(ctx.sentry.dsn).origin] : []),
  ];
  return origins.length ? origins.join(" ") : "'none'";
}

function contentSecurityPolicy(page: PageRef, ctx: BuildContext): string {
  const interactive = (page.scripts?.length ?? 0) > 0;
  return [
    "default-src 'none'",
    interactive ? "img-src 'self' data: https:" : "img-src 'self' data:",
    "style-src 'self'",
    "font-src 'self'",
    "script-src 'self'",
    ...(interactive ? [`connect-src ${connectSources(ctx)}`] : []),
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

  // Error reporting goes first, so it is listening before the page's code runs.
  const sentry = (page.scripts?.length ?? 0) > 0 ? ctx.sentry : undefined;
  const scripts = [
    ...(sentry ? ["assets/js/monitoring.js"] : []),
    ...(page.scripts ?? []),
  ];
  const scriptTags = scripts.map((src) => `
  <script type="module" src="${rel(src)}"></script>`).join("");
  const sentryMeta = sentry
    ? `
  <meta name="sentry-dsn" content="${escapeAttr(sentry.dsn)}">
  <meta name="sentry-environment" content="${escapeAttr(sentry.environment)}">${
      sentry.release
        ? `
  <meta name="sentry-release" content="${escapeAttr(sentry.release)}">`
        : ""
    }`
    : "";

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
  <meta name="theme-color" content="#ba181b">${sentryMeta}
  ${page.noindex ? '<meta name="robots" content="noindex">' : ""}
  ${canonical}
  ${alternates}
  ${og}
  <link rel="icon" href="${rel("img/favicon.png")}" type="image/png">
  <link rel="apple-touch-icon" href="${rel("img/icon-192.png")}">
  <link rel="stylesheet" href="${rel("assets/site.css")}">
  <script src="${rel("assets/js/theme.js")}"></script>
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
  }" hreflang="${other}" lang="${other}" aria-label="${ui.switchLabel}" title="${ui.switchTo}">${
    FLAGS[other]
  }</a>
      <button class="theme-toggle" id="theme-toggle" type="button" aria-pressed="false" aria-label="${ui.themeLabel}" title="${ui.themeLabel}" hidden>${THEME_ICONS}</button>
    </div>
  </header>
  <main id="content">
${body}
  </main>${scriptTags}
  <footer class="site-footer">
    <div class="container">
      <div class="footer-meta">
        <span>© ${ctx.year} Rubricator. ${ui.rights}</span>
        <a class="footer-store" href="${PLAY_STORE_URL}" rel="noopener"><svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 3v12M7 10l5 5 5-5M5 21h14"/></svg>${ui.getOnPlay}</a>
      </div>
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
