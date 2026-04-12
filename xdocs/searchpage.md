# 🔍 Search Page + Search Logs + Popular Searches (Full Implementation Rules)

## 🎯 Goal

Build a complete search system that includes:

* Book search (Google Books API)
* Search history tracking (per user)
* Global popular searches (most searched books)
* Efficient logging system (Supabase)

This is NOT just a search input.
It must be a **data-driven discovery system**.

---

# 🧱 Architecture (STRICT)

Follow clean architecture:

UI → Provider → UseCase → Repository → API / Supabase

---

# 📂 Feature Structure

```id="search_structure"
features/search/
 ├── presentation/
 │    ├── pages/search_page.dart
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

Use:

* Google Books API → for book search
* Supabase → for search logs & analytics

---

# 🧠 ENTITIES

```dart id="entities_search"
class SearchLogEntity {
  final String id;
  final String? userId;
  final String query;
  final String? bookId;
  final DateTime createdAt;
}

class BookEntity {
  final String id;
  final String title;
  final String? coverUrl;
}
```

---

# 🗄️ DATABASE (Supabase)

## Table: search_logs

```id="search_logs_table"
id: uuid (primary key)
user_id: uuid (nullable)
query: text
book_id: text (nullable)
created_at: timestamp
```

---

## Rules

* log BOTH:

  * search query
  * clicked book (optional)
* allow anonymous logs (user_id nullable)

---

## Indexes (IMPORTANT)

* index on query
* index on created_at
* index on book_id

---

# ⚙️ REPOSITORY METHODS

```dart id="search_repo"
Future<List<BookEntity>> searchBooks(String query);

Future<void> logSearch({
  required String query,
  String? bookId,
});

Future<List<String>> getPopularSearches();

Future<List<BookEntity>> getPopularBooks();
```

---

# 🔥 POPULAR SEARCH LOGIC

## Query-based popular searches:

```sql id="popular_queries"
SELECT query, COUNT(*) as count
FROM search_logs
GROUP BY query
ORDER BY count DESC
LIMIT 10;
```

---

## Book-based popular searches:

```sql id="popular_books"
SELECT book_id, COUNT(*) as count
FROM search_logs
WHERE book_id IS NOT NULL
GROUP BY book_id
ORDER BY count DESC
LIMIT 10;
```

---

# 🔄 STATE MANAGEMENT (Riverpod)

Create providers:

```dart id="search_providers"
searchProvider
popularSearchProvider
popularBooksProvider
searchHistoryProvider (optional)
```

---

# 📱 UI STRUCTURE

```id="search_layout"
Scaffold
 ├── AppBar (search input)
 ├── Body
 │    ├── if empty query:
 │    │     PopularSearchSection
 │    │     PopularBooksSection
 │    │
 │    ├── if typing:
 │    │     SearchResultsList
```

---

# 🧩 UI COMPONENTS

---

## 1. Search Input

### Rules:

* debounce: 300–500ms
* min length: 2 chars

---

### Behavior:

* on submit → log search
* on result click → log with book_id

---

## 2. Popular Searches Section

### UI:

* list of top queries
* clickable chips or list

---

### Behavior:

* clicking query → auto search

---

## 3. Popular Books Section

### UI:

* horizontal scroll
* book cards

---

### Behavior:

* click → go to detail page

---

## 4. Search Results

### UI:

* vertical list
* show:

  * cover
  * title

---

# ⚡ SEARCH FLOW

---

## Step 1:

User types → debounce → call searchBooks()

---

## Step 2:

Results displayed

---

## Step 3:

User selects book → logSearch(query, bookId)

---

## Step 4:

User submits query → logSearch(query)

---

# ⚡ PERFORMANCE RULES

* DO NOT log every keystroke
* ONLY log:

  * search submit
  * book click

---

# 🧪 EDGE CASES

Handle:

* empty query
* no results
* API failure

---

# 🔐 SECURITY

* RLS:

  * user_id = auth.uid() OR user_id IS NULL

---

# 🚫 ANTI-PATTERNS

* ❌ no logging on every keypress
* ❌ no duplicate logs spam
* ❌ no blocking UI
* ❌ no direct DB calls in UI

---

# 🎯 EXPECTED OUTPUT

User can:

* search books
* see popular searches
* see most searched books
* trigger search via suggestions

All interactions must be logged in Supabase.

---

# 🔥 FINAL RULE

Search is not just input.

It is:

* data collection system
* discovery engine

Design it to improve over time.
