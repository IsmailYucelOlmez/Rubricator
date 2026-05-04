# 🧠 UX & Error Handling System (FULL – Production Ready)

## 🎯 Goal

Build a complete user experience layer that:

* prevents raw error exposure
* validates user input properly
* provides meaningful feedback
* improves perceived performance
* ensures smooth and polished UX

This system MUST be applied globally across the app.

---

# 🧱 Architecture

UI → ViewModel/Provider → UseCase → Repository → API

❌ NEVER:

* show raw API errors in UI
* handle validation inside widgets randomly

---

# 🚨 ERROR HANDLING SYSTEM

---

## 🔴 1. Global Error Mapper

Create a centralized error mapper:

```dart id="error_mapper"
class AppError {
  final String message;
  final String code;

  AppError(this.message, this.code);
}

class ErrorMapper {
  static AppError map(dynamic error) {
    if (error.toString().contains("network")) {
      return AppError("İnternet bağlantınızı kontrol edin", "NETWORK");
    }

    if (error.toString().contains("timeout")) {
      return AppError("İstek zaman aşımına uğradı", "TIMEOUT");
    }

    return AppError("Bir hata oluştu, lütfen tekrar deneyin", "UNKNOWN");
  }
}
```

---

## 🔴 2. UI Error Rules

* NEVER show raw error text
* ALWAYS show user-friendly message
* ALWAYS provide retry option if possible

---

## 🔴 3. Error UI Types

### Snackbar (minor errors)

* short message
* auto dismiss

---

### Dialog (critical errors)

* blocking
* retry button

---

### Inline Error (form)

* shown under input field

---

# 📝 FORM VALIDATION SYSTEM

---

## 🔵 1. Validation Rules

All forms MUST validate before submission.

---

## Example:

```dart id="validation"
String? validateEmail(String value) {
  if (value.isEmpty) return "Email gerekli";
  if (!value.contains("@")) return "Geçerli email girin";
  return null;
}
```

---

## 🔵 2. Required Fields

* title
* review
* list name
* etc.

---

## 🔵 3. UX Rules

* show error instantly (on blur)
* highlight field border (red)
* scroll to first error

---

# ⚡ LOADING STATES

---

## 🟡 Types:

### 1. Full screen loading

* initial page load

---

### 2. Button loading

* disable button
* show spinner

---

### 3. Skeleton loading (IMPORTANT)

* for lists and feeds

---

## Example:

```dart id="loading_button"
if (isLoading) {
  return CircularProgressIndicator();
}
```

---

# 📭 EMPTY STATES

---

## MUST exist for:

* no search results
* empty lists
* no reviews

---

## Example messages:

* “Henüz kitap eklenmedi”
* “İlk listeni oluştur”

---

## UX:

* icon + message + CTA button

---

# 🔄 RETRY SYSTEM

---

## Required for:

* network failure
* failed API calls

---

## Example:

* “Tekrar dene” button
* retry same action

---

# 🧠 UX FEEDBACK SYSTEM

---

## 🟢 Success Feedback

* snackbar: “Liste başarıyla oluşturuldu”

---

## 🟡 Warning

* “Bu işlem geri alınamaz”

---

## 🔴 Error

* friendly message
* never technical

---

# 📶 NETWORK AWARENESS

---

## Detect:

* offline mode

---

## Show:

* “İnternet bağlantısı yok”

---

# 🔐 ACTION SAFETY

---

## Dangerous actions:

* delete list
* remove item

---

## MUST:

* confirmation dialog

---

# 🎯 MICRO INTERACTIONS

---

## Add:

* button press animation
* like animation
* smooth transitions

---

# ⚡ PERFORMANCE UX

---

## Rules:

* no blocking UI
* use async operations
* lazy loading

---

# 📊 STATE HANDLING

---

## States:

* loading
* success
* error
* empty

---

## MUST:

Each screen must handle ALL states.

---

# 🚫 ANTI-PATTERNS

---

* ❌ raw API error
* ❌ silent failure
* ❌ infinite loading
* ❌ no feedback after action

---

# 🎯 EXPECTED OUTPUT

User should:

* always understand what is happening
* never see technical errors
* recover from errors بسهولة
* feel app is smooth and responsive

---

# 🔥 FINAL RULE

If something fails:

👉 explain it
👉 guide the user
👉 offer recovery
