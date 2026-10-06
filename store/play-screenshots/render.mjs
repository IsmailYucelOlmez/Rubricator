// Renders template.html to out/<lang>-<device>/NN.png with headless Chromium:
// phone 1080x1920 and tablet 2560x1440, each in Turkish and English.
// Usage: node store/play-screenshots/render.mjs [slide numbers...]
// Set CHROME to a chrome.exe path if Playwright's Chromium is not installed.
import { execFileSync } from "node:child_process";
import { existsSync, mkdirSync, readdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { homedir } from "node:os";

const here = dirname(fileURLToPath(import.meta.url));

function findChrome() {
  if (process.env.CHROME) return process.env.CHROME;
  const root = join(homedir(), "AppData", "Local", "ms-playwright");
  for (const d of readdirSync(root).filter((d) => d.startsWith("chromium-")).sort().reverse()) {
    for (const sub of ["chrome-win64", "chrome-win"]) {
      const p = join(root, d, sub, "chrome.exe");
      if (existsSync(p)) return p;
    }
  }
  throw new Error("Chromium not found; set CHROME");
}

const chrome = findChrome();
const slides = process.argv.slice(2).length ? process.argv.slice(2) : ["1", "2", "3", "4", "5", "6", "7", "8", "9"];
const variants = [
  { lang: "tr", device: "phone", size: "1080,1920" },
  { lang: "en", device: "phone", size: "1080,1920" },
  { lang: "tr", device: "tablet", size: "2560,1440" },
  { lang: "en", device: "tablet", size: "2560,1440" },
];

for (const v of variants) {
  const dir = join(here, "out", `${v.lang}-${v.device}`);
  mkdirSync(dir, { recursive: true });
  for (const s of slides) {
    const out = join(dir, `${s.padStart(2, "0")}.png`);
    const url = `${pathToFileURL(join(here, "template.html")).href}?s=${s}&lang=${v.lang}&device=${v.device}`;
    execFileSync(chrome, [
      "--headless", "--disable-gpu", "--hide-scrollbars", "--allow-file-access-from-files",
      "--force-device-scale-factor=1", `--window-size=${v.size}`, "--virtual-time-budget=4000",
      `--screenshot=${out}`, url,
    ], { stdio: "ignore" });
    console.log(out);
  }
}
