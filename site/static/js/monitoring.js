// Error reporting (Sentry) for the pages that run code: Virgil, contact and the
// email confirmation page. Nothing is loaded or sent until an error happens:
// this file only listens, and the SDK (site/static/vendor/sentry.js, ~95 KB
// gzip) is imported on the first error. Reports carry no personal data: no
// user, no breadcrumbs, no query string or #fragment (the confirmation link
// carries tokens there), and email addresses are masked.

const meta = (name) =>
  document.querySelector(`meta[name="${name}"]`)?.getAttribute("content") ||
  undefined;

const dsn = meta("sentry-dsn");
const MAX_REPORTS = 10; // per page view
const EMAIL = /[^\s@"'<>()]+@[^\s@"'<>()]+\.[a-z]{2,}/gi;

function scrubUrl(value) {
  try {
    const url = new URL(value, location.href);
    return url.origin + url.pathname;
  } catch {
    return undefined;
  }
}

const scrub = (text) =>
  typeof text === "string" ? text.replace(EMAIL, "[email]") : text;

function beforeSend(event) {
  delete event.user;
  delete event.breadcrumbs;
  if (event.request) {
    event.request.url = scrubUrl(event.request.url ?? location.href);
    delete event.request.query_string;
    delete event.request.cookies;
    if (event.request.headers) delete event.request.headers.Referer;
  }
  event.message = scrub(event.message);
  for (const value of event.exception?.values ?? []) {
    value.value = scrub(value.value);
  }
  return event;
}

if (dsn) {
  let sdk = null;
  let loading = null;
  let sent = 0;
  const queue = [];

  const load = () =>
    loading ??= import("../vendor/sentry.js").then((Sentry) => {
      Sentry.init({
        dsn,
        // Errors only: none of the default integrations (tracing, breadcrumbs…).
        defaultIntegrations: [],
        environment: meta("sentry-environment") ?? "production",
        release: meta("sentry-release"),
        sendDefaultPii: false,
        integrations: [
          Sentry.dedupeIntegration(),
          Sentry.linkedErrorsIntegration(),
          Sentry.httpContextIntegration(),
        ],
        // Only errors thrown by this site's own scripts (not extensions).
        allowUrls: [location.origin],
        beforeSend,
      });
      sdk = Sentry;
    });

  const report = (error) => {
    if (sent >= MAX_REPORTS || error == null) return;
    sent++;
    queue.push(error);
    load()
      .then(() => {
        while (queue.length) sdk.captureException(queue.shift());
      })
      .catch(() => {/* reporting must never break the page */});
  };

  // Resource load errors (e.g. a broken book cover) have no `error`: skipped.
  addEventListener("error", (event) => report(event.error));
  addEventListener("unhandledrejection", (event) => report(event.reason));
}
