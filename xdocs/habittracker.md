# 📊 Reading Habit Tracker (Full Implementation Rules)

## 🎯 Goal

Build a complete reading habit tracking system that allows users to:

* Log daily reading activity (pages + minutes)
* Track reading streaks
* View reading statistics
* Set reading goals
* Access quick logging from profile

This system must be:

* fast
* simple
* motivating

---

# 🧱 Architecture (STRICT)

UI → Provider → UseCase → Repository → Supabase

DO NOT put business logic inside UI.

---

# 📂 Feature Structure

```id="habit_structure"
features/habit/
 ├── presentation/
 │    ├── pages/habit_page.dart
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

# 🧠 CORE CONCEPT

Tracking must support BOTH:

* minutes_read (habit tracking)
* pages_read (book progress)

These must be optional but at least ONE is required per log.

---

# 🧠 ENTITIES

```dart id="habit_entities"
class ReadingLogEntity {
  final String id;
  final String userId;
  final String? bookId;
  final int minutesRead;
  final int pagesRead;
  final DateTime date;
  final DateTime createdAt;
}

class ReadingStatsEntity {
  final int totalMinutes;
  final int totalPages;
  final int currentStreak;
  final int longestStreak;
}
```

---

# 🗄️ DATABASE (Supabase)

## Table: reading_logs

```id="reading_logs_table"
id: uuid (primary key)
user_id: uuid
book_id: text (nullable)
date: date
minutes_read: integer (default 0)
pages_read: integer (default 0)
created_at: timestamp
```

---

## Rules

* one user can have MULTIPLE logs per day
* aggregation must be done in queries

---

## Indexes

* (user_id, date)
* (user_id, created_at)

---

# ⚙️ REPOSITORY METHODS

```dart id="habit_repo"
Future<void> addReadingLog({
  String? bookId,
  int minutesRead,
  int pagesRead,
});

Future<List<ReadingLogEntity>> getLogsByDateRange(
  DateTime start,
  DateTime end,
);

Future<ReadingStatsEntity> getReadingStats();

Future<bool> hasReadToday();
```

---

# 🔥 BUSINESS LOGIC

---

## 1. Add Reading Log

Rules:

* at least one must be > 0:

  * minutesRead
  * pagesRead

* date = today

---

## 2. Streak Calculation (CRITICAL)

Definition:

* streak = consecutive days with at least 1 log

---

### Algorithm:

1. get logs grouped by date
2. sort descending
3. count consecutive days from today

---

## 3. Longest Streak

* calculate max consecutive sequence

---

## 4. Today Status

* if any log exists today → true

---

# 🔄 STATE MANAGEMENT (Riverpod)

Create providers:

```dart id="habit_providers"
readingLogsProvider
readingStatsProvider
todayReadingProvider
```

---

## Provider Rules

* cache results
* update instantly after new log
* avoid full refetch

---

# 📱 UI STRUCTURE

---

## 1. Profile Widget (SUMMARY)

Must include:

* 🔥 current streak
* “Did you read today?”
* quick add button

---

## 2. Habit Page (DETAIL)

```id="habit_layout"
Scaffold
 ├── AppBar
 ├── StatsSection
 ├── CalendarSection
 ├── ChartSection
 ├── LogsList
```

---

# 🧩 UI COMPONENTS

---

## 1. Quick Add Modal (CRITICAL)

Fields:

* minutes input
* pages input
* optional book selector

---

### Buttons:

* +10 min
* +5 pages

---

### Validation:

* at least one field > 0

---

## 2. Streak Widget

Show:

* current streak
* longest streak

---

## 3. Calendar View

* highlight days with activity
* GitHub style grid

---

## 4. Chart Section

* daily reading (bar chart)
* weekly aggregation

---

## 5. Logs List

* show past entries
* grouped by date

---

# 🎯 GOAL SYSTEM (OPTIONAL MVP+)

Allow user to set:

* daily minutes goal
* weekly pages goal

---

# ⚡ UX RULES

* logging must take < 3 seconds
* show instant feedback
* no complex forms
* use optimistic updates

---

# 🧪 EDGE CASES

Handle:

* user not logged in
* duplicate entries
* invalid values

---

# 🔐 SECURITY

* RLS:
  user_id = auth.uid()

---

# 🚫 ANTI-PATTERNS

* ❌ no heavy calculations in UI
* ❌ no blocking operations
* ❌ no complex input forms
* ❌ no forced book selection

---

# ⚡ PERFORMANCE

* cache stats
* aggregate in DB queries
* avoid large data loads

---

# 🎯 EXPECTED OUTPUT

User can:

* log reading daily
* track streak
* view stats
* see calendar activity

---

# 🔥 FINAL RULE

This system must:

* be fast
* be addictive
* encourage daily usage

Focus on simplicity and feedback.
