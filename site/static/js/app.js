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
  clearErrorsOnInput,
  clearFieldErrors,
  showFieldErrors,
} from "./fields.js";
import {
  createVirgil,
  isVotableIsbn,
  MAX_QUERY_LENGTH,
  MAX_REFINEMENT_ISBNS,
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

  // Validation problems go under their field; #status is for form-wide errors.
  function checkFields(form, problems) {
    const ok = showFieldErrors(form, problems);
    if (!ok) say("");
    return ok;
  }
  clearErrorsOnInput();

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
    $("account").hidden = !signedIn;
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
      current = null;
      votes = new Map();
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
  // opens in a dialog (the website has no book page to go to). Results with an
  // ISBN get the relevance marks on the cover (siblings of the card button:
  // buttons can't be nested).
  function resultCard(book, position) {
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
    if (isVotableIsbn(book.isbn13)) {
      item.dataset.isbn = book.isbn13;
      const marks = $("vote-template").content.firstElementChild.cloneNode(
        true,
      );
      for (const button of marks.querySelectorAll("[data-vote]")) {
        button.addEventListener("click", () => {
          toggleVote(book, position, Number(button.dataset.vote));
        });
      }
      item.append(marks);
      showVote(item, votes.get(book.isbn13) ?? 0);
    }
    return item;
  }

  // ---- relevance marks + refine (same flow as the app) ----------------------
  /** The search on screen: {query, category, applied} (applied = refinement). */
  let current = null;
  /** isbn13 -> 1 | -1, in the order they were cast (most recent last). */
  let votes = new Map();
  const voting = new Set();

  function showVote(item, vote) {
    if (vote) item.dataset.vote = String(vote);
    else delete item.dataset.vote;
    for (const button of item.querySelectorAll("[data-vote]")) {
      button.setAttribute(
        "aria-pressed",
        String(Number(button.dataset.vote) === vote),
      );
    }
  }

  function showVotes() {
    for (const item of $("results").querySelectorAll("li[data-isbn]")) {
      showVote(item, votes.get(item.dataset.isbn) ?? 0);
    }
  }

  /** The latest marks per side, capped like the API. */
  function pendingRefinement() {
    const side = (value) =>
      [...votes].filter(([, v]) => v === value).map(([isbn]) => isbn)
        .slice(-MAX_REFINEMENT_ISBNS);
    return { relevant: side(1), irrelevant: side(-1) };
  }

  function sameRefinement(a, b) {
    const same = (x, y) =>
      x.length === y.length && x.every((isbn) => y.includes(isbn));
    return Boolean(a && b) && same(a.relevant, b.relevant) &&
      same(a.irrelevant, b.irrelevant);
  }

  function updateRefineBar() {
    const bar = $("refine");
    const hasResults = $("results").querySelector("li[data-isbn]") !== null;
    if (!current || (!hasResults && !current.applied)) {
      bar.hidden = true;
      return;
    }
    const pending = pendingRefinement();
    const empty = pending.relevant.length + pending.irrelevant.length === 0;
    const upToDate = sameRefinement(pending, current.applied);
    $("refine-hint").textContent = upToDate
      ? t.feedbackRefined
      : t.feedbackHint;
    $("refine-apply").disabled = empty || upToDate;
    $("refine-reset").hidden = !current.applied;
    bar.hidden = false;
  }

  async function toggleVote(book, position, value) {
    if (!current || voting.has(book.isbn13)) return;
    const previous = votes.get(book.isbn13) ?? 0;
    const next = previous === value ? 0 : value;
    const set = (vote) => {
      votes.delete(book.isbn13);
      if (vote) votes.set(book.isbn13, vote);
      showVotes();
      updateRefineBar();
    };
    set(next);
    voting.add(book.isbn13);
    try {
      await virgil.vote({
        query: current.query,
        language: lang,
        isbn13: book.isbn13,
        vote: next,
        position,
        similarity: book.similarity,
        category: current.category,
      });
    } catch (error) {
      set(previous);
      say(
        error instanceof VirgilError && error.code === "rate_limited"
          ? t.errFeedbackRateLimited
          : t.errFeedback,
        "error",
      );
      if (error instanceof VirgilError && error.code === "unauthorized") {
        auth.reload();
      }
    } finally {
      voting.delete(book.isbn13);
    }
  }

  function openBook(book) {
    $("book-dialog-cover").replaceWith(
      Object.assign(coverBox(book, "book-cover"), { id: "book-dialog-cover" }),
    );
    $("book-dialog-title").textContent = book.title || book.isbn13;
    $("book-dialog-author").textContent = book.author ?? "";
    $("book-dialog-author").hidden = !book.author;
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
    runSearch({
      query,
      category: lang === "en" ? genre : "All",
      applied: null,
    });
  });

  $("refine-apply").addEventListener("click", () => {
    if (current) runSearch({ ...current, applied: pendingRefinement() });
  });
  $("refine-reset").addEventListener("click", () => {
    if (current) runSearch({ ...current, applied: null });
  });

  /**
   * Runs a search and shows it. A new query starts with the user's saved marks
   * for it; a refinement (applied) re-runs the same query with the marks.
   */
  function runSearch(next) {
    const { query, category, applied } = next;
    const newQuery = !current || current.query !== query ||
      current.category !== category;
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
      current,
      votes,
    };
    button.disabled = true;
    $("refine-apply").disabled = true;
    $("refine-reset").disabled = true;
    current = next;
    if (newQuery) {
      votes = new Map();
      $("refine").hidden = true;
      virgil.votes({ query, language: lang }).then((saved) => {
        if (seq !== searchSeq || current !== next) return;
        // Marks cast while loading win over the saved ones.
        votes = new Map([...saved, ...votes]);
        showVotes();
        updateRefineBar();
      });
    }
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
    virgil.search({ query, category, language: lang, feedback: applied })
      .then((books) => {
        if (seq !== searchSeq) return;
        say("");
        list.replaceChildren(...books.map(resultCard));
        updateRefineBar();
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
        current = previous.current;
        votes = previous.votes;
        showVotes();
        if (
          error instanceof VirgilError && error.code === "daily_limit_reached"
        ) {
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
        if (seq !== searchSeq) return;
        button.disabled = false;
        $("refine-reset").disabled = false;
        updateRefineBar();
      });
  }

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
