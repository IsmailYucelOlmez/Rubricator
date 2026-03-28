# 🔐 Supabase Integration Rules (Flutter Project)

## 🎯 Goal

Integrate Supabase as the backend service for:

* Authentication
* Database (favorites, user data)
* Optional: Realtime (future)

The implementation must be clean, modular, and production-ready.

---

## 🧱 Tech Requirements

* Use `supabase_flutter` package
* Follow null-safe Dart
* Use Riverpod for state management
* Do NOT mix Supabase calls directly inside UI

---

## 📦 Packages

Ensure the following is installed:

* supabase_flutter
* flutter_riverpod
* dio (already used for APIs)

---

## 🔑 Environment Setup

* Use `.env` file for keys
* NEVER hardcode:

  * Supabase URL
  * Anon Key

Example:

```id="env_example"
SUPABASE_URL=your_url
SUPABASE_ANON_KEY=your_key
```

---

## 🧩 Project Structure (Supabase Layer)

Create a dedicated structure:

```id="supabase_structure"
lib/
 ├── services/
 │    └── supabase_service.dart
 │
 ├── features/
 │    ├── auth/
 │    │    ├── data/
 │    │    ├── domain/
 │    │    └── presentation/
 │    │
 │    ├── favorites/
 │    │    ├── data/
 │    │    ├── domain/
 │    │    └── presentation/
```

---

## 🔐 Authentication Rules

### Features to implement:

* Sign up (email + password)
* Sign in
* Sign out
* Session persistence

### Rules:

* Use Supabase Auth ONLY
* Handle errors properly
* Expose auth state via Riverpod

### Example Responsibilities:

* auth_service.dart → all auth calls
* auth_provider.dart → state management

---

## ❤️ Favorites (Database)

### Table: `favorites`

Structure:

```id="favorites_table"
id: uuid (primary key)
user_id: uuid (foreign key)
book_id: text
created_at: timestamp
```

---

### Required Features:

* Add book to favorites
* Remove from favorites
* Get user favorites list

---

### Rules:

* Always filter by `user_id`
* Never expose all data
* Use Supabase Row Level Security (RLS)

---

## 🔒 Security (VERY IMPORTANT)

Enable RLS on all tables.

Example policy:

```id="rls_policy"
user_id = auth.uid()
```

Rules:

* Users can only access their own data
* No public write access

---

## ⚙️ Supabase Service Layer

Create a centralized service:

`supabase_service.dart`

Responsibilities:

* Initialize Supabase client
* Provide reusable methods
* Handle errors globally

---

## 🧠 Riverpod Integration

* Create providers for:

  * auth state
  * favorites list

Example:

* authProvider
* favoritesProvider

---

## 🚫 Anti-Patterns (DO NOT DO)

* ❌ Do NOT call Supabase directly in UI
* ❌ Do NOT duplicate queries
* ❌ Do NOT skip error handling
* ❌ Do NOT store sensitive data locally

---

## ⚡ Performance

* Cache favorites locally if needed
* Avoid unnecessary refetch
* Use async/await properly

---

## 🧪 Error Handling

Handle:

* network errors
* auth errors
* empty states

Return meaningful messages

---

## 🔄 Future Ready

Structure must support:

* adding comments system
* adding reading progress
* adding social features

---

## 💡 Cursor Instructions

When generating code:

* Create clean service classes
* Use async/await (no callbacks)
* Keep functions small and reusable
* Separate data / domain / UI layers
* Follow feature-based architecture
* Use typed models (no dynamic)

---

## 🎯 Expected Output

* Fully working auth system
* Favorites CRUD working
* Clean architecture
* Secure database access (RLS enabled)

---

## 🔥 Final Rule

If something is unclear:
→ choose simplicity over complexity
→ choose maintainability over speed
