# 📚 Google Books API Integration Rules (Flutter Project)

## 🎯 Goal

Integrate Google Books API to fetch and display book data in a scalable and clean way.

The system must support:

* Book search
* Book details
* Author details
* Related books

---

## 🌐 Base API

Base URL:
https://www.googleapis.com/books/v1

Covers: use `volumeInfo.imageLinks` (thumbnail / smallThumbnail), HTTPS.

---

## 📦 Endpoints to Use

### 1. Search Books

GET /volumes?q={query}&startIndex=&maxResults=

### 2. Volume details

GET /volumes/{volume_id}

### 3. Author details

No first-class author resource; use `inauthor:` queries or display name from volume.

### 4. Cover image

From `imageLinks` on the volume resource (not a separate cover-id service).

---

## 🧱 Architecture Rules

### MUST follow:

* Use layered architecture:

  * data
  * domain
  * presentation

* DO NOT call API directly from UI

---

## 📂 Folder Structure

```text
features/
 ├── books/
 │    ├── data/
 │    │    ├── models/
 │    │    ├── datasources/
 │    │    └── repositories/
 │    │
 │    ├── domain/
 │    │    ├── entities/
 │    │    └── usecases/
 │    │
 │    └── presentation/
 │         ├── pages/
 │         ├── widgets/
 │         └── providers/
```

---

## ⚙️ API Service Rules

* Use Dio for HTTP requests
* Create a single `api_service.dart`
* Handle:

  * timeouts
  * errors
  * logging

---

## 📊 Data Handling (CRITICAL)

Google Books responses are NOT clean.

### You MUST handle:

* null fields
* missing descriptions
* missing covers
* multiple author formats

---

### Example Problem Cases:

* description:

  * string OR object

* volumeInfo.authors:

  * sometimes missing

* volumeInfo.imageLinks:

  * may not exist

---

### Rule:

Always normalize API response into clean models.

---

## 🧩 Model Rules

Create strongly typed models:

* BookModel
* AuthorModel

Avoid:

* dynamic
* loosely typed maps

---

## 🔄 Mapping Rules

Convert API data → Domain entities

Example:

```id="mapping_rule"
BookModel → BookEntity
```

---

## 🖼️ Cover Handling

If `volumeInfo.imageLinks` has a thumbnail URL:
→ normalize to HTTPS and display

If NOT:
→ use placeholder image

---

## 🔍 Search Rules

* Implement debounce (300–500ms)
* Avoid sending request on every keystroke
* Minimum query length: 2 characters

---

## 📚 Pagination

* Use `startIndex` + `maxResults` (max 40)
* Implement infinite scroll
* Do NOT load all data at once

---

## ⚡ Performance Rules

* Cache search results (optional)
* Avoid duplicate requests
* Lazy load lists

---

## 🧪 Error Handling

Handle:

* empty results
* network failure
* API failure

Show user-friendly messages

---

## 🧠 Riverpod Integration

Create providers:

* bookSearchProvider
* bookDetailProvider

Use:

* FutureProvider
* StateNotifierProvider (if needed)

---

## 🚫 Anti-Patterns (STRICTLY FORBIDDEN)

* ❌ API call inside Widget
* ❌ Using setState for API data
* ❌ No error handling
* ❌ Ignoring null values
* ❌ Hardcoding URLs everywhere

---

## 💡 Cursor Instructions

When generating code:

* Create reusable services
* Keep models clean and typed
* Separate layers properly
* Handle edge cases explicitly
* Write readable and maintainable Dart code
* Use async/await

---

## 🎯 Expected Features

* Search books (working)
* Book detail page
* Author info
* Cover images displayed correctly

---

## 🔥 Final Rule

Google Books API is messy.

Your job is to:
→ clean the data
→ standardize it
→ make UI simple

Always prioritize:

* stability
* user experience
* clean architecture
