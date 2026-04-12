# 📚 AI-Powered Book Discovery App (Flutter)

## 🎯 Project Goal

Build a modern, scalable Flutter mobile application that allows users to discover books, save favorites, and get AI-powered summaries using Google Books data.

The app should feel like a **next-generation version of a book platform similar to 1000Kitap**, but with:

* AI features
* clean UX
* personalization

---

## 🧱 Tech Stack

### Frontend

* Flutter (latest stable)
* Riverpod (state management)
* Dio (API client)

### Backend (No custom backend)

* Google Books API (book data)
* Firebase / Appwrite (Auth + Database)

### AI

* OpenAI API (summarization & recommendation)

---

## 📂 Project Structure

```
lib/
 ├── core/
 │    ├── constants/
 │    ├── theme/
 │    └── utils/
 │
 ├── features/
 │    ├── auth/
 │    ├── books/
 │    │    ├── data/
 │    │    ├── domain/
 │    │    └── presentation/
 │    ├── favorites/
 │    └── ai/
 │
 ├── services/
 │    ├── api_service.dart
 │    ├── ai_service.dart
 │    └── auth_service.dart
 │
 └── main.dart
```

---

## 🧠 Core Features (MVP)

### 1. Book Discovery

* Search books
* List trending/popular books
* Show book details (cover, description, author)

### 2. AI Summary (Critical Feature)

* Generate short summary of a book
* Show key ideas
* Cache results to avoid repeated API calls

### 3. Authentication

* User signup/login
* Persist session

### 4. Favorites

* Add/remove books
* User-specific favorite list

### 5. Recommendations

* Basic: category-based
* Advanced (optional): AI-powered suggestions

---

## ⚙️ Development Rules (IMPORTANT)

### General

* Write clean, modular, reusable code
* Follow feature-based architecture
* Avoid large widgets (max ~200 lines)

### State Management

* Use Riverpod ONLY
* Do not use setState for business logic

### API Layer

* Use Dio
* Create a centralized API service
* Handle:

  * errors
  * timeouts
  * logging

### AI Usage

* All AI calls must go through `ai_service.dart`
* Cache responses locally (Hive or SharedPreferences)
* Never call AI directly from UI

### UI/UX

* Minimal and modern design
* Use consistent spacing and typography
* Add loading states (skeletons or spinners)

---

## 🚫 What NOT to Build (for MVP)

* No chat system
* No complex social network
* No real-time features
* No microservices

Focus on **quality over quantity**

---

## 📦 API Guidelines

### Google Books

* Use `/volumes` search
* Use `/volumes/{id}` for details
* Handle missing/null fields

### AI (OpenAI)

* Limit token usage
* Keep summaries concise (max 150-200 words)

---

## 🧪 Testing

* Test API responses
* Handle edge cases:

  * empty results
  * network failure
  * invalid data

---

## 🚀 Performance

* Cache API responses
* Lazy load lists
* Avoid unnecessary rebuilds

---

## 📅 Development Plan

Week 1-2:

* Setup project
* API integration
* Book listing

Week 3-4:

* Book detail
* Auth system
* Favorites

Week 5:

* AI integration

Week 6:

* Recommendation system

Week 7:

* UI polish

Week 8:

* Testing & release prep

---

## 🧩 Future Improvements

* Social features (comments, discussions)
* Advanced recommendation engine
* Offline-first support
* Gamification (badges, streaks)

---

## 💡 Cursor AI Instructions

When generating code:

* Prefer small, composable widgets
* Use Riverpod providers properly
* Follow folder structure strictly
* Do not introduce unnecessary dependencies
* Always separate UI and business logic
* Write null-safe Dart code

---

## 🎯 Success Criteria

* App runs smoothly
* Clean UI
* AI summary works reliably
* Codebase is maintainable and scalable

---

## 🔥 Final Note

This is not just a demo project.

Build it like a **real product**:

* clean
* fast
* focused

Avoid overengineering.
