# 📊 Profile Stats Module (FULL – Summary + Detail + Integration)

## 🎯 Goal

Build a COMPLETE Profile Stats system that includes:

1. Stats Summary (for Profile Page)
2. Full Stats Page (detailed analytics)
3. Clean data flow (Supabase aggregation)
4. Efficient performance (no heavy loading on profile)

This module must answer:

👉 “What kind of reader is this user?”

NOT:

👉 “What did the user do today?” (habit tracker handles that)

---

# 🧱 Architecture (STRICT)

UI → Provider → UseCase → Repository → Supabase

DO NOT:

* put logic in UI
* fetch full stats on profile page

---

# 📂 Feature Structure

```id="stats_full_structure"
features/profile_stats/
 ├── presentation/
 │    ├── pages/
 │    │    ├── profile_stats_page.dart
 │    │
 │    ├── widgets/
 │    │    ├── stats_preview_card.dart
 │    │    ├── reading_identity_section.dart
 │    │    ├── library_stats_section.dart
 │    │    ├── rating_section.dart
 │    │    ├── content_stats_section.dart
 │    │
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

# 🧠 ENTITIES

```dart id="stats_entities_full"
class ProfileStatsSummary {
  final int completedBooks;
  final double averageRating;
  final String topGenre;
}

class GenreStat {
  final String genre;
  final int count;
}

class AuthorStat {
  final String author;
  final int count;
}

class RatingStat {
  final double averageRating;
  final Map<int, int> distribution;
}

class LibraryStat {
  final int toRead;
  final int reading;
  final int completed;
  final int dropped;
  final int favorites;
}

class ContentStat {
  final int reviewCount;
  final int quoteCount;
}
```

---

# 🗄️ DATABASE SOURCES (Supabase)

Use:

* user_books
* reviews
* quotes
* ratings

---

# ⚙️ REPOSITORY METHODS

```dart id="stats_repo_full"
Future<ProfileStatsSummary> getStatsSummary();

Future<List<GenreStat>> getGenreStats();
Future<List<AuthorStat>> getAuthorStats();

Future<RatingStat> getRatingStats();

Future<LibraryStat> getLibraryStats();

Future<ContentStat> getContentStats();
```

---

# 🔥 BUSINESS LOGIC

---

## 1. SUMMARY (CRITICAL)

Used in Profile Page.

Must be FAST.

### Includes:

* completed books count
* average rating
* top genre

---

## Rules:

* use aggregated queries
* limit processing
* avoid joins if possible

---

## 2. GENRE STATS

* use completed books
* group by genre
* sort descending
* limit top 5

---

## 3. AUTHOR STATS

* group completed books by author
* count

---

## 4. RATING STATS

* calculate average rating
* build star distribution

---

## 5. LIBRARY STATS

From user_books:

* count per status
* count favorites

---

## 6. CONTENT STATS

* count reviews
* count quotes

---

# 🔄 STATE MANAGEMENT (Riverpod)

```dart id="stats_providers_full"
profileStatsSummaryProvider

genreStatsProvider
authorStatsProvider
ratingStatsProvider
libraryStatsProvider
contentStatsProvider
```

---

## RULES

* summary provider → used in profile
* full providers → only in stats page
* cache all results
* avoid duplicate calls

---

# 📱 UI STRUCTURE

---

# 🟢 1. PROFILE PAGE INTEGRATION

## Component: StatsPreviewCard

---

## Behavior:

* shows summary only
* navigates to full stats page

---

## UI:

```text id="preview_ui"
📚 12 books
⭐ 4.2 avg
Top: Fantasy

→ View all stats
```

---

## Rules:

* MUST NOT load full stats
* MUST be fast (<100ms perceived)

---

# 🔵 2. STATS PAGE (DETAIL)

```id="stats_layout_full"
Scaffold
 ├── AppBar
 ├── SingleChildScrollView
 │    ├── ReadingIdentitySection
 │    ├── LibraryStatsSection
 │    ├── RatingSection
 │    ├── ContentStatsSection
```

---

# 🧩 UI COMPONENTS

---

## 1. Reading Identity

* genre chart
* top authors list

---

## 2. Library Stats

* card grid
* to_read / reading / completed / dropped / favorites

---

## 3. Rating Section

* average rating
* star distribution bars

---

## 4. Content Stats

* review count
* quote count

---

# 🔗 NAVIGATION FLOW

```text id="navigation_flow"
Profile Page
 └── StatsPreviewCard (tap)
       ↓
ProfileStatsPage
```

---

# ⚡ PERFORMANCE STRATEGY

---

## Profile Page:

* ONLY call summary provider

---

## Stats Page:

* lazy load sections
* load providers independently

---

## Caching:

* keep stats in memory
* avoid refetch on navigation

---

# 🧪 EDGE CASES

Handle:

* no data → show “No data yet”
* null values → safe fallback

---

# 🚫 ANTI-PATTERNS

* ❌ no heavy queries on profile
* ❌ no UI-based aggregation
* ❌ no duplicate API calls
* ❌ no blocking rendering

---

# ⚡ PERFORMANCE RULES

* aggregation MUST be done in DB
* minimize payload
* avoid nested loops in client

---

# 🎯 EXPECTED OUTPUT

User can:

* see quick stats in profile
* navigate to full analytics page
* understand reading behavior

---

# 🔥 FINAL RULE

This module must be:

* fast (summary)
* deep (detail page)
* scalable (modular providers)

---

Focus on:

👉 clarity
👉 performance
👉 meaningful insights
