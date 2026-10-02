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

  // ---- field errors ---------------------------------------------------------
  // A validation problem is shown under its own field (aria-invalid + a message
  // linked with aria-describedby); #status is kept for form-wide errors.
  function setFieldError(input, message) {
    const field = input.closest(".field");
    const id = `${input.id}-error`;
    let note = document.getElementById(id);
    if (!note) {
      note = document.createElement("p");
      note.className = "field-error";
      note.id = id;
      field.append(note);
    }
    note.textContent = message;
    input.dataset.describedby ??= input.getAttribute("aria-describedby") ?? "";
    input.setAttribute("aria-invalid", "true");
    input.setAttribute(
      "aria-describedby",
      `${id} ${input.dataset.describedby}`.trim(),
    );
  }

  function clearFieldError(input) {
    if (input.getAttribute("aria-invalid") !== "true") return;
    document.getElementById(`${input.id}-error`)?.remove();
    input.removeAttribute("aria-invalid");
    if (input.dataset.describedby) {
      input.setAttribute("aria-describedby", input.dataset.describedby);
    } else {
      input.removeAttribute("aria-describedby");
    }
  }

  function clearFieldErrors(container) {
    for (const input of container.querySelectorAll("[aria-invalid=true]")) {
      clearFieldError(input);
    }
  }

  /**
   * Shows every [input, message] problem under its field and focuses the first
   * one. Returns true when there was nothing to show.
   */
  function checkFields(form, problems) {
    clearFieldErrors(form);
    const found = problems.filter(([, message]) => message);
    for (const [input, message] of found) setFieldError(input, message);
    if (found.length === 0) return true;
    say("");
    found[0][0].focus();
    return false;
  }

  // Typing into (or ticking) a field clears its error.
  for (const type of ["input", "change"]) {
    document.addEventListener(type, (event) => {
      const target = event.target;
      if (
        target instanceof HTMLElement && target.matches("[aria-invalid=true]")
      ) {
        clearFieldError(target);
      }
    });
  }

  function showForm(name) {
    for (const [key, form] of Object.entries(forms)) {
      form.hidden = key !== name;
      clearFieldErrors(form);
    }
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
      $("search-intro").hidden = false;
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

  /** A cover box that keeps its placeholder (book icon) if the image fails. */
  function coverBox(book, className) {
    const cover = document.createElement("div");
    cover.className = className;
    if (book.cover) {
      const img = document.createElement("img");
      img.src = book.cover;
      img.alt = "";
      img.loading = "lazy";
      img.decoding = "async";
      img.referrerPolicy = "no-referrer";
      img.addEventListener("error", () => img.remove());
      cover.append(img);
    }
    return cover;
  }

  // Like the app: a grid of covers with title and author. The description
  // opens in a dialog (the website has no book page to go to).
  function resultCard(book) {
    const item = document.createElement("li");
    const card = document.createElement("button");
    card.type = "button";
    card.className = "v-card";
    const title = document.createElement("span");
    title.className = "v-card-title";
    title.textContent = book.title || book.isbn13;
    const author = document.createElement("span");
    author.className = "v-card-author";
    author.textContent = book.author ?? "";
    card.append(coverBox(book, "book-cover"), title, author);
    card.addEventListener("click", () => openBook(book));
    item.append(card);
    return item;
  }

  function openBook(book) {
    $("book-dialog-cover").replaceWith(
      Object.assign(coverBox(book, "book-cover"), { id: "book-dialog-cover" }),
    );
    $("book-dialog-title").textContent = book.title || book.isbn13;
    $("book-dialog-author").textContent = book.author ?? "";
    $("book-dialog-author").hidden = !book.author;
    $("book-dialog-category").textContent = book.category ?? "";
    $("book-dialog-meta").hidden = !book.category;
    $("book-dialog-desc").textContent = book.description ?? "";
    $("book-dialog-desc").hidden = !book.description;
    $("book-dialog").showModal();
  }

  // A click on the backdrop (outside the dialog box) closes it too.
  $("book-dialog").addEventListener("click", (event) => {
    if (event.target === event.currentTarget) event.currentTarget.close();
  });

  // Static placeholders while Virgil works; #status announces "thinking".
  function skeletonCards(count) {
    return Array.from({ length: count }, () => {
      const item = document.createElement("li");
      item.setAttribute("aria-hidden", "true");
      const card = document.createElement("div");
      card.className = "v-card skeleton";
      const cover = document.createElement("div");
      cover.className = "book-cover";
      const title = document.createElement("span");
      title.className = "v-card-title";
      const author = document.createElement("span");
      author.className = "v-card-author";
      card.append(cover, title, author);
      item.append(card);
      return item;
    });
  }

  // ---- genre (English page only) --------------------------------------------
  let genre = "All";
  const genreToggle = $("genre-toggle");
  function setGenrePanel(open) {
    $("genre-panel").hidden = !open;
    genreToggle.setAttribute("aria-expanded", String(open));
  }
  if (genreToggle) {
    genreToggle.addEventListener("click", () => {
      setGenrePanel(genreToggle.getAttribute("aria-expanded") !== "true");
    });
    $("genre-close").addEventListener("click", () => {
      setGenrePanel(false);
      genreToggle.focus();
    });
    for (const chip of document.querySelectorAll("[data-genre]")) {
      chip.addEventListener("click", () => {
        genre = chip.dataset.genre;
        for (const other of document.querySelectorAll("[data-genre]")) {
          other.setAttribute("aria-pressed", String(other === chip));
        }
      });
    }
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
    const f = forms.signin;
    const email = f.email.value;
    const password = f.password.value;
    if (
      !checkFields(f, [
        [f.email, emailError(email)],
        [f.password, password ? null : t.errPasswordRequired],
      ])
    ) {
      event.preventDefault();
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
    if (
      !checkFields(f, [
        [f.username, f.username.value.trim() ? null : t.errUsernameRequired],
        [f.email, emailError(f.email.value)],
        [f.password, passwordError(f.password.value)],
        [f.privacy, f.privacy.checked ? null : t.errAcceptPrivacy],
      ])
    ) {
      event.preventDefault();
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
    if (
      !checkFields(forms.resetRequest, [
        [forms.resetRequest.email, emailError(email)],
      ])
    ) {
      event.preventDefault();
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
    const password = passwordError(f.password.value);
    if (
      !checkFields(f, [
        [f.code, code.length === 8 ? null : t.errOtpIncomplete],
        [f.password, password],
        [
          f.confirm,
          password || f.password.value === f.confirm.value
            ? null
            : t.errMismatch,
        ],
      ])
    ) {
      event.preventDefault();
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
    const queryProblem = query.length < MIN_QUERY_LENGTH
      ? t.errQueryShort
      : query.length > MAX_QUERY_LENGTH
      ? t.errQueryLong
      : null;
    if (!checkFields($("form-search"), [[$("query"), queryProblem]])) return;
    const category = lang === "en" ? genre : "All";
    const seq = ++searchSeq;
    const button = $("search-button");
    const list = $("results");
    const wrap = $("results-wrap");
    const heading = $("results-query");
    const categoryLabel = $("results-category");
    // Kept so an error can put the previous results back.
    const previous = {
      items: [...list.children],
      hidden: wrap.hidden,
      query: heading.textContent,
      category: categoryLabel.textContent,
      categoryHidden: categoryLabel.hidden,
      intro: $("search-intro").hidden,
    };
    button.disabled = true;
    say(t.searching);
    // Like the app: the query becomes the title of the results.
    heading.textContent = query;
    categoryLabel.textContent = t.genres[category] ?? category;
    categoryLabel.hidden = category === "All";
    $("search-intro").hidden = true;
    list.replaceChildren(...skeletonCards(6));
    list.setAttribute("aria-busy", "true");
    $("no-results").hidden = true;
    wrap.hidden = false;
    virgil.search({ query, category, language: lang }).then((books) => {
      if (seq !== searchSeq) return;
      say("");
      list.replaceChildren(...books.map(resultCard));
      list.removeAttribute("aria-busy");
      $("no-results").hidden = books.length > 0;
      $("results-heading").focus();
      refreshUsage();
    }).catch((error) => {
      if (seq !== searchSeq) return;
      list.replaceChildren(...previous.items);
      list.removeAttribute("aria-busy");
      wrap.hidden = previous.hidden;
      heading.textContent = previous.query;
      categoryLabel.textContent = previous.category;
      categoryLabel.hidden = previous.categoryHidden;
      $("search-intro").hidden = previous.intro;
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
