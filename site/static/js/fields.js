// Field-level validation messages shared by the site's forms (Virgil, contact).
// A problem is shown under its own field: aria-invalid on the control and a
// message linked with aria-describedby. Text is set with textContent only.

export function setFieldError(input, message) {
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

export function clearFieldError(input) {
  if (input.getAttribute("aria-invalid") !== "true") return;
  document.getElementById(`${input.id}-error`)?.remove();
  input.removeAttribute("aria-invalid");
  if (input.dataset.describedby) {
    input.setAttribute("aria-describedby", input.dataset.describedby);
  } else {
    input.removeAttribute("aria-describedby");
  }
}

export function clearFieldErrors(container) {
  for (const input of container.querySelectorAll("[aria-invalid=true]")) {
    clearFieldError(input);
  }
}

/**
 * Shows every [input, message] problem under its field and focuses the first
 * one. Returns true when there was nothing to show.
 */
export function showFieldErrors(form, problems) {
  clearFieldErrors(form);
  const found = problems.filter(([, message]) => message);
  for (const [input, message] of found) setFieldError(input, message);
  if (found.length === 0) return true;
  found[0][0].focus();
  return false;
}

/** Typing into (or ticking) a field clears its error. */
export function clearErrorsOnInput() {
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
}
