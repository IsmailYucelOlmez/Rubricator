# 📚 Social Lists Module (FULL – Discovery + Creation + Social + Profile Integration)

## 🎯 Goal

Build a COMPLETE user-generated lists system similar to Letterboxd:

Users can:

* create lists
* add/reorder books
* write descriptions & notes
* like, comment, save lists
* explore other users' lists
* manage their own lists
* view lists in profiles

This module must feel like a **content platform**, not a simple CRUD feature.

---

# 🧱 Architecture (STRICT)

UI → Provider → UseCase → Repository → Supabase

DO NOT:

* call DB directly in UI
* mix business logic in widgets

---

# 📂 Feature Structure

```id="lists_structure"
features/lists/
 ├── presentation/
 │    ├── pages/
 │    │    ├── lists_feed_page.dart
 │    │    ├── list_detail_page.dart
 │    │    ├── create_edit_list_page.dart
 │    │    ├── user_lists_page.dart
 │
 │    ├── widgets/
 │    │    ├── list_card.dart
 │    │    ├── list_item_tile.dart
 │    │    ├── book_selector.dart
 │    │    ├── list_cover_preview.dart
 │    │    ├── like_button.dart
 │    │    ├── comment_section.dart
 │
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

```dart id="list_entities"
class ListEntity {
  final String id;
  final String userId;
  final String title;
  final String description;
  final bool isPublic;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
}

class ListItemEntity {
  final String id;
  final String listId;
  final String bookId;
  final int orderIndex;
  final String? note;
}

class ListComment {
  final String id;
  final String userId;
  final String listId;
  final String content;
  final DateTime createdAt;
}
```

---

# 🗄️ DATABASE (Supabase)

---

## lists

```sql id="lists_table"
id uuid PRIMARY KEY
user_id uuid
title text
description text
is_public boolean
created_at timestamp
```

---

## list_items

```sql id="list_items_table"
id uuid PRIMARY KEY
list_id uuid
book_id text
order_index integer
note text
```

---

## list_likes

```sql id="list_likes_table"
id uuid
user_id uuid
list_id uuid
```

---

## list_comments

```sql id="list_comments_table"
id uuid
user_id uuid
list_id uuid
content text
created_at timestamp
```

---

## saved_lists

```sql id="saved_lists_table"
id uuid
user_id uuid
list_id uuid
```

---

## Indexes (IMPORTANT)

* lists(user_id)
* list_items(list_id)
* list_likes(list_id)
* list_comments(list_id)

---

# ⚙️ REPOSITORY METHODS

```dart id="lists_repo"
Future<void> createList(...);
Future<void> updateList(...);
Future<void> deleteList(String listId);

Future<void> addBookToList(...);
Future<void> reorderListItems(...);
Future<void> removeBookFromList(...);

Future<List<ListEntity>> getFeedLists();
Future<List<ListEntity>> getPopularLists();
Future<List<ListEntity>> getUserLists(String userId);

Future<List<ListItemEntity>> getListItems(String listId);

Future<void> likeList(String listId);
Future<void> unlikeList(String listId);

Future<void> saveList(String listId);
Future<void> unsaveList(String listId);

Future<List<ListComment>> getComments(String listId);
Future<void> addComment(...);
```

---

# 🔄 STATE MANAGEMENT (Riverpod)

```dart id="lists_providers"
listsFeedProvider
popularListsProvider
userListsProvider
listDetailProvider
listItemsProvider

likeProvider
saveProvider
commentsProvider
```

---

# 📱 UI STRUCTURE

---

# 🟢 1. LISTS FEED PAGE

```id="lists_feed_layout"
Scaffold
 ├── AppBar
 ├── Tabs:
 │    ├── For You
 │    ├── Popular
 │    ├── Following
 │
 ├── ListView (ListCard)
```

---

## List Card UI

Must include:

* list title
* user name
* preview (3–4 book covers)
* like count

---

## Behavior:

* tap → List Detail
* like button (instant update)

---

# 🔵 2. LIST DETAIL PAGE

---

## Layout:

```id="list_detail_layout"
Header
 ├── title
 ├── description
 ├── user info
 ├── actions (like, save)

Book List
 ├── ordered list items

Comments Section
```

---

## Book Item:

* cover
* title
* optional note

---

## Features:

* reorder (owner only)
* edit/delete (owner only)

---

# 🟣 3. CREATE / EDIT LIST PAGE

---

## Fields:

* title
* description
* privacy toggle
* book selector

---

## Book Selector:

* search via Open Library
* add/remove books

---

## Reordering:

* drag & drop

---

# 🟡 4. USER LISTS PAGE

---

## Show:

* lists created by user
* saved lists

---

## Layout:

* grid or list

---

# 🔥 5. SOCIAL FEATURES

---

## Like System

* toggle like
* optimistic UI update

---

## Save System

* bookmark list
* accessible in profile

---

## Comments

* add comment
* list comments
* real-time optional

---

# 🔗 PROFILE INTEGRATION

---

## Profile Page:

Add section:

```text id="profile_lists"
My Lists
Saved Lists
```

---

# ⚡ DISCOVERY LOGIC

---

## Feed Types:

* popular (by likes)
* recent
* following users

---

## Sorting:

* like count DESC
* created_at DESC

---

# ⚡ PERFORMANCE RULES

* paginate lists
* lazy load items
* cache list previews

---

# 🧪 EDGE CASES

* empty list
* deleted books
* private list access

---

# 🔐 SECURITY (RLS)

* user can edit only own lists
* private lists only visible to owner

---

# 🚫 ANTI-PATTERNS

* ❌ no heavy joins in UI
* ❌ no blocking scroll
* ❌ no full list reload on like

---

# 🎯 EXPECTED OUTPUT

User can:

* create lists
* browse lists
* interact socially
* manage personal collections

---

# 🔥 FINAL RULE

This module must feel like:

👉 a social content platform
NOT just a list manager
