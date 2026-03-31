# 📚 Home Page (Explore / Discover) – Full Implementation Rules

## 🎯 Goal

Build a modern, scalable Home Page that allows users to:

* Discover popular books
* Browse books by genre
* Search books quickly
* Navigate to book detail pages

This page must feel like a **Netflix-style discovery experience**, not a static list.

---

# 🧱 Architecture (STRICT)

Follow clean architecture:

* presentation → UI
* domain → entities + usecases
* data → models + repositories + services

DO NOT skip layers.

---

# 📂 Feature Structure

```id="home_structure"
features/home/
 ├── presentation/
 │    ├── pages/home_page.dart
 │    ├── widgets/
 │    └── providers/
 │
 ├── domain/
 │    ├── entities/
 │    └── usecases/
 │
 ├── data/
 │    ├── models/
 │    ├── repositories/
 │    └── datasources/
```

---

# 🌐 DATA SOURCE

Use Open Library API

---

## Required Endpoints

### 1. Genre Books

GET /subjects/{genre}.json

### 2. Search

GET /search.json?q={query}

---

# 🧠 ENTITIES

You MUST define:

```id="entities_home"
BookEntity {
  id
  title
  coverUrl
  authorNames
}
```

---

# ⚙️ REPOSITORY METHODS

```dart id="home_repo"
Future<List<BookEntity>> getBooksByGenre(String genre);

Future<List<BookEntity>> searchBooks(String query);

Future<List<BookEntity>> getPopularBooks();
```

---

## ⚠️ Popular Books Logic

Open Library does NOT provide real popular data.

You MUST simulate:

* use a fixed query (e.g. "bestseller")
  OR
* use a default genre (e.g. fiction)

---

# 🔄 STATE MANAGEMENT (Riverpod)

Create providers:

```dart id="providers_home"
popularBooksProvider
genreBooksProvider (family)
searchProvider
```

---

## Provider Rules

Each provider must handle:

* loading state
* error state
* data state

---

# 📱 UI STRUCTURE (STRICT)

Use:

```id="home_layout"
Scaffold
 ├── AppBar (search bar)
 ├── CustomScrollView
 │    ├── PopularSection
 │    ├── GenreSection (multiple)
```

---

# 🧩 UI COMPONENTS

---

## 1. AppBar (Search)

### Requirements:

* search input field
* debounce input (300–500ms)

### Behavior:

* if query empty → show home sections
* if query exists → show search results

---

## 2. Popular Section

### UI:

* horizontal scroll
* large book cards

### Logic:

* call popularBooksProvider

---

## 3. Genre Sections

### Genres (fixed list):

* fantasy
* science_fiction
* romance
* mystery

---

### UI:

* title (genre name)
* horizontal scroll list

---

### Logic:

* each section calls:
  genreBooksProvider(genre)

---

## 📚 Book Card Component

Must include:

* cover image
* title
* author (optional)

---

### Behavior:

* onTap → navigate to Book Detail Page

---

# ⚡ UX RULES

* horizontal scrolling for all sections
* fast loading (show skeletons)
* avoid text-heavy UI
* focus on images (book covers)

---

# 🔍 SEARCH BEHAVIOR

---

## Input Handling

* debounce user input
* min 2 characters

---

## Display

If searching:

* replace home content
* show vertical list of results

---

## Edge Cases

* no results → show "No books found"
* loading → show spinner

---

# ⚡ PERFORMANCE

* cache genre results
* avoid refetch on scroll
* lazy load lists

---

# 🧪 ERROR HANDLING

Handle:

* network errors
* empty responses

Show friendly messages

---

# 🚫 ANTI-PATTERNS

* ❌ no API calls in widgets
* ❌ no large nested widgets
* ❌ no blocking UI
* ❌ no duplicate requests

---

# 🎯 EXPECTED OUTPUT

User can:

* scroll through popular books
* browse books by genre
* search books
* navigate to book detail page

All data must come from Open Library API.

---

# 🔥 FINAL RULE

This page must feel:

* fast
* visual
* intuitive

It is a discovery engine, not a data list.
