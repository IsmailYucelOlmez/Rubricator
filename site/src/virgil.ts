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

export const VIRGIL_SCRIPTS = ["assets/js/app.js"];

const en = {
  eyebrow: "Virgil",
  h1: "Tell Virgil what you're in the mood for",
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
  searching: "Virgil is thinking…",
  usage: "{left} of {limit} recommendation requests left today.",
  resultsHeading: "Recommendations",
  noResults: "Virgil couldn't find a match. Try describing it differently.",
  mobileNote:
    "Asking questions about your own PDF or EPUB is only available in the mobile app.",
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
} as const;

export type VirgilStrings = {
  [K in keyof typeof en]: (typeof en)[K] extends string ? string
    : Record<string, string>;
};

const tr: VirgilStrings = {
  eyebrow: "Virgil",
  h1: "Virgil'e canının ne istediğini söyle",
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
  searching: "Virgil düşünüyor…",
  usage: "Bugün {left}/{limit} öneri hakkın kaldı.",
  resultsHeading: "Öneriler",
  noResults: "Virgil bir eşleşme bulamadı. Farklı anlatmayı dene.",
  mobileNote:
    "Kendi PDF veya EPUB dosyan hakkında soru sorma özelliği yalnızca mobil uygulamada var.",
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

export function virgilBody(lang: Lang, ctx: BuildContext): string {
  const t = VIRGIL_STRINGS[lang];
  const configured = Boolean(ctx.supabaseUrl && ctx.supabaseAnonKey);
  const config = configured
    ? ` data-supabase-url="${esc(ctx.supabaseUrl!)}" data-anon-key="${
      esc(ctx.supabaseAnonKey!)
    }"`
    : "";
  // The genre filter is English-only: its BISAC-style values don't match the
  // Turkish catalog, so filtering by one would return nothing (same as the app).
  const genre = lang === "en"
    ? `
          <div class="field field-narrow">
            <label for="genre">${t.genreLabel}</label>
            <select id="genre" name="genre">
${
      Object.entries(t.genres).map(([value, label]) =>
        `              <option value="${esc(value)}">${esc(label)}</option>`
      ).join("\n")
    }
            </select>
          </div>`
    : "";

  return `    <div class="page container virgil" id="virgil" data-lang="${lang}" data-policy-version="${PRIVACY_POLICY_VERSION}"${config}>
      <div class="prose">
        <p class="eyebrow">${t.eyebrow}</p>
        <h1>${t.h1}</h1>
        <p class="lead">${t.lead}</p>
      </div>

      <noscript><div class="note"><p>${t.noscript}</p></div></noscript>
      <div class="note" id="unavailable"${
    configured ? " hidden" : ""
  }><p>${t.unavailable}</p></div>

      <p class="status" id="status" role="status" aria-live="polite" hidden></p>

      <section class="panel" id="auth-view" hidden>
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
      </section>

      <section class="panel" id="search-view" hidden>
        <div class="account-bar">
          <span>${t.signedInAs} <strong id="account-email"></strong></span>
          <button class="link-button" type="button" id="sign-out">${t.signOut}</button>
        </div>
        <form id="form-search" method="post" action="#" novalidate>
          <div class="field"><label for="query">${t.queryLabel}</label>
            <textarea id="query" name="query" rows="3" maxlength="500" placeholder="${
    esc(t.queryPlaceholder)
  }" required></textarea></div>${genre}
          <div class="actions"><button class="btn" type="submit" id="search-button">${t.search}</button></div>
        </form>
        <p class="hint" id="usage" hidden></p>
        <div id="results-wrap" hidden>
          <h2 id="results-heading" tabindex="-1">${t.resultsHeading}</h2>
          <p id="no-results" hidden>${t.noResults}</p>
          <ol class="results" id="results"></ol>
        </div>
        <p class="hint">${t.mobileNote}</p>
      </section>

      <script type="application/json" id="i18n">${jsonIsland(t)}</script>
    </div>`;
}
