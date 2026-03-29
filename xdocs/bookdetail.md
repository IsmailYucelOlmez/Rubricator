# 📚 Book Detail Page – Full Implementation Rules (UI + Logic + Data)

## 🎯 Goal

Build a complete Book Detail feature that includes:

* UI rendering
* API integration (Open Library)
* User interactions (rating, reviews, quotes)
* Database operations (Supabase)
* State management (Riverpod)

This is NOT just a UI page.
It must be a fully working feature with real data flow.

---

# 🧱 Architecture (STRICT)

Follow clean architecture:

* presentation → UI
* domain → entities + usecases
* data → models + repositories + services

DO NOT skip layers.

---

# 📂 Feature Structure

```id="structure"
features/books/
 ├── presentation/
 │    ├── pages/book_detail_page.dart
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

# 📊 Data Flow (VERY IMPORTANT)

Flow must be:

UI → Provider → UseCase → Repository → API/Supabase

Return data back the same way.

---

# 📚 BOOK DATA (Open Library)

Use Open Library API

## Required operations:

### 1. Fetch Book Detail

* input: work_id
* fetch: /works/{id}.json

### 2. Normalize Data

Handle:

* description (string OR object)
* missing cover
* missing authors

---

# 🧠 ENTITIES

You MUST define:

```id="entities"
BookEntity
ReviewEntity
ExternalReviewEntity
QuoteEntity
RatingEntity
```

Each must be strongly typed (no dynamic).

---

# ⚙️ REPOSITORY METHODS

```id="repo_methods"
Future<BookEntity> getBookDetail(String id);

Future<void> addReview(ReviewEntity review);
Future<List<ReviewEntity>> getReviews(String bookId);

Future<void> addExternalReview(ExternalReviewEntity review);
Future<List<ExternalReviewEntity>> getExternalReviews(String bookId);

Future<void> addQuote(QuoteEntity quote);
Future<List<QuoteEntity>> getQuotes(String bookId);

Future<void> rateBook(RatingEntity rating);
Future<double> getAverageRating(String bookId);
```

---

# 🔐 DATABASE (Supabase)

Tables:

* reviews
* external_reviews
* quotes
* ratings

Rules:

* always filter by user_id
* enforce RLS
* no public writes

---

# 🔄 STATE MANAGEMENT (Riverpod)

Create providers:

```id="providers"
bookDetailProvider
reviewListProvider
externalReviewProvider
quoteProvider
ratingProvider
```

Each provider must handle:

* loading
* success
* error

---

# 📱 UI SECTIONS + LOGIC

---

## 1. Header Section

### UI:

* cover
* title
* author
* rating

### Logic:

* load book detail via provider
* display fallback if missing data

---

## 2. AI Section

### Logic:

* call ai_service
* cache result
* avoid duplicate calls

---

## 3. Rating Section

### Actions:

* user selects rating (1–5)

### Flow:

UI → provider → repository → Supabase

### Rules:

* update average after submit
* prevent duplicate rating (one per user)

---

## 4. Review Section (CRITICAL)

Supports TWO types:

---

### A. Internal Reviews

#### Actions:

* create review
* edit own review
* delete own review

#### Flow:

UI form → provider → repository → Supabase

#### Validation:

* content required
* min length: 10 chars

---

### B. External Reviews (DIFFERENTIATOR)

#### Actions:

* add external link

#### Flow:

UI form → provider → repository → Supabase

#### Validation:

* valid URL required
* title required

---

### UI Rules:

* Use tabs:

  * "User Reviews"
  * "External Reviews"

---

### External Review Behavior:

* show clickable link
* open with external browser
* DO NOT embed content

---

## 5. Quotes Section

### Actions:

* add quote
* like quote

### Validation:

* content required

---

## 6. Similar Books

### Logic:

* fetch from Open Library
* fallback to same author books

---

# ⚡ ACTION HANDLING RULES

Every user action must:

1. Show loading state
2. Call provider
3. Handle success
4. Handle error

---

# 🧪 ERROR HANDLING

Handle:

* API errors
* empty lists
* network failure

Show user-friendly messages

---

# ⚡ PERFORMANCE

* cache book detail
* cache AI summary
* avoid duplicate API calls

---

# 🚫 ANTI-PATTERNS

* ❌ No API calls in widgets
* ❌ No business logic in UI
* ❌ No unvalidated input
* ❌ No duplicated queries

---

# 🎯 EXPECTED OUTPUT

A fully working Book Detail feature where users can:

* view book data
* rate the book
* write reviews
* add external review links
* add quotes

All operations must be connected to real data sources.

---

# 🔥 FINAL RULE

This is not a static page.

It is an interactive system.

Focus on:

* correct data flow
* clean architecture
* smooth UX
