// Wires the "you're confirmed" page (site/src/confirmed.ts) to auth.js. The
// page's own text is already correct with no JavaScript: this only upgrades
// it when it can identify the visitor from the link they clicked.
import { createAuth } from "./auth.js";

const root = document.getElementById("confirmed");

function main() {
  const url = root.dataset.supabaseUrl;
  const anonKey = root.dataset.anonKey;
  if (!url || !anonKey) return; // static text already covers this case

  const t = JSON.parse(document.getElementById("i18n").textContent);
  const status = document.getElementById("status");
  let storage = null;
  try {
    storage = globalThis.localStorage;
  } catch { /* consumeRedirectFragment still stores in memory for this load */ }

  // Read before consumeRedirectFragment() runs: it strips the hash
  // synchronously for the "no tokens" branch, which includes "#error=…".
  const hadError = new URLSearchParams(location.hash.replace(/^#/, "")).has(
    "error",
  );

  const auth = createAuth({ url, anonKey, storage });
  auth.consumeRedirectFragment().then((session) => {
    if (session) {
      status.textContent = t.signedIn.replace("{email}", session.user.email);
      status.dataset.kind = "ok";
      const continueLink = root.querySelector("a.btn");
      setTimeout(() => {
        if (continueLink) location.href = continueLink.href;
      }, 1500);
    } else if (hadError) {
      status.textContent = t.error;
      status.dataset.kind = "error";
    }
  }).catch(() => {/* the static "confirmed" text already covers this */});
}

if (root) main();
