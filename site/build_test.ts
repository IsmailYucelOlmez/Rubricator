import { assert, assertEquals, assertMatch } from "jsr:@std/assert@1";
import { dirname, join, normalize } from "jsr:@std/path@1";

import { build } from "./build.ts";
import { outputPath, relativeUrl } from "./src/layout.ts";
import { PAGES } from "./src/pages.ts";

const SITE_URL = "https://example.github.io/bookapp";

async function buildTo(
  options: { siteUrl?: string; siteDomain?: string } = {},
) {
  const dir = await Deno.makeTempDir({ prefix: "site-test-" });
  // Empty strings (not undefined) so the developer's environment never leaks in.
  await build({
    outPath: dir,
    supabaseUrl: "",
    supabaseAnonKey: "",
    ...options,
  });
  return dir;
}

async function walk(dir: string, base = dir): Promise<string[]> {
  const out: string[] = [];
  for await (const e of Deno.readDir(dir)) {
    const full = join(dir, e.name);
    if (e.isDirectory) out.push(...await walk(full, base));
    else out.push(full.slice(base.length + 1).replaceAll("\\", "/"));
  }
  return out;
}

const htmlFiles = (files: string[]) => files.filter((f) => f.endsWith(".html"));

// --- relativeUrl ------------------------------------------------------------

Deno.test("relativeUrl links directories and works from any depth", () => {
  assertEquals(relativeUrl("index.html", "about/index.html"), "about/");
  assertEquals(relativeUrl("index.html", "index.html"), "./");
  assertEquals(relativeUrl("about/index.html", "index.html"), "../");
  assertEquals(
    relativeUrl("tr/hakkimizda/index.html", "about/index.html"),
    "../../about/",
  );
  assertEquals(relativeUrl("tr/hakkimizda/index.html", "tr/index.html"), "../");
  assertEquals(
    relativeUrl("tr/index.html", "tr/iletisim/index.html"),
    "iletisim/",
  );
  assertEquals(
    relativeUrl("about/index.html", "privacy-policy.html"),
    "../privacy-policy.html",
  );
  assertEquals(
    relativeUrl("tr/hakkimizda/index.html", "assets/site.css"),
    "../../assets/site.css",
  );
  assertEquals(
    relativeUrl("privacy-policy.html", "img/favicon.png"),
    "img/favicon.png",
  );
});

// --- structure --------------------------------------------------------------

Deno.test("every page, static asset and hosting file is emitted", async () => {
  const dir = await buildTo();
  const files = await walk(dir);
  for (
    const f of [
      "index.html",
      "tr/index.html",
      "about/index.html",
      "tr/hakkimizda/index.html",
      "contact/index.html",
      "tr/iletisim/index.html",
      "privacy-policy.html",
      "privacy-policy/index.html",
      "account-deletion/index.html",
      "tr/hesap-silme/index.html",
      "404.html",
      "assets/site.css",
      "img/favicon.png",
      "img/icon-192.png",
      "img/icon-512.png",
      "robots.txt",
      ".nojekyll",
      "assets/fonts/Outfit-Regular.woff2",
      "assets/fonts/Nouveau-Regular.woff2",
      "assets/fonts/OFL-Outfit.txt",
      "assets/fonts/OFL-DT-Nouveau.txt",
    ]
  ) assert(files.includes(f), `missing ${f}`);
  // The URLs registered in Play Console before the redesign keep working.
  assert(
    files.includes("privacy-policy.html") &&
      files.includes("account-deletion/index.html"),
  );
});

Deno.test("every relative href/src resolves to a file in the output", async () => {
  const dir = await buildTo();
  const files = new Set(await walk(dir));
  const problems: string[] = [];
  for (const page of htmlFiles([...files])) {
    const html = await Deno.readTextFile(join(dir, page));
    for (const m of html.matchAll(/\b(?:href|src)="([^"]*)"/g)) {
      const url = m[1];
      if (url === "#" || url.startsWith("#") || url.startsWith("mailto:")) {
        continue;
      }
      if (/^https?:\/\//.test(url)) continue; // external: checked in another test
      if (url.startsWith("/")) {
        problems.push(`${page}: root-absolute "${url}"`);
        continue;
      }
      const path = normalize(join(dirname(page), url.split(/[?#]/)[0]))
        .replaceAll("\\", "/");
      if (path.startsWith("..")) {
        problems.push(`${page}: "${url}" escapes the site`);
        continue;
      }
      const target = path === "." || path.endsWith("/")
        ? `${path.replace(/\/$/, "")}/index.html`.replace(/^\.\//, "").replace(
          /^\//,
          "",
        )
        : path;
      const candidates = [target, path, `${path}/index.html`].map((c) =>
        c.replace(/^\.\//, "")
      );
      if (!candidates.some((c) => files.has(c))) {
        problems.push(`${page}: "${url}" -> ${candidates[0]} not found`);
      }
    }
  }
  assertEquals(problems, []);
});

Deno.test("only the privacy policy's own third-party links point off-site", async () => {
  const dir = await buildTo();
  const hosts = new Set<string>();
  for (const page of htmlFiles(await walk(dir))) {
    const html = await Deno.readTextFile(join(dir, page));
    for (const m of html.matchAll(/\b(?:href|src)="(https?:\/\/[^"]+)"/g)) {
      hosts.add(new URL(m[1]).host);
    }
  }
  assertEquals([...hosts].sort(), [
    "play.google.com", // the landing page's "Get the Android app" button
    "policies.google.com",
    "resend.com", // privacy policy: contact-form email provider
    "sentry.io",
    "supabase.com",
  ]);
});

// --- per-page hygiene -------------------------------------------------------

Deno.test("each page: lang, unique title/description, one h1, CSP, no scripts, no inline styles", async () => {
  const dir = await buildTo();
  const titles = new Map<string, string>();
  const descriptions = new Map<string, string>();
  for (const file of htmlFiles(await walk(dir))) {
    if (file === "privacy-policy/index.html") continue; // redirect stub
    const html = await Deno.readTextFile(join(dir, file));
    const lang = file.startsWith("tr/") ? "tr" : "en";
    assertMatch(html, new RegExp(`<html lang="${lang}">`), file);
    const title = html.match(/<title>([^<]+)<\/title>/)?.[1] ?? "";
    const desc =
      html.match(/<meta name="description" content="([^"]*)"/)?.[1] ?? "";
    assert(
      title.length > 5 && title.length <= 90,
      `${file}: title length ${title.length}`,
    );
    assert(
      desc.length >= 10 && desc.length <= 200,
      `${file}: description length ${desc.length}`,
    );
    assert(
      !titles.has(title),
      `${file}: title duplicates ${titles.get(title)}`,
    );
    assert(
      !descriptions.has(desc),
      `${file}: description duplicates ${descriptions.get(desc)}`,
    );
    titles.set(title, file);
    descriptions.set(desc, file);
    assertEquals(
      (html.match(/<h1[\s>]/g) ?? []).length,
      1,
      `${file}: h1 count`,
    );
    assertMatch(
      html,
      /http-equiv="Content-Security-Policy" content="default-src 'none'/,
      file,
    );
    // Only pages that need it run code: one module script plus a JSON data block.
    const interactive =
      /(^|\/)(virgil|contact|iletisim|auth\/(confirmed|onay))\/index\.html$/
      .test(file);
    const scripts = html.match(/<script[^>]*>/gi) ?? [];
    assertEquals(scripts.length, interactive ? 2 : 0, `${file}: script count`);
    assert(
      scripts.every((tag) =>
        /^<script type="(module" src="[^"]+"|application\/json" id="i18n")>$/
          .test(tag)
      ),
      `${file}: unexpected script tag ${scripts.join(" ")}`,
    );
    assertEquals(/script-src/.test(html), interactive, `${file}: script-src`);
    assert(
      !/<style/i.test(html) && !/\sstyle="/i.test(html),
      `${file}: inline style (blocked by CSP)`,
    );
    assert(!/\son[a-z]+="/i.test(html), `${file}: inline event handler`);
    assertMatch(html, /<a class="skip-link" href="#content">/, file);
    assertMatch(html, /<main id="content">/, file);
    assert(
      !/(undefined|\[object Object\]|\{\{)/.test(html),
      `${file}: unresolved template text`,
    );
  }
});

Deno.test("the language switch always leads somewhere valid", async () => {
  const dir = await buildTo();
  const files = new Set(await walk(dir));
  for (const file of htmlFiles([...files])) {
    if (file === "privacy-policy/index.html") continue;
    const html = await Deno.readTextFile(join(dir, file));
    const href = html.match(/class="lang-switch" href="([^"]+)"/)?.[1];
    assert(href, `${file}: no language switch`);
    const target = normalize(join(dirname(file), href)).replaceAll("\\", "/")
      .replace(/\/$/, "");
    assert(
      files.has(`${target}/index.html`) || files.has(target) ||
        target === "." && files.has("index.html"),
      `${file}: switch -> ${href}`,
    );
  }
});

Deno.test("Turkish pages link to the Turkish privacy policy, which points back to the English text", async () => {
  const dir = await buildTo();
  const home = await Deno.readTextFile(join(dir, "tr/index.html"));
  assertMatch(home, /href="gizlilik-politikasi\/">Gizlilik Politikası</);
  assert(
    !/hreflang="en" lang="en">Gizlilik/.test(home),
    "footer must not mark the policy as English",
  );

  const tr = await Deno.readTextFile(
    join(dir, "tr/gizlilik-politikasi/index.html"),
  );
  assertMatch(tr, /<html lang="tr">/);
  assertMatch(tr, /<h1>Rubricator Gizlilik Politikası<\/h1>/);
  assertMatch(
    tr,
    /href="\.\.\/\.\.\/privacy-policy\.html" hreflang="en" lang="en">İngilizce metin</,
  );
  assertMatch(
    tr,
    /class="lang-switch" href="\.\.\/\.\.\/privacy-policy\.html"/,
  );
  assertEquals(
    (tr.match(/<table>/g) ?? []).length,
    (tr.match(/<div class="table-wrap"><table>/g) ?? []).length,
  );

  const en = await Deno.readTextFile(join(dir, "privacy-policy.html"));
  assertMatch(en, /class="lang-switch" href="tr\/gizlilik-politikasi\/"/);
});

Deno.test("the Turkish and English privacy policies have the same structure", async () => {
  const dir = await buildTo();
  const shape = (html: string) => ({
    h2: (html.match(/<h2>/g) ?? []).length,
    h3: (html.match(/<h3>/g) ?? []).length,
    tables: (html.match(/<table>/g) ?? []).length,
    rows: (html.match(/<tr>/g) ?? []).length,
    lists: (html.match(/<(ul|ol)>/g) ?? []).length,
    items: (html.match(/<li>/g) ?? []).length,
    mailto: (html.match(/mailto:support@rubricator\.app/g) ?? []).length,
    // The TR page carries one extra paragraph: the "translation of the English text" notice.
    external: (html.match(/href="https:\/\//g) ?? []).length,
  });
  const en = shape(await Deno.readTextFile(join(dir, "privacy-policy.html")));
  const tr = shape(
    await Deno.readTextFile(join(dir, "tr/gizlilik-politikasi/index.html")),
  );
  assertEquals(tr, en);
});

Deno.test("the translated accounts of the same page mirror each other", () => {
  for (
    const page of PAGES.filter((p) =>
      p.dir.en !== undefined && p.dir.tr !== undefined
    )
  ) {
    assert(outputPath(page, "en") && outputPath(page, "tr"), page.id);
    assertEquals(page.title.en.length > 0 && page.title.tr.length > 0, true);
  }
});

// --- absolute-URL mode ------------------------------------------------------

Deno.test("with SITE_URL: canonical, hreflang pairs, og:image, sitemap, absolute 404 links", async () => {
  const dir = await buildTo({ siteUrl: SITE_URL + "/" });
  const about = await Deno.readTextFile(join(dir, "about/index.html"));
  assertMatch(
    about,
    new RegExp(`<link rel="canonical" href="${SITE_URL}/about/">`),
  );
  assertMatch(about, new RegExp(`hreflang="en" href="${SITE_URL}/about/"`));
  assertMatch(
    about,
    new RegExp(`hreflang="tr" href="${SITE_URL}/tr/hakkimizda/"`),
  );
  assertMatch(
    about,
    new RegExp(`og:image" content="${SITE_URL}/img/icon-512.png"`),
  );

  const sitemap = await Deno.readTextFile(join(dir, "sitemap.xml"));
  for (
    const p of [
      "",
      "about/",
      "tr/",
      "tr/hakkimizda/",
      "contact/",
      "tr/iletisim/",
      "privacy-policy.html",
      "account-deletion/",
      "tr/hesap-silme/",
    ]
  ) {
    assert(
      sitemap.includes(`<loc>${SITE_URL}/${p}</loc>`),
      `sitemap misses ${p}`,
    );
  }
  assert(!sitemap.includes("404.html"), "404 must not be in the sitemap");
  assertMatch(
    await Deno.readTextFile(join(dir, "robots.txt")),
    new RegExp(`Sitemap: ${SITE_URL}/sitemap.xml`),
  );

  const notFound = await Deno.readTextFile(join(dir, "404.html"));
  assertMatch(notFound, new RegExp(`href="${SITE_URL}/assets/site.css"`));
  assertMatch(notFound, /name="robots" content="noindex"/);
});

Deno.test("without SITE_URL there are no canonical/sitemap/absolute URLs", async () => {
  const dir = await buildTo();
  const files = await walk(dir);
  assert(!files.includes("sitemap.xml"));
  const html = await Deno.readTextFile(join(dir, "index.html"));
  assert(!html.includes('rel="canonical"') && !html.includes("og:image"));
});

Deno.test("SITE_DOMAIN writes the CNAME file GitHub Pages needs", async () => {
  const withDomain = await buildTo({ siteDomain: "rubricator.app" });
  assertEquals(
    await Deno.readTextFile(join(withDomain, "CNAME")),
    "rubricator.app\n",
  );
  const without = await buildTo();
  assert(!(await walk(without)).includes("CNAME"));
});

Deno.test("the old /privacy-policy/ URL redirects to /privacy-policy.html", async () => {
  const dir = await buildTo();
  assertMatch(
    await Deno.readTextFile(join(dir, "privacy-policy/index.html")),
    /http-equiv="refresh" content="0; url=\.\.\/privacy-policy\.html"/,
  );
});

Deno.test("the privacy policy keeps its content and wraps tables for small screens", async () => {
  const dir = await buildTo();
  const html = await Deno.readTextFile(join(dir, "privacy-policy.html"));
  assertMatch(html, /<h1>Rubricator Privacy Policy<\/h1>/);
  assertMatch(html, /Last updated:<\/strong> \d{2}\.\d{2}\.\d{4}/);
  assertEquals(
    (html.match(/<table>/g) ?? []).length,
    (html.match(/<div class="table-wrap"><table>/g) ?? []).length,
  );
});
