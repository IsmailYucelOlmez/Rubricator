// Entry for the vendored Sentry browser SDK (site/static/vendor/sentry.js).
// Errors only: no default integrations (no tracing, replay, feedback or
// breadcrumbs). site/static/js/monitoring.js imports it lazily, only after an
// error happens. Rebuild after changing the version or the exports:
//   deno bundle --platform browser --format esm --minify \
//     site/tools/sentry_entry.ts -o site/static/vendor/sentry.js
export {
  captureException,
  dedupeIntegration,
  httpContextIntegration,
  init,
  linkedErrorsIntegration,
} from "npm:@sentry/browser@11.4.0";
