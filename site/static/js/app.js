// Wires the Virgil page (site/src/virgil.ts) to the auth and API modules.
// All text is inserted with textContent / createElement: results come from a
// third-party catalog, so they are never treated as HTML.
import {
  AuthError,
  createAuth,
  isValidEmail,
  validatePassword,
} from "./auth.js";
import {
  createVirgil,
  MAX_QUERY_LENGTH,
  MIN_QUERY_LENGTH,
  VirgilError,
} from "./virgil.js";

const root = document.getElementById("virgil");

function main() {
  const t = JSON.parse(document.getElementById("i18n").textContent);
  const url = root.dataset.supabaseUrl;
  const anonKey = root.dataset.anonKey;
  if (!url || !anonKey) return; // the page already shows "unavailable"

  const $ = (id) => document.getElementById(id);
  const lang = root.dataset.lang;
  let storage = null;
  try {
    storage = globalThis.localStorage;
  } catch { /* blocked: the auth client falls back to memory */ }

  const auth = createAuth({
    url,
    anonKey,
    storage,
    redirectTo: root.dataset.confirmUrl,
  });
  const virgil = createVirgil({
    url,
    anonKey,
    getToken: (force) => auth.getAccessToken(force),
  });

  const views = { auth: $("auth-view"), search: $("search-view") };
  const forms = {
    signin: $("form-signin"),
    signup: $("form-signup"),
    resetRequest: $("form-reset-request"),
    reset: $("form-reset"),
  };
  const status = $("status");
  let resetEmail = "";
  let searchSeq = 0;
  let wasSignedIn = false;
  let signingOut = false;

  // ---- helpers ------------------------------------------------------------
  function say(message, kind = "info") {
    status.textContent = message;
    status.dataset.kind = kind;
    status.hidden = !message;
  }

  function showForm(name) {
    for (const [key, form] of Object.entries(forms)) form.hidden = key !== name;
    const signin = name === "signin";
    const signup = name === "signup";
    $("tab-signin").setAttribute("aria-pressed", String(signin));
    $("tab-signup").setAttribute("aria-pressed", String(signup));
    document.querySelector(".tabs").hidden = !(signin || signup);
    say("");
  }

  function setBusy(form, busy) {
    for (const el of form.querySelectorAll("button, input, textarea, select")) {
      el.disabled = busy;
    }
    form.setAttribute("aria-busy", String(busy));
  }

  function authMessage(error) {
    if (!(error instanceof AuthError)) return t.errUnknown;
    switch (error.code) {
      case "network":
        return t.errNetwork;
      case "invalid_credentials":
      case "invalid_grant":
        return t.errInvalidCredentials;
      case "email_not_confirmed":
        return t.errEmailNotConfirmed;
      case "user_already_exists":
      case "email_exists":
        return t.errUserExists;
      case "weak_password":
        return t.errWeakPassword;
      case "over_request_rate_limit":
      case "over_email_send_rate_limit":
      case "over_sms_send_rate_limit":
        return t.errRateLimit;
      case "otp_expired":
      case "otp_disabled":
        return t.errOtp;
      default:
        return error.status === 429 ? t.errRateLimit : t.errUnknown;
    }
  }

  function virgilMessage(error) {
    if (!(error instanceof VirgilError)) return t.errUnknown;
    switch (error.code) {
      case "unauthorized":
        return t.errSessionExpired;
      case "daily_limit_reached":
        return t.errDailyLimit;
      case "rate_limited":
        return t.errBusy;
      case "invalid_query":
        return t.errQueryShort;
      case "network":
        return t.errNetwork;
      case "timeout":
        return t.errTimeout;
      default:
        return t.errServer;
    }
  }

  /** Runs a form action with the form locked; shows the error if it throws. */
  async function submit(form, event, action, toMessage) {
    event.preventDefault();
    if (form.getAttribute("aria-busy") === "true") return;
    setBusy(form, true);
    try {
      await action();
    } catch (error) {
      say(toMessage(error), "error");
    } finally {
      setBusy(form, false);
    }
  }

  function passwordError(value) {
    const failure = validatePassword(value);
    if (!failure) return null;
    return {
      empty: t.errPasswordRequired,
      tooShort: t.errPasswordTooShort,
      missingUppercase: t.errPasswordMissingUppercase,
      missingLowercase: t.errPasswordMissingLowercase,
      missingPunctuation: t.errPasswordMissingPunctuation,
    }[failure];
  }

  function emailError(value) {
    if (!value.trim()) return t.errEmailRequired;
    return isValidEmail(value) ? null : t.errEmailInvalid;
  }

  // ---- rendering ----------------------------------------------------------
  function render(session) {
    const signedIn = Boolean(session);
    // The session vanished without the user asking (expired or revoked).
    const ended = wasSignedIn && !signedIn && !signingOut;
    wasSignedIn = signedIn;
    views.auth.hidden = signedIn;
    views.search.hidden = !signedIn;
    if (signedIn) {
      $("account-email").textContent = session.user.email;
      refreshUsage();
    } else {
      searchSeq++; // drop in-flight results
      setLimitReached(false);
      if (ended) {
        showForm("signin");
        say(t.errSessionExpired, "error");
      }
      $("results").replaceChildren();
      $("results-wrap").hidden = true;
      $("usage").hidden = true;
    }
  }

  async function refreshUsage() {
    const usage = await virgil.usage();
    const el = $("usage");
    if (!usage) {
      el.hidden = !limitReached;
      return;
    }
    el.textContent = t.usage
      .replace("{left}", String(Math.max(usage.limit - usage.used, 0)))
      .replace("{limit}", String(usage.limit));
    el.hidden = false;
    setLimitReached(usage.used >= usage.limit);
  }

  // With no requests left the button is aria-disabled (still focusable, so its
  // aria-describedby usage hint is read) and the submit handler refuses. The
  // hint (aria-live) then says why and when it renews.
  let limitReached = false;
  function setLimitReached(reached) {
    limitReached = reached;
    const button = $("search-button");
    if (reached) button.setAttribute("aria-disabled", "true");
    else button.removeAttribute("aria-disabled");
    if (reached) {
      $("usage").textContent = t.errDailyLimit;
      $("usage").hidden = false;
    }
  }

  function resultCard(book) {
    const item = document.createElement("li");
    item.className = "book";
    // The placeholder stays when there is no cover or it fails to load.
    const cover = document.createElement("div");
    cover.className = "book-cover";
    item.append(cover);
    if (book.cover) {
      const img = document.createElement("img");
      img.src = book.cover;
      img.alt = "";
      img.width = 72;
      img.height = 108;
      img.loading = "lazy";
      img.decoding = "async";
      img.referrerPolicy = "no-referrer";
      img.addEventListener("error", () => img.remove());
      cover.append(img);
    }
    const text = document.createElement("div");
    const title = document.createElement("h3");
    title.textContent = book.title || book.isbn13;
    text.append(title);
    if (book.author) {
      const author = document.createElement("p");
      author.className = "book-author";
      author.textContent = book.author;
      text.append(author);
    }
    if (book.category) {
      const category = document.createElement("p");
      category.className = "book-category";
      category.textContent = book.category;
      text.append(category);
    }
    if (book.description) {
      const description = document.createElement("p");
      description.textContent = book.description;
      text.append(description);
    }
    item.append(text);
    return item;
  }

  // ---- events -------------------------------------------------------------
  $("tab-signin").addEventListener("click", () => showForm("signin"));
  $("tab-signup").addEventListener("click", () => showForm("signup"));
  $("open-reset").addEventListener("click", () => {
    $("reset-email").value = $("signin-email").value;
    showForm("resetRequest");
  });
  for (const button of document.querySelectorAll("[data-back-to-signin]")) {
    button.addEventListener("click", () => showForm("signin"));
  }

  forms.signin.addEventListener("submit", (event) => {
    const email = forms.signin.email.value;
    const password = forms.signin.password.value;
    const problem = emailError(email) ??
      (password ? null : t.errPasswordRequired);
    if (problem) {
      event.preventDefault();
      say(problem, "error");
      return;
    }
    submit(forms.signin, event, async () => {
      await auth.signIn(email, password);
      forms.signin.password.value = "";
      say(t.msgSignedIn, "ok");
    }, authMessage);
  });

  forms.signup.addEventListener("submit", (event) => {
    const f = forms.signup;
    const problem = (f.username.value.trim() ? null : t.errUsernameRequired) ??
      emailError(f.email.value) ?? passwordError(f.password.value) ??
      (f.privacy.checked ? null : t.errAcceptPrivacy);
    if (problem) {
      event.preventDefault();
      say(problem, "error");
      return;
    }
    submit(f, event, async () => {
      const { session } = await auth.signUp({
        email: f.email.value,
        password: f.password.value,
        username: f.username.value,
        policyVersion: root.dataset.policyVersion,
      });
      f.password.value = "";
      if (session) {
        say(t.msgSignedIn, "ok");
      } else {
        $("signin-email").value = f.email.value;
        showForm("signin");
        say(t.msgSignUpDone, "ok");
      }
    }, authMessage);
  });

  forms.resetRequest.addEventListener("submit", (event) => {
    const email = forms.resetRequest.email.value;
    const problem = emailError(email);
    if (problem) {
      event.preventDefault();
      say(problem, "error");
      return;
    }
    submit(forms.resetRequest, event, async () => {
      await auth.sendRecoveryCode(email);
      resetEmail = email;
      showForm("reset");
      say(t.msgCodeSent, "ok");
      forms.reset.code.focus();
    }, authMessage);
  });

  forms.reset.addEventListener("submit", (event) => {
    const f = forms.reset;
    const code = f.code.value.trim();
    const problem = (code.length === 8 ? null : t.errOtpIncomplete) ??
      passwordError(f.password.value) ??
      (f.password.value === f.confirm.value ? null : t.errMismatch);
    if (problem) {
      event.preventDefault();
      say(problem, "error");
      return;
    }
    submit(f, event, async () => {
      await auth.resetPassword({
        email: resetEmail,
        code,
        newPassword: f.password.value,
      });
      f.reset();
      say(t.msgResetDone, "ok");
    }, authMessage);
  });

  $("sign-out").addEventListener("click", async () => {
    signingOut = true;
    await auth.signOut();
    signingOut = false;
    showForm("signin");
  });

  $("form-search").addEventListener("submit", (event) => {
    event.preventDefault();
    if (limitReached) return;
    const query = $("query").value.trim();
    if (query.length < MIN_QUERY_LENGTH) return say(t.errQueryShort, "error");
    if (query.length > MAX_QUERY_LENGTH) return say(t.errQueryLong, "error");
    const category = lang === "en" ? $("genre").value : "All";
    const seq = ++searchSeq;
    const button = $("search-button");
    button.disabled = true;
    say(t.searching);
    virgil.search({ query, category, language: lang }).then((books) => {
      if (seq !== searchSeq) return;
      say("");
      const list = $("results");
      list.replaceChildren(...books.map(resultCard));
      $("no-results").hidden = books.length > 0;
      $("results-wrap").hidden = false;
      $("results-heading").focus();
      refreshUsage();
    }).catch((error) => {
      if (seq !== searchSeq) return;
      if (error instanceof VirgilError && error.code === "daily_limit_reached") {
        say("");
        setLimitReached(true);
      } else {
        say(virgilMessage(error), "error");
      }
      if (error instanceof VirgilError && error.code === "unauthorized") {
        auth.reload();
      }
      refreshUsage();
    }).finally(() => {
      if (seq === searchSeq) button.disabled = false;
    });
  });

  // Keep several tabs in sync (sign in / out, refreshed tokens).
  addEventListener("storage", (event) => {
    if (event.key === null || event.key.startsWith("rubricator.web.")) {
      auth.reload();
    }
  });
  auth.onChange((session) => render(session));

  showForm("signin");
  render(auth.getSession());
}

if (root) main();
