# 🌍 Language Normalization System (Google Books Data)

## 🎯 Goal

Implement a language prioritization and normalization system for book data fetched from Google Books API.

The system must:

1. Prioritize English ("eng") and Turkish ("tur") books
2. If not available → prefer Latin-character titles
3. If still not suitable → fallback safely

This system must be applied BEFORE data reaches UI.

---

# 🧱 Architecture (STRICT)

Data flow:

API → Model → Mapper → Entity → UI

Language filtering MUST happen in:

* data layer (mapper / repository)

DO NOT handle language filtering in UI.

---

# 🧠 LANGUAGE PRIORITY RULES

## Priority Order:

1. Books with language: "eng" or "tur"
2. Books with Latin characters in title
3. Fallback → any available data

---

# ⚙️ IMPLEMENTATION DETAILS

---

## 1. Language Score System

Create a scoring function:

```dart id="language_score"
int getLanguageScore(BookModel book) {
  if (book.languages != null) {
    if (book.languages.contains("eng") || book.languages.contains("tur")) {
      return 3;
    }
  }

  if (isLatinText(book.title)) {
    return 2;
  }

  return 1;
}
```

---

## 2. Latin Character Detection

```dart id="latin_check"
bool isLatinText(String text) {
  final latinRegex = RegExp(r'^[a-zA-Z0-9\s\-\.,:;\'\"!?()]+$');
  return latinRegex.hasMatch(text);
}
```

---

## 3. Sorting Logic

Before returning book list:

```dart id="sorting"
books.sort((a, b) {
  final scoreA = getLanguageScore(a);
  final scoreB = getLanguageScore(b);

  return scoreB.compareTo(scoreA);
});
```

---

## 4. Filtering (Optional for MVP)

If strict filtering is needed:

```dart id="filtering"
books = books.where((book) {
  return getLanguageScore(book) >= 2;
}).toList();
```

---

## 5. Description Normalization

Handle multiple formats:

```dart id="description_parse"
String? parseDescription(dynamic description) {
  if (description == null) return null;

  if (description is String) return description;

  if (description is Map && description["value"] != null) {
    return description["value"];
  }

  return null;
}
```

---

## 6. Fallback Strategy

If no high-quality data:

* allow fallback book
* but ensure:

  * title is not empty
  * cover fallback exists

---

# 🔄 REPOSITORY RULES

Every list returned from API MUST:

1. Normalize fields
2. Apply language scoring
3. Sort results
4. Return cleaned entities

---

# 📊 ENTITY OUTPUT RULE

Final BookEntity must contain:

```dart id="entity"
id
title
coverUrl
authorNames
description
```

All fields must be:

* safe (null handled)
* clean (no raw API data)

---

# ⚡ PERFORMANCE

* Apply sorting once per response
* Do NOT re-sort in UI
* Avoid heavy regex in loops (optimize if needed)

---

# 🧪 EDGE CASES

Handle:

* missing language field
* null title
* mixed language arrays
* empty results

---

# 🚫 ANTI-PATTERNS

* ❌ No filtering in UI
* ❌ No direct API data usage
* ❌ No assumption that language always exists
* ❌ No blocking UI for filtering

---

# 🎯 EXPECTED OUTPUT

* English and Turkish books appear first
* Latin titles appear second
* Other languages appear last (or filtered out)

User should mostly see readable content.

---

# 🔥 FINAL RULE

Remote book data can be inconsistent across sources.

Your job is to:

* clean it
* prioritize it
* make it user-friendly

Always prefer better UX over raw data accuracy.
