// Light/dark theme switch (header sun/moon button). Loaded as a classic,
// blocking script in <head> so a saved choice is applied before first paint
// (no flash). Without a saved choice the site follows the system setting;
// without JavaScript the button stays hidden and the system setting applies.
(function () {
  var KEY = "rubricator.theme";
  var root = document.documentElement;
  var saved = null;
  try {
    saved = localStorage.getItem(KEY);
  } catch (_) { /* storage blocked: follow the system */ }
  if (saved === "light" || saved === "dark") root.dataset.theme = saved;

  document.addEventListener("DOMContentLoaded", function () {
    var button = document.getElementById("theme-toggle");
    if (!button) return;
    var system = matchMedia("(prefers-color-scheme: dark)");
    function isDark() {
      return root.dataset.theme
        ? root.dataset.theme === "dark"
        : system.matches;
    }
    function sync() {
      button.setAttribute("aria-pressed", String(isDark()));
    }
    button.addEventListener("click", function () {
      var next = isDark() ? "light" : "dark";
      root.dataset.theme = next;
      try {
        localStorage.setItem(KEY, next);
      } catch (_) { /* this page only */ }
      sync();
    });
    system.addEventListener("change", sync);
    sync();
    button.hidden = false;
  });
})();
