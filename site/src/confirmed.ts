/**
 * Landing page for Supabase's signup-confirmation email link
 * (`{{ .ConfirmationURL }}` → GoTrue verifies it, then redirects here with
 * `#access_token=…&refresh_token=…&type=signup` in the fragment, or
 * `#error=…&error_description=…` if the link was invalid or had expired).
 *
 * The confirmation itself already happened server-side by the time this page
 * loads — the text below is true even with JavaScript off. The script
 * (static/js/confirmed.js) only upgrades it: pick up the tokens, sign the
 * visitor in on this device and send them on to Virgil.
 */
import { type BuildContext, type Lang, outputPath } from "./layout.ts";

export const CONFIRMED_SCRIPTS = ["assets/js/confirmed.js"];

const en = {
  h1: "You're confirmed",
  generic: "Your email address is confirmed. Sign in below to continue.",
  signedIn: "You're confirmed and signed in as {email}. Taking you to Virgil…",
  error:
    "This confirmation link is invalid or has expired. Try signing up again, or request a new email from the sign-in page.",
  continueLabel: "Continue to Virgil",
};

const tr: typeof en = {
  h1: "Onaylandı",
  generic: "E-posta adresin onaylandı. Devam etmek için aşağıdan giriş yap.",
  signedIn:
    "Onaylandın ve {email} olarak giriş yaptın. Virgil'e yönlendiriliyorsun…",
  error:
    "Bu onay bağlantısı geçersiz ya da süresi dolmuş. Yeniden kayıt olmayı dene, ya da giriş sayfasından yeni bir e-posta iste.",
  continueLabel: "Virgil'e devam et",
};

export const CONFIRMED_STRINGS: Record<Lang, typeof en> = { en, tr };

const esc = (s: string) =>
  s.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");

const jsonIsland = (value: unknown) =>
  JSON.stringify(value).replaceAll("<", "\\u003c").replaceAll(
    "\u2028",
    "\\u2028",
  ).replaceAll("\u2029", "\\u2029");

export function confirmedBody(lang: Lang, ctx: BuildContext): string {
  const t = CONFIRMED_STRINGS[lang];
  const config = ctx.supabaseUrl && ctx.supabaseAnonKey
    ? ` data-supabase-url="${esc(ctx.supabaseUrl)}" data-anon-key="${
      esc(ctx.supabaseAnonKey)
    }"`
    : "";

  return `    <div class="page container" id="confirmed"${config}>
      <article class="prose">
        <h1>${t.h1}</h1>
        <p class="status" id="status" role="status" aria-live="polite">${t.generic}</p>
        <p><a class="btn" href="{{link:virgil}}">${t.continueLabel}</a></p>
      </article>
      <script type="application/json" id="i18n">${jsonIsland(t)}</script>
    </div>`;
}

/**
 * Absolute URL of the confirmed page in `lang`, for `redirect_to` (must be an
 * absolute URL — the confirmation email is opened outside this site's own
 * pages). `undefined` when the site URL isn't known (local/dev builds), in
 * which case the client omits `redirect_to` and GoTrue falls back to the
 * project's configured Site URL.
 */
export function confirmedUrl(
  lang: Lang,
  ctx: BuildContext,
): string | undefined {
  if (!ctx.siteUrl) return undefined;
  const page = ctx.pages.find((p) => p.id === "confirmed");
  const path = page ? outputPath(page, lang) : null;
  if (!path) return undefined;
  return `${ctx.siteUrl}/${path.replace(/(^|\/)index\.html$/, "$1")}`;
}
