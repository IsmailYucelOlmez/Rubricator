// Wires the contact form (site/src/pages.ts, contact page) to the `contact`
// edge function, which emails the message to the support address. Without
// JavaScript or Supabase config the page still shows the email address.
import { clearErrorsOnInput, showFieldErrors } from "./fields.js";

const root = document.getElementById("contact");

// Same rule as supabase/functions/contact/handler.ts.
const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const LIMITS = { name: 100, email: 254, messageMin: 10, messageMax: 5000 };
const TIMEOUT_MS = 20_000;

function main() {
  const url = root.dataset.supabaseUrl;
  const anonKey = root.dataset.anonKey;
  if (!url || !anonKey) return; // the page already shows "email us instead"

  const t = JSON.parse(document.getElementById("i18n").textContent);
  const form = document.getElementById("form-contact");
  const status = document.getElementById("status");
  const button = form.querySelector("button[type=submit]");
  const f = form.elements;

  function say(message, kind = "info") {
    status.textContent = message;
    status.dataset.kind = kind;
    status.hidden = !message;
  }

  function setBusy(busy) {
    button.disabled = busy;
    form.setAttribute("aria-busy", String(busy));
  }

  /** Server field codes (handler.ts validate) → this page's messages. */
  const serverMessages = {
    name: { too_long: t.errNameLong },
    email: { required: t.errEmailRequired, invalid: t.errEmailInvalid },
    message: {
      required: t.errMessageRequired,
      too_short: t.errMessageShort,
      too_long: t.errMessageLong,
    },
  };

  function localProblems() {
    const name = f.name.value.trim();
    const email = f.email.value.trim();
    const message = f.message.value.trim();
    return [
      [f.name, name.length > LIMITS.name ? t.errNameLong : null],
      [
        f.email,
        !email
          ? t.errEmailRequired
          : email.length > LIMITS.email || !EMAIL.test(email)
          ? t.errEmailInvalid
          : null,
      ],
      [
        f.message,
        !message
          ? t.errMessageRequired
          : message.length < LIMITS.messageMin
          ? t.errMessageShort
          : message.length > LIMITS.messageMax
          ? t.errMessageLong
          : null,
      ],
    ];
  }

  form.hidden = false;
  clearErrorsOnInput();

  form.addEventListener("submit", async (event) => {
    event.preventDefault();
    if (form.getAttribute("aria-busy") === "true") return;
    if (!showFieldErrors(form, localProblems())) {
      say("");
      return;
    }
    setBusy(true);
    say(t.sending);
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);
    try {
      const response = await fetch(`${url}/functions/v1/contact`, {
        method: "POST",
        headers: { apikey: anonKey, "Content-Type": "application/json" },
        body: JSON.stringify({
          name: f.name.value,
          email: f.email.value,
          message: f.message.value,
          website: f.website.value, // honeypot: stays empty for people
          lang: root.dataset.lang,
        }),
        signal: controller.signal,
      });
      if (response.ok) {
        form.reset();
        say(t.sent, "ok");
        return;
      }
      if (response.status === 429) return say(t.errRateLimit, "error");
      if (response.status === 400) {
        const data = await response.json().catch(() => null);
        const fields = data?.fields ?? {};
        const problems = Object.entries(fields).map(([key, code]) => [
          f[key],
          serverMessages[key]?.[code] ?? t.errServer,
        ]).filter(([input]) => input);
        if (problems.length) {
          say("");
          showFieldErrors(form, problems);
          return;
        }
      }
      say(t.errServer, "error");
    } catch {
      say(t.errNetwork, "error");
    } finally {
      clearTimeout(timer);
      setBusy(false);
    }
  });
}

if (root) main();
