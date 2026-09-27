import { assert, assertEquals, assertMatch } from "jsr:@std/assert@1";
import { join } from "jsr:@std/path@1";

import { build } from "./build.ts";
import { PRIVACY_POLICY_VERSION } from "./src/layout.ts";
import { VIRGIL_STRINGS } from "./src/virgil.ts";

const SUPABASE = {
  supabaseUrl: "https://proj.supabase.co",
  supabaseAnonKey: "sb_publishable_test",
};

async function buildTo(
  options: {
    supabaseUrl?: string;
    supabaseAnonKey?: string;
    siteUrl?: string;
  } = {},
) {
  const dir = await Deno.makeTempDir({ prefix: "virgil-test-" });
  // Empty strings (not undefined) so the developer's environment never leaks in.
  await build({
    outPath: dir,
    siteUrl: "",
    supabaseUrl: "",
    supabaseAnonKey: "",
    ...options,
  });
  return dir;
}

const read = (dir: string, file: string) => Deno.readTextFile(join(dir, file));

Deno.test("CSP: own scripts, only the Supabase origin, no unsafe-*", async () => {
  const dir = await buildTo(SUPABASE);
  for (const file of ["virgil/index.html", "tr/virgil/index.html"]) {
    const html = await read(dir, file);
    const csp = html.match(/Content-Security-Policy" content="([^"]+)"/)![1];
    assertEquals(
      csp,
      [
        "default-src 'none'",
        "img-src 'self' data: https:",
        "style-src 'self'",
        "font-src 'self'",
        "script-src 'self'",
        "connect-src https://proj.supabase.co",
        "base-uri 'self'",
        "form-action 'none'",
      ].join("; "),
    );
    assert(!/unsafe-/.test(csp));
    assertMatch(html, /data-supabase-url="https:\/\/proj\.supabase\.co"/);
    assertMatch(html, /data-anon-key="sb_publishable_test"/);
    assertMatch(
      html,
      /<script type="module" src="(\.\.\/)*assets\/js\/app\.js"><\/script>/,
    );
  }
});

Deno.test("without Supabase settings the page says 'unavailable' and connects nowhere", async () => {
  const html = await read(await buildTo(), "virgil/index.html");
  assertMatch(html, /connect-src 'none'/);
  assert(
    !html.includes("data-supabase-url") && !html.includes("data-anon-key"),
  );
  assert(!/id="unavailable" hidden/.test(html), "the notice must be visible");
  const configured = await read(await buildTo(SUPABASE), "virgil/index.html");
  assertMatch(configured, /id="unavailable" hidden/);
});

Deno.test("SUPABASE_URL must be https (or a local http mock)", async () => {
  for (
    const bad of [
      "http://evil.example",
      "https://a.co/path",
      "ftp://x",
      "javascript:1",
    ]
  ) {
    let failed = false;
    try {
      await buildTo({ supabaseUrl: bad, supabaseAnonKey: "k" });
    } catch {
      failed = true;
    }
    assert(failed, `${bad} must be rejected`);
  }
  await buildTo({ supabaseUrl: "http://localhost:8767", supabaseAnonKey: "k" });
  await buildTo({
    supabaseUrl: "https://proj.supabase.co/",
    supabaseAnonKey: "k",
  });
});

Deno.test("the browser scripts are published, import only each other and avoid unsafe APIs", async () => {
  const dir = await buildTo(SUPABASE);
  const files: string[] = [];
  for await (const e of Deno.readDir(join(dir, "assets/js"))) {
    files.push(e.name);
  }
  assertEquals(files.sort(), [
    "app.js",
    "auth.js",
    "confirmed.js",
    "virgil.js",
  ]);
  for (const f of files) {
    const code = await read(dir, `assets/js/${f}`);
    for (const m of code.matchAll(/from\s+"([^"]+)"/g)) {
      assertMatch(m[1], /^\.\/[a-z]+\.js$/, `${f} imports ${m[1]}`);
    }
    assert(
      !/\beval\(|new Function|innerHTML|outerHTML|document\.write|insertAdjacentHTML/
        .test(code),
      `${f}: unsafe DOM/eval API`,
    );
  }
});

Deno.test("the i18n block is valid JSON that can't close its script tag", async () => {
  const dir = await buildTo(SUPABASE);
  for (
    const [file, signIn] of [["virgil/index.html", "Sign in"], [
      "tr/virgil/index.html",
      "Giriş yap",
    ]]
  ) {
    const html = await read(dir, file);
    const block = html.match(
      /<script type="application\/json" id="i18n">([\s\S]*?)<\/script>/,
    )![1];
    assert(!block.includes("<"));
    const strings = JSON.parse(block);
    assertEquals(strings.tabSignIn, signIn);
    assert(strings.errDailyLimit.includes("5"));
    assertEquals(typeof strings.genres.All, "string");
  }
});

Deno.test("English and Turkish strings cover the same keys and none is empty", () => {
  const { en, tr } = VIRGIL_STRINGS;
  assertEquals(Object.keys(tr).sort(), Object.keys(en).sort());
  assertEquals(Object.keys(tr.genres).sort(), Object.keys(en.genres).sort());
  for (const key of Object.keys(en) as Array<keyof typeof en>) {
    if (typeof tr[key] === "string" && key !== "privacyPre") {
      assert((tr[key] as string).length > 0, `tr.${key} is empty`);
    }
  }
});

Deno.test("only the English page offers the genre filter", async () => {
  const dir = await buildTo(SUPABASE);
  assertMatch(await read(dir, "virgil/index.html"), /<select id="genre"/);
  assert(!(await read(dir, "tr/virgil/index.html")).includes('id="genre"'));
});

Deno.test("the sign-up consent link goes to the privacy policy of the same language", async () => {
  const dir = await buildTo(SUPABASE);
  assertMatch(
    await read(dir, "virgil/index.html"),
    /href="\.\.\/privacy-policy\.html"[^>]*>privacy policy</,
  );
  assertMatch(
    await read(dir, "tr/virgil/index.html"),
    /href="\.\.\/gizlilik-politikasi\/"[^>]*>Gizlilik politikasını</,
  );
});

Deno.test("the policy version sent at sign-up equals the policy's 'Last updated' date", async () => {
  const dir = await buildTo(SUPABASE);
  for (
    const [file, label] of [
      ["privacy-policy.html", "Last updated:"],
      ["tr/gizlilik-politikasi/index.html", "Son güncelleme:"],
    ]
  ) {
    const html = await read(dir, file);
    const match = html.match(
      new RegExp(`${label}</strong> (\\d{2})\\.(\\d{2})\\.(\\d{4})`),
    );
    assert(match, `${file}: no date`);
    assertEquals(
      `${match[3]}-${match[2]}-${match[1]}`,
      PRIVACY_POLICY_VERSION,
      file,
    );
  }
  assertMatch(
    await read(dir, "virgil/index.html"),
    new RegExp(`data-policy-version="${PRIVACY_POLICY_VERSION}"`),
  );
});

Deno.test("navigation offers Virgil and the home page links to it", async () => {
  const dir = await buildTo(SUPABASE);
  const home = await read(dir, "index.html");
  assertMatch(home, /<a href="virgil\/">Virgil<\/a>/);
  assertMatch(home, /class="btn" href="virgil\/">Try Virgil</);
  assert(!/aria-disabled/.test(home), "no disabled 'coming soon' button left");
  assertMatch(
    await read(dir, "tr/index.html"),
    /class="btn" href="virgil\/">Virgil'i dene</,
  );
});

// --- the "you're confirmed" page (site/src/confirmed.ts) --------------------

const SITE_URL = "https://rubricator.site";

Deno.test("the confirmed page exists in both languages, out of the nav, noindex, own CSP", async () => {
  const dir = await buildTo({ ...SUPABASE, siteUrl: SITE_URL });
  for (
    const [file, lang] of [
      ["auth/confirmed/index.html", "en"],
      ["tr/auth/onay/index.html", "tr"],
    ] as const
  ) {
    const html = await read(dir, file);
    assertMatch(html, new RegExp(`<html lang="${lang}">`));
    assertMatch(html, /name="robots" content="noindex"/);
    assert(
      !html.includes('aria-current="page"'),
      `${file}: must not be a nav item`,
    );
    assertMatch(
      html,
      /<script type="module" src="(\.\.\/)*assets\/js\/confirmed\.js"><\/script>/,
    );
    assertMatch(
      html,
      /Content-Security-Policy" content="default-src 'none'; img-src 'self' data: https:; style-src 'self'; font-src 'self'; script-src 'self'; connect-src https:\/\/proj\.supabase\.co; base-uri 'self'; form-action 'none'"/,
    );
  }
});

Deno.test("the confirmed page is not in the sitemap", async () => {
  const dir = await buildTo({ ...SUPABASE, siteUrl: SITE_URL });
  const sitemap = await read(dir, "sitemap.xml");
  assert(
    !sitemap.includes("/auth/confirmed/") && !sitemap.includes("/auth/onay/"),
  );
});

Deno.test("the Virgil page points redirect_to at the confirmed page of the same language, absolute URL", async () => {
  const dir = await buildTo({ ...SUPABASE, siteUrl: SITE_URL });
  assertMatch(
    await read(dir, "virgil/index.html"),
    new RegExp(`data-confirm-url="${SITE_URL}/auth/confirmed/"`),
  );
  assertMatch(
    await read(dir, "tr/virgil/index.html"),
    new RegExp(`data-confirm-url="${SITE_URL}/tr/auth/onay/"`),
  );
});

Deno.test("without a site URL, the Virgil page carries no confirm-url (redirect_to is simply omitted)", async () => {
  const html = await read(await buildTo(SUPABASE), "virgil/index.html");
  assert(!html.includes("data-confirm-url"));
});

Deno.test("the confirmed page's i18n block is valid, script-tag-safe JSON with matching keys", async () => {
  const dir = await buildTo({ ...SUPABASE, siteUrl: SITE_URL });
  for (const file of ["auth/confirmed/index.html", "tr/auth/onay/index.html"]) {
    const html = await read(dir, file);
    const block = html.match(
      /<script type="application\/json" id="i18n">([\s\S]*?)<\/script>/,
    )![1];
    assert(!block.includes("<"));
    const strings = JSON.parse(block);
    assertEquals(Object.keys(strings).sort(), [
      "continueLabel",
      "error",
      "generic",
      "h1",
      "signedIn",
    ]);
    assert(strings.signedIn.includes("{email}"));
  }
});

Deno.test("the confirmed page's own text is correct without JavaScript (no 'hidden' gating it)", async () => {
  const dir = await buildTo({ ...SUPABASE, siteUrl: SITE_URL });
  const html = await read(dir, "auth/confirmed/index.html");
  assertMatch(
    html,
    /id="status"[^>]*>Your email address is confirmed\. Sign in below to continue\.</,
  );
  assert(
    !/id="status"[^>]*\shidden/.test(html),
    "the status text must be visible without JS",
  );
});

Deno.test("without Supabase settings the confirmed page still renders (no script, no data attrs)", async () => {
  const html = await read(
    await buildTo({ siteUrl: SITE_URL }),
    "auth/confirmed/index.html",
  );
  assert(
    !html.includes("data-supabase-url") && !html.includes("data-anon-key"),
  );
  // The script still loads (like the Virgil page); it self-guards at runtime
  // on the missing data attributes, same as app.js.
  assertMatch(
    html,
    /<script type="module" src="[^"]*confirmed\.js"><\/script>/,
  );
  assertMatch(html, /connect-src 'none'/);
  assertMatch(
    html,
    /Your email address is confirmed\. Sign in below to continue\./,
  );
});
