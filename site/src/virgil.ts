/**
 * The Virgil web page: sign in (or create an account), describe the book you're
 * in the mood for, read the recommendations. The markup and every string live
 * here; static/js/app.js wires it up. Recommendations come from the same
 * `rubricatorApi` edge function the mobile app uses.
 */
import {
  type BuildContext,
  type Lang,
  PRIVACY_POLICY_VERSION,
} from "./layout.ts";
import { confirmedUrl } from "./confirmed.ts";

export const VIRGIL_SCRIPTS = ["assets/js/app.js"];

const en = {
  badge: "BETA",
  tagline: "Virgil will guide your reading journey.",
  lead:
    "Describe a story, a feeling or a topic in your own words and get book recommendations. You'll need a Rubricator account, the same one you use in the app.",
  unavailable:
    "Virgil isn't available on the website right now. Please try again later or use the mobile app.",
  noscript:
    "Virgil on the web needs JavaScript. Please enable it and reload the page.",
  tabSignIn: "Sign in",
  tabSignUp: "Create account",
  email: "Email",
  password: "Password",
  username: "Display name",
  passwordHint:
    "At least 6 characters, with an uppercase letter, a lowercase letter and a punctuation mark.",
  privacyPre: "I have read and accept the",
  privacyLink: "privacy policy",
  privacyPost: ".",
  signIn: "Sign in",
  signUp: "Create account",
  forgot: "Forgot your password?",
  resetTitle: "Reset your password",
  resetIntro: "We'll email you an 8-digit code.",
  sendCode: "Send code",
  code: "8-digit code",
  newPassword: "New password",
  confirmPassword: "Confirm new password",
  resetSubmit: "Set new password",
  backToSignIn: "Back to sign in",
  signOut: "Sign out",
  signedInAs: "Signed in as",
  queryLabel: "What are you looking for?",
  queryPlaceholder: "e.g. a slow-burn mystery set in a small coastal town",
  genreLabel: "Genre",
  genres: {
    "All": "All",
    "Fiction": "Fiction",
    "Nonfiction": "Nonfiction",
    "Children's Fiction": "Children's fiction",
    "Children's Nonfiction": "Children's nonfiction",
  },
  search: "Get recommendations",
  intro:
    "Discover new authors, different genres and works you might like. Virgil makes exploring easy with its recommendations.",
  close: "Close",
  searching: "Virgil is thinking…",
  usage: "{left} of {limit} recommendation requests left today.",
  resultsHeading: "Recommendations",
  noResultsTitle: "Virgil couldn't find a match.",
  noResultsHint:
    "Try describing a mood, a topic or a book you loved in different words. Setting Genre to “All” can help too.",
  // Relevance marks on the result covers (same as the app).
  voteRelevant: "Relevant",
  voteIrrelevant: "Not relevant",
  feedbackHint: "Mark results as relevant or not, then refine.",
  feedbackRefine: "Refine",
  feedbackRefined: "Refined with your marks.",
  feedbackReset: "Original",
  // Messages (used by app.js)
  msgSignedIn: "Welcome back.",
  msgSignUpDone:
    "Account created. Check your email to confirm it, then sign in.",
  msgCodeSent: "Check your email for your 8-digit code.",
  msgResetDone: "Your password was updated and you're signed in.",
  errEmailRequired: "Email is required.",
  errEmailInvalid: "Enter a valid email address.",
  errPasswordRequired: "Password is required.",
  errPasswordTooShort: "Password must be at least 6 characters.",
  errPasswordMissingUppercase: "Password must include an uppercase letter.",
  errPasswordMissingLowercase: "Password must include a lowercase letter.",
  errPasswordMissingPunctuation:
    "Password must include a punctuation character.",
  errUsernameRequired: "Display name is required.",
  errMismatch: "Passwords do not match.",
  errAcceptPrivacy: "Please accept the privacy policy to create an account.",
  errOtpIncomplete: "Please enter the full 8-digit code.",
  errQueryShort: "Write at least 3 characters.",
  errQueryLong: "Keep it under 500 characters.",
  errInvalidCredentials: "Email or password is incorrect.",
  errEmailNotConfirmed:
    "Please confirm your email address first: check your inbox.",
  errUserExists: "An account with this email already exists. Try signing in.",
  errWeakPassword: "That password is too weak. Choose a stronger one.",
  errRateLimit: "Too many attempts. Please wait a moment and try again.",
  errOtp: "That code is wrong or has expired. Request a new one.",
  errNetwork: "Couldn't reach the server. Check your connection and try again.",
  errUnknown: "Something went wrong. Please try again.",
  errSessionExpired: "Your session ended. Please sign in again.",
  errDailyLimit:
    "You can request recommendations up to 5 times per day. Try again tomorrow.",
  errBusy: "Virgil is busy right now. Please try again in a moment.",
  errTimeout: "That took too long. Please try again.",
  errServer: "Virgil ran into a problem. Please try again later.",
  errFeedback: "Couldn't save your mark. Try again.",
  errFeedbackRateLimited:
    "You've marked a lot of results. Try again in a while.",
} as const;

export type VirgilStrings = {
  [K in keyof typeof en]: (typeof en)[K] extends string ? string
    : Record<string, string>;
};

const tr: VirgilStrings = {
  badge: "BETA",
  tagline: "Virgil okuma yolculuğuna rehberlik eder.",
  lead:
    "Bir hikâyeyi, bir duyguyu ya da bir konuyu kendi cümlelerinle anlat, kitap önerileri al. Uygulamada kullandığın Rubricator hesabına ihtiyacın var.",
  unavailable:
    "Virgil şu an web sitesinde kullanılamıyor. Lütfen daha sonra tekrar dene ya da mobil uygulamayı kullan.",
  noscript:
    "Web'de Virgil için JavaScript gerekiyor. Lütfen etkinleştirip sayfayı yenile.",
  tabSignIn: "Giriş yap",
  tabSignUp: "Hesap oluştur",
  email: "E-posta",
  password: "Şifre",
  username: "Görünen ad",
  passwordHint:
    "En az 6 karakter; büyük harf, küçük harf ve noktalama işareti içermeli.",
  privacyPre: "",
  privacyLink: "Gizlilik politikasını",
  privacyPost: " okudum ve kabul ediyorum.",
  signIn: "Giriş yap",
  signUp: "Hesap oluştur",
  forgot: "Şifreni mi unuttun?",
  resetTitle: "Şifreni sıfırla",
  resetIntro: "Sana 8 haneli bir kod e-postalayacağız.",
  sendCode: "Kod gönder",
  code: "8 haneli kod",
  newPassword: "Yeni şifre",
  confirmPassword: "Yeni şifreyi doğrula",
  resetSubmit: "Yeni şifreyi kaydet",
  backToSignIn: "Girişe dön",
  signOut: "Çıkış yap",
  signedInAs: "Giriş yapan:",
  queryLabel: "Ne arıyorsun?",
  queryPlaceholder:
    "ör. küçük bir sahil kasabasında geçen, yavaş ilerleyen bir polisiye",
  genreLabel: "Tür",
  genres: {
    "All": "Tümü",
    "Fiction": "Kurgu",
    "Nonfiction": "Kurgu dışı",
    "Children's Fiction": "Çocuk kurgusu",
    "Children's Nonfiction": "Çocuk kurgu dışı",
  },
  search: "Öneri al",
  intro:
    "Keşfetmeye değer yeni yazarlar, farklı türler ve ilgini çekebilecek eserler. Virgil, sana öneriler sunarak keşfetmeni kolaylaştırır.",
  close: "Kapat",
  searching: "Virgil düşünüyor…",
  usage: "Bugün {left}/{limit} öneri hakkın kaldı.",
  resultsHeading: "Öneriler",
  noResultsTitle: "Virgil bir eşleşme bulamadı.",
  noResultsHint:
    "Bir ruh halini, bir konuyu ya da sevdiğin bir kitabı farklı cümlelerle anlatmayı dene.",
  voteRelevant: "Alakalı",
  voteIrrelevant: "Alakasız",
  feedbackHint:
    "Sonuçları alakalı ya da alakasız diye işaretle, sonra iyileştir.",
  feedbackRefine: "İyileştir",
  feedbackRefined: "İşaretlerine göre iyileştirildi.",
  feedbackReset: "İlk sonuçlar",
  msgSignedIn: "Tekrar hoş geldin.",
  msgSignUpDone:
    "Hesabın oluşturuldu. Onaylamak için e-postanı kontrol et, sonra giriş yap.",
  msgCodeSent: "8 haneli kod için e-postanı kontrol et.",
  msgResetDone: "Şifren güncellendi ve giriş yaptın.",
  errEmailRequired: "E-posta gerekli.",
  errEmailInvalid: "Geçerli bir e-posta gir.",
  errPasswordRequired: "Şifre gerekli.",
  errPasswordTooShort: "Şifre en az 6 karakter olmalıdır.",
  errPasswordMissingUppercase: "Şifre en az bir büyük harf içermelidir.",
  errPasswordMissingLowercase: "Şifre en az bir küçük harf içermelidir.",
  errPasswordMissingPunctuation:
    "Şifre en az bir noktalama işareti içermelidir.",
  errUsernameRequired: "Görünen ad gerekli.",
  errMismatch: "Şifreler eşleşmiyor.",
  errAcceptPrivacy:
    "Hesap oluşturmak için gizlilik politikasını kabul etmelisin.",
  errOtpIncomplete: "Lütfen 8 haneli kodu eksiksiz gir.",
  errQueryShort: "En az 3 karakter yaz.",
  errQueryLong: "500 karakterin altında tut.",
  errInvalidCredentials: "E-posta veya şifre hatalı.",
  errEmailNotConfirmed:
    "Önce e-posta adresini onaylamalısın: gelen kutunu kontrol et.",
  errUserExists: "Bu e-postayla zaten bir hesap var. Giriş yapmayı dene.",
  errWeakPassword: "Bu şifre çok zayıf. Daha güçlü bir şifre seç.",
  errRateLimit: "Çok fazla deneme yapıldı. Biraz bekleyip tekrar dene.",
  errOtp: "Kod hatalı ya da süresi dolmuş. Yeni bir kod iste.",
  errNetwork: "Sunucuya ulaşılamadı. Bağlantını kontrol edip tekrar dene.",
  errUnknown: "Bir şeyler ters gitti. Lütfen tekrar dene.",
  errSessionExpired: "Oturumun sona erdi. Lütfen tekrar giriş yap.",
  errDailyLimit:
    "Günde en fazla 5 kez kitap önerisi alabilirsin. Yarın tekrar dene.",
  errBusy: "Virgil şu an yoğun. Birazdan tekrar dene.",
  errTimeout: "Bu çok uzun sürdü. Lütfen tekrar dene.",
  errServer: "Virgil bir sorunla karşılaştı. Lütfen daha sonra tekrar dene.",
  errFeedback: "İşaretin kaydedilemedi. Tekrar dene.",
  errFeedbackRateLimited:
    "Çok fazla işaretleme yaptın. Biraz sonra tekrar dene.",
};

export const VIRGIL_STRINGS: Record<Lang, VirgilStrings> = { en, tr };

const esc = (s: string) =>
  s.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");

/** JSON that is safe inside a <script type="application/json"> block. */
const jsonIsland = (value: unknown) =>
  JSON.stringify(value).replaceAll("<", "\\u003c").replaceAll(
    "\u2028",
    "\\u2028",
  ).replaceAll("\u2029", "\\u2029");

// Icons from the mobile Virgil module (the "tune" filter and the quill on the
// red submit button, assets/Virgil/recommendation/redBtn.svg). Drawn with CSS
// stroke = currentColor.
const TUNE_ICON =
  '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M4 7h10M18 7h2M4 17h4M12 17h8"/><circle cx="16" cy="7" r="2"/><circle cx="10" cy="17" r="2"/></svg>';
export const QUILL_ICON =
  '<svg viewBox="6 6 24 24" aria-hidden="true"><path d="M10.64 23.18c-.27-2.9-.53-5.04.48-6.84.1.75.22 1.64.38 2.47.13.71.29 1.4.46 1.91.08.26.18.5.29.69.2.34.5.46.63.47.43.04.8-.11 1.07-.43.23-.28.35-.66.42-1.04.14-.75.13-1.79.13-2.85-.01-1.09-.01-2.24.13-3.3.14-1.07.41-2 .91-2.66.5-.66 1.53-1.2 2.8-1.66.62-.23 1.27-.43 1.9-.62-.45.61-.86 1.28-1.18 1.92-.3.59-.53 1.19-.6 1.69-.03.24-.03.52.06.77.1.24.28.43.53.53.26.08.44.02.54-.03.3-.14.6-.4.95-.75.48-.46 1.1-1.12 1.7-1.7.6-.6 1.22-1.17 1.75-1.54.27-.18.5-.3.67-.35.17-.06.24-.03.26-.02 1.3.66 3.2 2.3 3.88 2.97.18.17.23.34.21.53-.02.21-.12.47-.33.77-.42.59-1.12 1.14-1.7 1.42-.46.22-1.03.31-1.66.33-.64.01-1.29-.05-1.92-.12-.6-.07-1.22-.14-1.69-.12-.23.02-.49.05-.71.17-.22.11-.39.29-.47.54-.08.38-.09 1.12.61 1.75.51.46 1.34.8 2.67.94-1.31.91-2.57 1.06-3.68 1.03-.35-.01-.69-.04-1.01-.07-.32-.03-.65-.06-.94-.07-.57-.02-1.21.02-1.69.42-.42.36-.33.88-.2 1.2.13.35.39.7.69 1.01.3.31.68.6 1.07.8l.22.1c-.99.9-1.67 1.14-2.29 1.15-.4.01-.83-.08-1.36-.2-.51-.13-1.13-.29-1.85-.4l-.44-.06-1.29 4.8a1 1 0 0 1-1.93-.51z"/></svg>';

// Thumbs up / down for the relevance marks (outline; filled when pressed).
const THUMB_UP_ICON =
  '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M7 10v11H4a1 1 0 0 1-1-1v-9a1 1 0 0 1 1-1h3zm0 0 4-8a3 3 0 0 1 3 3v4h5.5a2 2 0 0 1 2 2.3l-1.4 8.5a2 2 0 0 1-2 1.7H7"/></svg>';
const THUMB_DOWN_ICON =
  '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M17 14V3h3a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1h-3zm0 0-4 8a3 3 0 0 1-3-3v-4H4.5a2 2 0 0 1-2-2.3l1.4-8.5a2 2 0 0 1 2-1.7H17"/></svg>';

export function virgilBody(lang: Lang, ctx: BuildContext): string {
  const t = VIRGIL_STRINGS[lang];
  const configured = Boolean(ctx.supabaseUrl && ctx.supabaseAnonKey);
  const confirm = confirmedUrl(lang, ctx);
  const config = configured
    ? ` data-supabase-url="${esc(ctx.supabaseUrl!)}" data-anon-key="${
      esc(ctx.supabaseAnonKey!)
    }"${confirm ? ` data-confirm-url="${esc(confirm)}"` : ""}`
    : "";
  // The genre filter is English-only: its BISAC-style values don't match the
  // Turkish catalog, so filtering by one would return nothing (same as the app).
  // Like the app, it is a toggle button that opens a row of chips.
  const english = lang === "en";
  const genreToggle = english
    ? `
              <button class="v-round" type="button" id="genre-toggle" aria-expanded="false" aria-controls="genre-panel" aria-label="${t.genreLabel}">${TUNE_ICON}</button>`
    : "";
  const genrePanel = english
    ? `
          <div class="v-genres" id="genre-panel" hidden>
            <div class="v-genres-head">
              <span id="genre-heading">${t.genreLabel}</span>
              <button class="link-button" type="button" id="genre-close">${t.close}</button>
            </div>
            <div class="v-chips" role="group" aria-labelledby="genre-heading">
${
      Object.entries(t.genres).map(([value, label]) =>
        `              <button class="v-chip" type="button" data-genre="${
          esc(value)
        }" aria-pressed="${value === "All"}">${esc(label)}</button>`
      ).join("\n")
    }
            </div>
          </div>`
    : "";

  // Layout follows the app's recommendation screen: brand row on top, the
  // content in the middle, the search bar docked at the bottom of the screen.
  return `    <div class="v-screen" id="virgil" data-lang="${lang}" data-policy-version="${PRIVACY_POLICY_VERSION}"${config}>
     <div class="container v-frame">
      <header class="v-head">
        <h1 class="v-brand"><span class="v-word">Virgil</span> <span class="v-badge">${t.badge}</span></h1>
        <div class="v-account" id="account" hidden>
          <span class="v-account-email"><span class="sr-only">${t.signedInAs} </span><span id="account-email"></span></span>
          <button class="link-button" type="button" id="sign-out">${t.signOut}</button>
        </div>
      </header>

      <noscript><div class="note"><p>${t.noscript}</p></div></noscript>
      <div class="note" id="unavailable"${
    configured ? " hidden" : ""
  }><p>${t.unavailable}</p></div>

      <p class="status" id="status" role="status" aria-live="polite" hidden></p>

      <section class="v-auth" id="auth-view" hidden>
       <p class="v-tagline">${t.tagline}</p>
       <p class="v-lead">${t.lead}</p>
       <div class="panel">
        <div class="tabs" role="group" aria-label="${t.tabSignIn} / ${t.tabSignUp}">
          <button type="button" class="tab" id="tab-signin" aria-pressed="true">${t.tabSignIn}</button>
          <button type="button" class="tab" id="tab-signup" aria-pressed="false">${t.tabSignUp}</button>
        </div>

        <form id="form-signin" method="post" action="#" novalidate>
          <div class="field"><label for="signin-email">${t.email}</label>
            <input id="signin-email" name="email" type="email" autocomplete="email" required></div>
          <div class="field"><label for="signin-password">${t.password}</label>
            <input id="signin-password" name="password" type="password" autocomplete="current-password" required></div>
          <div class="actions">
            <button class="btn" type="submit">${t.signIn}</button>
            <button class="link-button" type="button" id="open-reset">${t.forgot}</button>
          </div>
        </form>

        <form id="form-signup" method="post" action="#" novalidate hidden>
          <div class="field"><label for="signup-username">${t.username}</label>
            <input id="signup-username" name="username" type="text" autocomplete="nickname" maxlength="40" required></div>
          <div class="field"><label for="signup-email">${t.email}</label>
            <input id="signup-email" name="email" type="email" autocomplete="email" required></div>
          <div class="field"><label for="signup-password">${t.password}</label>
            <input id="signup-password" name="password" type="password" autocomplete="new-password" aria-describedby="password-hint" required>
            <p class="hint" id="password-hint">${t.passwordHint}</p></div>
          <div class="field check">
            <input id="signup-privacy" name="privacy" type="checkbox">
            <label for="signup-privacy">${t.privacyPre} <a href="{{link:privacy}}" target="_blank" rel="noopener">${t.privacyLink}</a>${t.privacyPost}</label>
          </div>
          <div class="actions"><button class="btn" type="submit">${t.signUp}</button></div>
        </form>

        <form id="form-reset-request" method="post" action="#" novalidate hidden>
          <h2>${t.resetTitle}</h2>
          <p>${t.resetIntro}</p>
          <div class="field"><label for="reset-email">${t.email}</label>
            <input id="reset-email" name="email" type="email" autocomplete="email" required></div>
          <div class="actions">
            <button class="btn" type="submit">${t.sendCode}</button>
            <button class="link-button" type="button" data-back-to-signin>${t.backToSignIn}</button>
          </div>
        </form>

        <form id="form-reset" method="post" action="#" novalidate hidden>
          <h2>${t.resetTitle}</h2>
          <div class="field"><label for="reset-code">${t.code}</label>
            <input id="reset-code" name="code" type="text" inputmode="numeric" autocomplete="one-time-code" maxlength="8" required></div>
          <div class="field"><label for="reset-password">${t.newPassword}</label>
            <input id="reset-password" name="password" type="password" autocomplete="new-password" required></div>
          <div class="field"><label for="reset-confirm">${t.confirmPassword}</label>
            <input id="reset-confirm" name="confirm" type="password" autocomplete="new-password" required></div>
          <div class="actions">
            <button class="btn" type="submit">${t.resetSubmit}</button>
            <button class="link-button" type="button" data-back-to-signin>${t.backToSignIn}</button>
          </div>
        </form>
       </div>
      </section>

      <section class="v-app" id="search-view" hidden>
        <div class="v-content">
          <p class="v-intro" id="search-intro">${t.intro}</p>
          <div id="results-wrap" hidden>
            <h2 class="v-query" id="results-heading" tabindex="-1"><span class="sr-only">${t.resultsHeading}: </span><span id="results-query"></span></h2>
            <p class="v-category" id="results-category" hidden></p>
            <div class="v-refine" id="refine" hidden>
              <p class="hint" id="refine-hint" aria-live="polite"></p>
              <div class="v-refine-actions">
                <button class="link-button" type="button" id="refine-reset" hidden>${t.feedbackReset}</button>
                <button class="btn secondary" type="button" id="refine-apply" disabled>${t.feedbackRefine}</button>
              </div>
            </div>
            <div class="empty" id="no-results" hidden>
              <p><strong>${t.noResultsTitle}</strong></p>
              <p class="hint">${t.noResultsHint}</p>
            </div>
            <ol class="v-grid" id="results"></ol>
            <template id="vote-template">
              <div class="v-votes">
                <button class="v-vote" type="button" data-vote="1" aria-pressed="false" aria-label="${t.voteRelevant}" title="${t.voteRelevant}">${THUMB_UP_ICON}</button>
                <button class="v-vote" type="button" data-vote="-1" aria-pressed="false" aria-label="${t.voteIrrelevant}" title="${t.voteIrrelevant}">${THUMB_DOWN_ICON}</button>
              </div>
            </template>
          </div>
        </div>
        <form class="v-dock" id="form-search" method="post" action="#" novalidate>${genrePanel}
          <div class="field">
            <label class="sr-only" for="query">${t.queryLabel}</label>
            <div class="v-bar">
              <input class="v-input" id="query" name="query" type="text" enterkeyhint="search" autocomplete="off" maxlength="500" placeholder="${
    esc(t.queryPlaceholder)
  }" required>${genreToggle}
              <button class="v-round v-submit" type="submit" id="search-button" aria-describedby="usage" aria-label="${t.search}">${QUILL_ICON}</button>
            </div>
          </div>
          <p class="hint" id="usage" aria-live="polite" hidden></p>
        </form>
      </section>

      <dialog class="v-dialog" id="book-dialog" aria-labelledby="book-dialog-title">
        <div class="book-cover" id="book-dialog-cover"></div>
        <div>
          <h2 id="book-dialog-title"></h2>
          <p class="book-author" id="book-dialog-author"></p>
        </div>
        <p class="v-dialog-desc" id="book-dialog-desc"></p>
        <form method="dialog"><button class="btn secondary" type="submit">${t.close}</button></form>
      </dialog>

      <script type="application/json" id="i18n">${jsonIsland(t)}</script>
     </div>
    </div>`;
}
