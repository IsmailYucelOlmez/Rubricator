# Rubricator Privacy Policy

**Last updated:** 28.07.2026  
**App:** Rubricator (Flutter-based, iOS/Android/Web/Desktop)  
**Developer / Data Controller:** İsmail Yücel Ölmez  
**Contact:** support@rubricator.app

---

## 1. Introduction

Rubricator ("the app", "we", "our") is a mobile/desktop application that offers book discovery, personal reading tracking, book notes/reviews, reading lists, and AI-assisted book features.

This Privacy Policy explains which data is collected when you use Rubricator, how that data is used, with whom and why it is shared, how long it is retained, and your rights over your data. The policy was prepared by reviewing the app’s actual technical architecture (including Supabase, a custom API server, and Google Gemini–based AI features).

By using the app, you accept the data processing activities described in this policy. If you do not accept the policy, please do not use the app.

---

## 2. What Data We Collect

### 2.1 Information You Provide When Creating an Account

Accounts in Rubricator are created with an email address and password (one-tap third-party sign-in — Google/Apple Sign-In — is **not** used). Data we collect during registration and authentication:

- Your email address
- Your password (passwords are not stored on our servers; they are stored securely (hashed) by our authentication provider, Supabase Auth, and are never kept in plain text)
- Username / display name
- (If applicable) one-time codes (OTP) created during email verification / password reset

### 2.2 Profile Information

- Profile photo (optional; you may upload an image from your gallery; gallery access is requested only when you start an upload)
- Other information you choose to show on your profile

### 2.3 Content You Create in the App

The following content you create while using the app is stored and associated with your account:

- Book reviews and ratings (out-of-10 rating system)
- Book notes and quotes
- Reading lists (social lists) you create and books you add to them
- Favorite books
- “Read / reading” statuses, reading logs, and completed-book records
- Likes on reviews, lists, and content
- Habit tracker data — e.g. reading goal/streak records
- In-app search history (search records may be kept to improve recommendation quality)

### 2.4 Data Processed for AI Features

Rubricator offers the following AI-assisted features. Inputs for these features are sent to **Google Gemini** models (embedding and gemini-2.5-flash):

**a) Semantic Book Discovery (Virgil / Semantic Discovery):**  
Natural-language search queries (e.g. “suggest a short novel about loneliness”) are sent via our own server (FastAPI backend) to the Google Gemini API to produce relevant book recommendations.

**b) Document Chat (Q&A with PDF/EPUB):**  
If you use this feature, **PDF or EPUB files** you upload from your device are temporarily transferred to our server, chunked, vectorized (embedding), and sent to Google Gemini models to answer your questions.
- Uploaded documents and related session data are **not permanently stored in our database**; they are held temporarily (in memory/cache) for the session and deleted after a timeout (TTL) or when you end the session.
- This feature is entirely optional; this processing does not occur unless you upload a document.

**c) Book Chat / Recommendations (Virgil):**  
Questions and recommendations about books are likewise sent to the AI provider. Usage may be limited by daily quotas; anonymous usage counters (e.g. daily request counts) may be kept for this purpose.

> **Important:** Data sent to the AI provider (Google Gemini) is subject to that provider’s own privacy policy and data-processing terms. We advise against uploading documents that contain sensitive personal data (identity, health, financial information, etc.) to Document Chat.

### 2.5 Book Catalog Data (Third-Party Sources)

Book search, cover images, descriptions, and author information are fetched from the **Google Books API** via a proxy on our server. This data belongs to books and does not contain personal data about you.

### 2.6 Automatically Collected Technical Data

- **Crash/error reports:** We use **Sentry** to monitor app stability. When an error occurs, device/OS info, app version, stack trace, and context (e.g. which screen you were on) are sent to Sentry. These reports do not, by default, include direct identifiers such as name or email.
- **Connectivity status:** Whether you have an internet connection is checked only on-device; this information is not sent to our servers.
- **Local notification data:** Reading reminders are scheduled entirely on your device using the OS notification/timer infrastructure; this data is not sent to our servers.

### 2.7 Device Permissions

Rubricator may request the following permissions:

| Permission | Purpose |
|---|---|
| Internet access | Communicate with our servers and third-party services |
| Send notifications | Reading reminders and in-app notifications |
| Exact alarm / timer | Show reading reminders at the time you set |
| Gallery / file access | Upload a profile photo; select PDF/EPUB for Document Chat |

Location, camera, contacts, microphone, and similar permissions are **not** requested by the app.

---

## 3. Why We Process Your Data

We process your data to:

- Create your account, verify your identity, and manage your session securely
- Provide core features such as book discovery, search, favorites, lists, notes, and reviews
- Run AI-assisted semantic search, book recommendations, and Document Chat
- Offer personalized book recommendations (based on your reading history and interactions)
- Send reading reminders and habit-tracker notifications
- Monitor app performance and detect/fix bugs
- Prevent abuse and enforce service quotas (e.g. daily AI usage limits)
- Comply with legal obligations and protect user safety

Your data is processed on the legal bases of **consent** (e.g. choosing to use AI features), **performance of a contract** (providing your account and the service), and **legitimate interest** (security, bug fixing, service improvement).

---

## 4. Where Data Is Stored and Security

Your data is hosted on the following infrastructure:

- **Supabase** (PostgreSQL database, authentication, file storage, and serverless functions) — account data, user content, book catalog cache, and profile photos. Access is limited by Row Level Security policies; only your own data and content marked as public is accessible.
- Our own **API server (FastAPI)** — processes semantic search and Document Chat requests; Document Chat session data is held non-persistently (temporarily).
- **Google Gemini API** — used to process AI-based search, recommendation, and Document Chat requests.
- **Sentry** — used to collect crash/error reports.

Measures we take to protect your data include:

- All communication uses encrypted connections (HTTPS/TLS)
- Passwords are never stored in plain text
- Database access is scoped to the account owner via Row Level Security
- Server-side authorization and access-control mechanisms are applied

No internet-based system or data transmission method can be guaranteed 100% secure; however, we take reasonable technical and organizational measures to protect your data.

---

## 5. Data Sharing

We do **not** sell your personal data. Your data is shared only in the following cases and with the following parties:

| Recipient | Shared data | Purpose |
|---|---|---|
| Supabase | Account, profile, user content | Hosting, database, authentication, file storage |
| Google Gemini (Google) | Your search queries, uploaded document contents, chat messages | AI-assisted search/recommendation/Document Chat |
| Google Books API | Book search terms | Fetch book catalog data (does not contain personal data) |
| Sentry | Device/app technical info, error traces | Debugging and stability monitoring |

Your data may also be shared:

- To comply with a legal obligation, court order, or official authority request
- To protect the safety, rights, or property of our users, the app, or third parties
- In the event of a merger, acquisition, or asset sale (in which case you will be notified in advance)

---

## 6. Public Content

As a social reading platform, Rubricator allows some content to be **public**. The following may be visible to other users (and in some cases to visitors who are not signed in), by default or according to your preference:

- Reading lists you share publicly
- Your book reviews, ratings, notes, and quotes (shown with your username)
- Likes you give or receive

Even if you delete public content, it may already have been viewed, copied, or shared by others; we have no control over such secondary sharing.

---

## 7. Data Retention Periods

- Account and content data are retained while your account is active.
- Files and session data uploaded for Document Chat are **automatically deleted** shortly after processing completes / the session expires; they are not stored permanently.
- When you request account deletion, your account profile and personal data are deleted **within 7 days** after the request is verified. Some data may be retained for up to **30 additional days** where required by legal obligations (e.g. accounting/transaction records).
- Crash/error reports are subject to Sentry’s own retention policy.

---

## 8. Your Rights

Under Türkiye’s Personal Data Protection Law (KVKK) and/or the General Data Protection Regulation (GDPR), to the extent applicable, you have the right to:

- Learn whether your personal data is being processed
- Request information about your processed data
- Access your data and obtain a copy (in a portable format)
- Request correction of inaccurate or incomplete data
- Request deletion or destruction of your data
- Object to processing or withdraw consent (for consent-based processing such as AI features)
- Object to outcomes produced solely by automated analysis that are adverse to you
- Seek redress if you suffer damage due to unlawful processing

You may exercise these rights via the contact channel below.

---

## 9. Account and Data Deletion

To delete your account and associated data:

1. Email **support@rubricator.app**.
2. Use the subject line **"Account Deletion Request"**.
3. Include the email address registered with Rubricator in the message body.

After your request is verified, your account profile and personal data are deleted **within 7 days**; limited data required for legal retention may be kept for up to **30 additional days**.

---

## 10. Children’s Privacy

Rubricator is **not directed at children under 13** and does not knowingly collect data from that age group. If we learn that a child under 13 has provided us personal data, we will delete it within a reasonable time. If you are a parent or guardian and believe your child has provided us data, please contact us at support@rubricator.app.

---

## 11. Local Storage (Data Stored on Device)

The app stores some preferences and cache data (e.g. session info, theme preference, temporary content cache) locally on your device. This data is removed when you uninstall the app and is not automatically sent to our servers.

---

## 12. International Data Transfers

Our infrastructure providers (Supabase, Google, Sentry) may process your data on servers outside Türkiye (e.g. the European Union or the United States). For such transfers, we rely on the security and compliance mechanisms offered by those providers (standard contractual clauses, data processing agreements, etc.).

---

## 13. Third-Party Services and Links

The app may contain links to third-party websites or resources (e.g. external links opened via `url_launcher`). Those third-party sites have their own privacy policies; this policy covers only Rubricator’s own data processing.

Main third-party services we use:

- [Supabase Privacy Policy](https://supabase.com/privacy)
- [Google Privacy Policy](https://policies.google.com/privacy) (for Gemini API and Google Books API)
- [Sentry Privacy Policy](https://sentry.io/privacy/)

---

## 14. Changes to This Policy

We may update this Privacy Policy from time to time. For material changes, we may notify you via an in-app notice or email. The current policy is always published with the “Last updated” date at the top of this page. We recommend reviewing the policy regularly.

---

## 15. Contact

For questions, requests, or complaints about this Privacy Policy or the processing of your personal data:

**Rubricator**  
Email: **support@rubricator.app**  
Developer: İsmail Yücel Ölmez

By using Rubricator, you agree to this Privacy Policy.
