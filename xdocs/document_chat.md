# Belge Sohbeti (PDF / EPUB Kitap QA) – Entegrasyon Dökümanı

> **Kapsam:** `bookapp-api` document-chat modülünün BookApp (Flutter) istemcisine entegrasyonu.  
> **API kaynağı:** `bookapp-api/app/api/routers/sessions.py`  
> **API detay spesifikasyonu:** `bookapp-api/docs/DOCUMENT_CHAT_INTEGRATION.md`  
> **Hedef:** Kullanıcının yüklediği PDF veya EPUB dosyası üzerinde doğal dilde soru-cevap (RAG).

---

## Amaç

Kullanıcıların **kendi yükledikleri** kitap dosyaları (PDF veya EPUB) hakkında soru sormasını sağlamak:

- *"Ana karakterin motivasyonu nedir?"*
- *"Bu bölümde hangi temalar işleniyor?"*
- *"Yazarın argümanını özetle."*

Bu sistem:

- Mevcut **semantik kitap keşfi** (`features/semantic_discovery/`) ile **çakışmaz** — o katalog tabanlı kitap önerisidir; bu **kullanıcı belgesi Q&A**'dır.
- Mevcut **Google Books arama** (`SearchPage` keyword sekmesi) ile **tamamlar** — katalogda olmayan veya kullanıcının elindeki dosya üzerinde çalışır.
- **Supabase migration gerektirmez** — oturum verisi sunucuda geçicidir; kalıcı kullanıcı verisi yazılmaz.

---

## Mimari Özet

```
┌─────────────────────────────────────────────────────────────────────────┐
│  Flutter (BookApp)                                                       │
│  features/document_chat/  (planlanan)                                    │
│    UI → Provider → UseCase → Repository → Dio (multipart + JSON)       │
│    Upload → poll GET /sessions/{id} → chat                               │
│    Chat geçmişi yalnızca client state (SharedPreferences opsiyonel)      │
└──────────────────────────────┬──────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  FastAPI (bookapp-api) — aynı servis, farklı router                      │
├──────────────────────────────┬──────────────────────────────────────────┤
│  Mevcut: semantic modülü      │  Document-chat modülü                     │
│  POST /semantic/search        │  POST /sessions  (anında 201 + processing) │
│  Kalıcı: book_catalog         │  BackgroundTasks → extract/chunk/embed   │
│  pgvector (Supabase)          │  GET  /sessions/{id}  (status + progress)  │
│  Kitap önerisi                │  POST /sessions/{id}/chat (yalnızca ready) │
│                               │  DELETE /sessions/{id}                     │
│                               │  Ephemeral session store (memory/Redis)    │
└──────────────────────────────┴──────────────────────────────────────────┘
                               │
                               ▼
                        Google Gemini
                   (embedding-001 + gemini-2.5-flash)
                   Paralel batch embedding (ThreadPool)
```

### Sorumluluk ayrımı

| Katman | Sorumluluk |
|--------|------------|
| **FastAPI** | Dosya doğrulama, arka planda extract/chunk/embed, progress güncelleme, RAG, oturum TTL |
| **Flutter** | Dosya seçimi, upload, **status polling**, progress UI, chat, hata/limit mesajları |
| **Supabase** | Bu özellik için **kullanılmaz** (auth isteğe bağlı; QA verisi yazılmaz) |

### Zorunlu mimari kural (mevcut projeyle uyumlu)

```
UI → Provider → UseCase → Repository → FastAPI (Dio)
```

- FastAPI çağrıları **UI içinde yapılmamalı**.
- `SemanticApiDataSource` ile **aynı base URL ve API key** kullanılır; ayrı env gerekmez.
- Upload yanıtı hızlıdır; uzun bekleyen iş **polling** ile takip edilir (aşağıda).

---

## Mevcut sistemlerle ilişki

| Özellik | Semantik keşif | Belge sohbeti |
|---------|----------------|---------------|
| Girdi | Serbest metin sorgusu | PDF / EPUB dosyası |
| Veri kaynağı | `book_catalog` (pgvector) | Kullanıcının yüklediği dosya |
| Kalıcılık | Katalog kalıcı | Oturum geçici (TTL) |
| Çıktı | Kitap kartları | Metin cevap + kaynak alıntıları |
| Supabase | Evet (katalog, log) | Hayır |
| Flutter feature | `semantic_discovery/` (mevcut) | `document_chat/` (planlanan) |
| API prefix | `/api/v1/semantic/*` | `/api/v1/sessions/*` |

### SearchPage yerleşimi (öneri)

Mevcut `SearchPage` iki sekmeli:

1. **Keyword** — Google Books arama
2. **Semantic** — `SemanticDiscoveryView`

Üçüncü sekme veya ayrı giriş noktası:

3. **Kitabımla sor** — `DocumentChatView` (dosya yükle + sohbet)

Alternatif: profil veya kitap detayından "Kendi dosyamı yükle" FAB. Ürün kararı implementasyon öncesi netleştirilmeli.

---

## API durumu (bookapp-api)

Document-chat modülü **kodlanmış ve router kayıtlı** durumdadır. Önemli davranış değişiklikleri:

1. **Arka plan işleme** — `POST /sessions` dosyayı okuyup hemen `status: processing` ile `201` döner; extract + chunk + embedding `BackgroundTasks` içinde çalışır.
2. **Paralel embedding** — Chunk’lar batch’lere bölünür; birden fazla Gemini embedding isteği eşzamanlı gider.
3. **İstemci polling** — Chat yalnızca `status == ready` iken mümkündür; Flutter `GET /sessions/{id}` ile ilerlemeyi izler.

```python
# bookapp-api/app/main.py
app.include_router(semantic_router)
app.include_router(sessions_router)
```

### İlgili dosyalar

```
bookapp-api/
├── app/
│   ├── api/routers/sessions.py           # HTTP + BackgroundTasks
│   ├── domain/
│   │   ├── document_chat_service.py     # create_pending + process_session + RAG
│   │   ├── document_chunker.py
│   │   └── document_extractors/
│   │       ├── pdf_extractor.py
│   │       └── epub_extractor.py
│   ├── data/
│   │   ├── datasources/gemini.py        # paralel batch embed + on_progress
│   │   └── session_store/               # InMemorySessionStore (+ Redis opsiyonel)
│   ├── core/config.py                   # DOCUMENT_EMBEDDING_* ayarları
│   └── models/
│       ├── schemas.py
│       └── document_session.py          # status, chunks_embedded, chunks_total
├── docs/DOCUMENT_CHAT_INTEGRATION.md
└── scripts/smoke_document_chat.py
```

### Ortam değişkenleri (sunucu)

```env
# Zorunlu
GOOGLE_API_KEY=...              # Gemini embedding + chat

# İstemci auth (production)
API_KEY=...                     # Flutter → Bearer token

# Opsiyonel
SESSION_STORE_BACKEND=memory    # production çok instance → redis
REDIS_URL=redis://...
SESSION_IDLE_TTL_MINUTES=45
SESSION_MAX_TTL_MINUTES=120
DOCUMENT_MAX_FILE_SIZE_MB=20
DOCUMENT_MAX_QUESTIONS_PER_SESSION=10
DOCUMENT_EMBEDDING_CONCURRENCY=15
DOCUMENT_EMBEDDING_BATCH_SIZE=50
# ... diğer DOCUMENT_* limitleri (config.py)
```

### Limitler (varsayılan — `app/core/config.py`)

| Ayar | Varsayılan | Açıklama |
|------|------------|----------|
| `document_max_file_size_mb` | 20 | Multipart üst sınırı |
| `document_max_pages` | 500 | PDF sayfa limiti |
| `document_max_chapters` | 1000 | EPUB bölüm limiti |
| `document_max_words` | 1_500_000 | Toplam kelime |
| `document_max_chars` | 7_500_000 | Ham metin karakter |
| `document_max_chunks` | 1500 | Embedding + bellek tavanı |
| `document_chunk_size` | 1000 | Karakter |
| `document_chunk_overlap` | 200 | Karakter |
| `document_embedding_batch_size` | 50 | Paralel embedding batch boyutu |
| `document_embedding_concurrency` | 15 | Eşzamanlı embedding worker sayısı |
| `document_max_questions_per_session` | 10 | Oturum başına soru |
| `document_max_question_length` | 500 | Tek soru |
| `document_retrieval_top_k` | 5 | RAG chunk sayısı |
| `session_idle_ttl_minutes` | 45 | Son erişimden sonra silinme |
| `session_max_ttl_minutes` | 120 | Mutlak üst sınır |
| `document_max_concurrent_sessions` | 25 | Sunucu kapasitesi |
| `document_max_sessions_per_ip_hour` | 10 | IP rate limit |

Limit aşımında tipik HTTP kodları: `413` (dosya boyutu), `415` (format), `422` (içerik limiti / failed session), `409` (henüz processing), `429` (soru veya IP limiti).

---

## Oturum yaşam döngüsü (arka plan işleme)

```
Client                         FastAPI                         Background worker
  │                               │                                    │
  │── POST /sessions (file) ─────►│ validate + create_pending          │
  │                               │ status=processing                  │
  │◄── 201 { sessionId,           │── BackgroundTasks.add_task ───────►│
  │       status: processing } ───│                                    │
  │                               │                                    │ extract
  │── GET /sessions/{id} ────────►│                                    │ chunk
  │◄── status=processing,         │◄── chunksEmbedded güncelle ────────│ parallel embed
  │    chunksEmbedded/Total ──────│                                    │
  │         … poll …              │                                    │
  │── GET /sessions/{id} ────────►│                                    │
  │◄── status=ready, pageCount… ──│◄── status=ready ───────────────────│
  │                               │                                    │
  │── POST /sessions/{id}/chat ──►│ RAG + Gemini                       │
  │◄── answer + sources ──────────│                                    │
```

### Oturum durumları (`status`)

| `status` | Anlamı | Chat |
|----------|--------|------|
| `processing` | Extract / chunk / embedding devam ediyor | **409 Conflict** |
| `ready` | Embedding tamam; RAG kullanılabilir | **200** |
| `failed` | İşleme hata verdi (`errorMessage` dolu) | **422** |

### Sunucu tarafı adımlar

1. `create_pending_session` — boş oturum (`status=processing`, `chunkCount=0`) store’a yazılır.
2. `BackgroundTasks` → `process_session(session_id, data, format)`:
   - PDF/EPUB extract
   - Chunk split → `chunksTotal` set edilir
   - `embed_documents(..., on_progress=...)` → her batch bitince `chunksEmbedded` güncellenir
   - Başarı: `status=ready`, `chunks` dolu
   - Hata: `status=failed`, `errorMessage` set, `chunks` temizlenir

### Paralel embedding

`app/data/datasources/gemini.py` → `embed_with_retry`:

- Metinler `document_embedding_batch_size` (50) boyutunda batch’lere bölünür.
- En fazla `document_embedding_concurrency` (15) worker `ThreadPoolExecutor` ile eşzamanlı `embed_documents` çağırır.
- Her batch kendi retry mantığına sahiptir (429 / transient 502–504).
- Günlük kota tükenirse `DailyQuotaExhaustedError` → oturum `failed`.

Bu sayede büyük kitaplarda embedding süresi seri işleme göre belirgin kısalır; istemci yine de polling ile beklemelidir.

---

## HTTP API sözleşmesi

Tüm endpoint'ler `Authorization: Bearer <SEMANTIC_API_KEY>` ile korunur (`API_KEY` boşsa dev modda açık).

Prefix: `/api/v1`

### `POST /api/v1/sessions` — Oturum oluştur (dosya yükle)

**Content-Type:** `multipart/form-data`

| Alan | Tip | Zorunlu |
|------|-----|---------|
| `file` | binary | Evet |

**Davranış:** Dosya belleğe alınır, format/boyut doğrulanır, pending oturum oluşturulur, embedding **arka planda** başlar. Yanıt **hemen** döner — extract/embed bitmesini beklemez.

**Başarı (201) — tipik ilk yanıt:**

```json
{
  "sessionId": "550e8400-e29b-41d4-a716-446655440000",
  "format": "pdf",
  "filename": "kitap.pdf",
  "expiresAt": "2026-07-09T18:30:00Z",
  "status": "processing",
  "pageCount": null,
  "chapterCount": null,
  "wordCount": 0,
  "chunkCount": 0,
  "truncated": false,
  "limits": {
    "maxQuestionsRemaining": 10
  }
}
```

> **Not:** `pageCount` / `wordCount` / `chunkCount` ilk yanıtta genelde boş/0’dır; metadata `GET /sessions/{id}` ile `ready` (veya işleme ilerledikçe) dolar.

**Upload timeout:** Multipart gönderimi için `sendTimeout` / `receiveTimeout` ~**60 sn** yeterlidir (yanıt hızlı). Uzun bekleyen iş polling’dedir; eski “upload 120 sn bekle” modeli **geçersizdir**.

### `GET /api/v1/sessions/{sessionId}` — Oturum durumu (polling)

**Processing sırasında:**

```json
{
  "sessionId": "...",
  "format": "pdf",
  "expiresAt": "...",
  "chunkCount": 0,
  "questionCount": 0,
  "questionsRemaining": 10,
  "status": "processing",
  "errorMessage": null,
  "chunksEmbedded": 150,
  "chunksTotal": 420,
  "pageCount": 120,
  "chapterCount": null,
  "wordCount": 95000,
  "truncated": false
}
```

**Ready:**

```json
{
  "sessionId": "...",
  "format": "epub",
  "expiresAt": "...",
  "chunkCount": 87,
  "questionCount": 0,
  "questionsRemaining": 10,
  "status": "ready",
  "errorMessage": null,
  "chunksEmbedded": 87,
  "chunksTotal": 87,
  "pageCount": null,
  "chapterCount": 12,
  "wordCount": 42000,
  "truncated": false
}
```

**Failed:**

```json
{
  "sessionId": "...",
  "status": "failed",
  "errorMessage": "Could not extract text from document",
  "chunksEmbedded": 0,
  "chunksTotal": 0,
  "...": "..."
}
```

Chat mesajları **dönülmez** — geçmiş yalnızca istemci tarafında tutulur.

**Önerilen poll aralığı:** 1–2 sn (`Timer.periodic` veya `Stream.periodic`). `status != processing` olunca dur. Üst süre limiti (ör. 5–10 dk) sonrası kullanıcıya timeout mesajı.

Progress UI: `chunksTotal > 0` ise `chunksEmbedded / chunksTotal`; aksi halde belirsiz spinner (“Metin çıkarılıyor…”).

### `POST /api/v1/sessions/{sessionId}/chat` — Soru sor

**Önkoşul:** `status == ready`. Aksi halde chat denemeyin; önce poll edin.

**Content-Type:** `application/json`

```json
{
  "question": "Ana karakterin motivasyonu nedir?"
}
```

**Başarı (200):**

```json
{
  "answer": "...",
  "sources": [
    {
      "chunkIndex": 12,
      "excerpt": "İlk iki cümlelik kısa alıntı...",
      "metadata": { "page": 45, "format": "pdf" }
    }
  ],
  "sessionExpiresAt": "2026-07-09T18:35:00Z",
  "questionsRemaining": 9
}
```

EPUB kaynak metadata örneği: `{"chapter_index": 3, "chapter_title": "...", "format": "epub"}`.

### `DELETE /api/v1/sessions/{sessionId}` — Oturumu sonlandır

**204** — oturum ve tüm ephemeral veri silinir. Processing sırasında da silinebilir; arka plan görevi oturumu bulamazsa sessizce çıkar.

### Hata kodları özeti

| HTTP | `detail` örneği | Flutter aksiyonu |
|------|-----------------|------------------|
| 400 | `No file provided` | Dosya seçimini tekrarla |
| 401 | `Invalid or missing API key` | Env / deploy kontrolü |
| 404 | `Session not found or expired` | "Oturum süresi doldu" + yeniden yükle |
| 409 | `Session is still processing; poll GET /sessions/{id}…` | Poll’a devam; chat input disable |
| 413 | `File exceeds 20 MB limit` | Limit mesajı göster |
| 415 | `Unsupported format; use PDF or EPUB` | Format uyarısı |
| 422 | İçerik limiti / extract hatası / `status=failed` mesajı | Hata göster; yeniden yükle |
| 429 | `Question limit reached` / `Too many sessions from IP` | Limit / bekle mesajı |
| 503 | Embedding yapılandırılmamış / session capacity | Genel servis hatası |

---

## Flutter entegrasyonu

### Mevcut altyapı (yeniden kullanılacak)

| Bileşen | Konum | Kullanım |
|---------|-------|----------|
| API base URL | `lib/core/env.dart` → `Env.semanticApiBaseUrl` | Aynı FastAPI host |
| API key | `Env.semanticApiKey` | Bearer header |
| Config flag | `Env.hasSemanticApiConfig` | Feature gate (aynı flag yeterli) |
| Dio pattern | `SemanticApiDataSource` | Header, logging, hata yapısı |
| Clean architecture | `semantic_discovery/` | Klasör ve provider yapısı |
| Hata UI | `AsyncErrorView`, `AppLoadingIndicator` | Tutarlı UX |

`env.example.json`:

```json
{
  "SEMANTIC_API_BASE_URL": "http://192.168.1.175:8000",
  "SEMANTIC_API_KEY": "your-semantic-api-key"
}
```

Yeni env anahtarı **gerekmez**.

### Yeni bağımlılık

```yaml
# pubspec.yaml
dependencies:
  file_picker: ^8.0.0   # PDF/EPUB seçimi (sürüm pub.dev ile doğrulanmalı)
```

`image_picker` yalnızca galeri için; belge seçimi için `file_picker` şarttır.

### Önerilen feature yapısı

```
lib/features/document_chat/
├── presentation/
│   ├── pages/
│   │   └── document_chat_page.dart
│   ├── widgets/
│   │   ├── document_upload_card.dart
│   │   ├── document_processing_progress.dart  # chunksEmbedded/Total
│   │   ├── document_chat_message_list.dart
│   │   ├── document_chat_input_bar.dart
│   │   └── document_source_chip.dart
│   └── providers/
│       └── document_chat_providers.dart
│
├── domain/
│   ├── entities/
│   │   ├── document_session.dart
│   │   ├── document_chat_message.dart
│   │   └── document_chat_source.dart
│   ├── repositories/
│   │   └── document_chat_repository.dart
│   └── usecases/
│       ├── create_document_session_usecase.dart
│       ├── poll_document_session_usecase.dart   # veya repository içinde
│       ├── ask_document_question_usecase.dart
│       └── delete_document_session_usecase.dart
│
└── data/
     ├── models/
     │   ├── create_session_response_model.dart
     │   ├── session_status_response_model.dart
     │   └── chat_response_model.dart
     ├── datasources/
     │   └── document_chat_api_datasource.dart
     └── repositories/
          └── document_chat_repository_impl.dart
```

### Domain entity'leri (öneri)

```dart
enum DocumentSessionStatus { processing, ready, failed }

class DocumentSession {
  const DocumentSession({
    required this.sessionId,
    required this.format,       // 'pdf' | 'epub'
    required this.filename,
    required this.expiresAt,
    required this.status,
    required this.chunkCount,
    required this.questionsRemaining,
    this.pageCount,
    this.chapterCount,
    this.wordCount = 0,
    this.truncated = false,
    this.errorMessage,
    this.chunksEmbedded = 0,
    this.chunksTotal = 0,
  });

  final String sessionId;
  final String format;
  final String filename;
  final DateTime expiresAt;
  final DocumentSessionStatus status;
  final int chunkCount;
  final int questionsRemaining;
  final int? pageCount;
  final int? chapterCount;
  final int wordCount;
  final bool truncated;
  final String? errorMessage;
  final int chunksEmbedded;
  final int chunksTotal;

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);
  bool get isReady => status == DocumentSessionStatus.ready;
  bool get isProcessing => status == DocumentSessionStatus.processing;
  bool get isFailed => status == DocumentSessionStatus.failed;

  double? get embedProgress {
    if (chunksTotal <= 0) return null;
    return (chunksEmbedded / chunksTotal).clamp(0.0, 1.0);
  }
}

class DocumentChatMessage {
  const DocumentChatMessage({
    required this.id,
    required this.role,         // 'user' | 'assistant'
    required this.content,
    this.sources = const [],
    required this.createdAt,
  });

  final String id;
  final String role;
  final String content;
  final List<DocumentChatSource> sources;
  final DateTime createdAt;
}

class DocumentChatSource {
  const DocumentChatSource({
    required this.chunkIndex,
    required this.excerpt,
    required this.metadata,
  });

  final int chunkIndex;
  final String excerpt;
  final Map<String, dynamic> metadata;

  String? get pageLabel =>
      metadata['page'] != null ? 'p. ${metadata['page']}' : null;

  String? get chapterLabel => metadata['chapter_title'] as String?;
}
```

### Dio datasource (taslak)

Upload yanıtı hızlı olduğu için timeout’lar ılımlı tutulabilir; chat için 60–90 sn yeterli.

```dart
class DocumentChatApiDataSource {
  DocumentChatApiDataSource({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: Env.semanticApiBaseUrl,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 90),
                sendTimeout: const Duration(seconds: 60),
                headers: _defaultHeaders(),
                validateStatus: (code) => code != null && code < 500,
              ),
            );

  final Dio _dio;

  static Map<String, String> _defaultHeaders() {
    final headers = <String, String>{};
    final apiKey = Env.semanticApiKey.trim();
    if (apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer $apiKey';
    }
    return headers;
  }

  Future<CreateSessionResponseModel> createSession({
    required String filePath,
    required String filename,
  }) async {
    if (!Env.hasSemanticApiConfig) {
      throw StateError('Semantic API is not configured.');
    }

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: filename),
    });

    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/sessions',
      data: formData,
    );

    if (response.statusCode != 201) {
      throw DocumentChatException.fromResponse(response);
    }
    return CreateSessionResponseModel.fromJson(response.data!);
  }

  Future<SessionStatusResponseModel> getSessionStatus(String sessionId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/v1/sessions/$sessionId',
    );
    if (response.statusCode != 200) {
      throw DocumentChatException.fromResponse(response);
    }
    return SessionStatusResponseModel.fromJson(response.data!);
  }

  Future<ChatResponseModel> askQuestion({
    required String sessionId,
    required String question,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/v1/sessions/$sessionId/chat',
      data: {'question': question},
    );

    if (response.statusCode != 200) {
      throw DocumentChatException.fromResponse(response);
    }
    return ChatResponseModel.fromJson(response.data!);
  }

  Future<void> deleteSession(String sessionId) async {
    await _dio.delete('/api/v1/sessions/$sessionId');
  }
}
```

`DocumentChatException` sınıfı HTTP koduna göre kullanıcıya anlamlı mesaj üretmeli (`detail` parse); özellikle **409** → “Hâlâ işleniyor”, **422** failed → `errorMessage`.

### Provider state (öneri)

```dart
class DocumentChatState {
  const DocumentChatState({
    this.session,
    this.messages = const [],
    this.isUploading = false,
    this.isPolling = false,
    this.isSending = false,
    this.error,
  });

  final DocumentSession? session;
  final List<DocumentChatMessage> messages;
  final bool isUploading;
  final bool isPolling;
  final bool isSending;
  final Object? error;

  bool get hasActiveSession =>
      session != null && !session!.isExpired && session!.isReady;
}
```

Akış:

1. `pickAndUpload()` → `file_picker` → `createSession` → `session` (`processing`)
2. `_startPolling(sessionId)` → her 1–2 sn `getSessionStatus`
   - `processing` → progress güncelle (`chunksEmbedded` / `chunksTotal`)
   - `ready` → poll dur; chat input aç
   - `failed` → poll dur; `errorMessage` göster
3. `sendQuestion(text)` → yalnızca `isReady` iken; 409 gelirse poll’a geri dön
4. `disposeSession()` → poll iptal + `DELETE` + state sıfırla

### UI akışı

```
┌─────────────────────────────────────────────────────────────┐
│  1. Boş durum                                                │
│     [ PDF veya EPUB seç ]                                    │
│     Desteklenen: .pdf, .epub (max 20 MB)                     │
│     Oturum geçicidir; uygulama kapanınca sohbet silinir.     │
└─────────────────────────────────────────────────────────────┘
                          │ dosya seçildi
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  2a. Upload                                                  │
│     Multipart gönderiliyor… (kısa)                           │
└─────────────────────────────────────────────────────────────┘
                          │ 201 status=processing
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  2b. Arka plan işleme (poll)                                 │
│     Progress: 150 / 420 chunk                                │
│     veya "Metin çıkarılıyor…" (chunksTotal == 0)             │
│     Chat input: disabled                                     │
└─────────────────────────────────────────────────────────────┘
                          │ status=ready
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  3. Sohbet                                                   │
│     Üst: kitap.pdf · 32 sayfa · 9 soru kaldı · süre: 44 dk  │
│     Mesaj listesi (user / assistant)                         │
│     Kaynak chip: "p. 45" veya bölüm adı                      │
│     Alt: metin girişi + gönder                               │
└─────────────────────────────────────────────────────────────┘
                          │ failed / TTL / 404
                          ▼
┌─────────────────────────────────────────────────────────────┐
│  4. Hata veya oturum doldu                                   │
│     errorMessage veya "Oturumunuz sona erdi."                │
│     [ Yeni dosya yükle ]                                     │
└─────────────────────────────────────────────────────────────┘
```

### UX kuralları

| Konu | Kural |
|------|-------|
| Upload vs işleme | Upload bitince sohbet **açılmaz**; `ready` olana kadar progress göster |
| Progress | `chunksTotal > 0` → determinate bar; değilse indeterminate |
| Chat erken | Input disable; yanlışlıkla 409 alınırsa sessizce yok say / poll devam |
| Kalıcılık | Sunucu chat log tutmaz; istemci `messages` listesini kendi state'inde tutar |
| Uygulama yeniden başlatma | `sessionId` kaybolursa sohbet devam edemez — ürün metninde belirt |
| `truncated: true` | "Kitabın tamamı işlenemedi; yanıtlar kısmi olabilir" banner (`ready` sonrası) |
| Kaynaklar | `sources` chip; telif için kısa excerpt |
| Soru limiti | `questionsRemaining` üst barda; 0'da input disable |
| Çıkış | Poll timer iptal + isteğe bağlı `DELETE` |
| Offline | `Env.hasSemanticApiConfig` false → feature gizle |

---

## i18n anahtarları (öneri)

`app_en.arb` / `app_tr.arb` için eklenecek örnek anahtarlar:

| Anahtar | EN | TR |
|---------|----|----|
| `searchTabDocumentChat` | Ask my book | Kitabımla sor |
| `documentChatPickFile` | Choose PDF or EPUB | PDF veya EPUB seç |
| `documentChatUploading` | Uploading… | Yükleniyor… |
| `documentChatProcessing` | Processing your book… | Kitabınız işleniyor… |
| `documentChatEmbedProgress` | Embedding {done} of {total} | {done} / {total} gömülüyor |
| `documentChatExtracting` | Extracting text… | Metin çıkarılıyor… |
| `documentChatEmptyHint` | Upload a book to ask questions about its content. | İçerik hakkında soru sormak için kitap yükleyin. |
| `documentChatSessionExpired` | Your session has expired. Upload the book again. | Oturumunuz sona erdi. Kitabı yeniden yükleyin. |
| `documentChatProcessingFailed` | Could not process this book. | Bu kitap işlenemedi. |
| `documentChatStillProcessing` | Still processing — please wait. | Hâlâ işleniyor — lütfen bekleyin. |
| `documentChatQuestionsRemaining` | {count} questions left | {count} soru kaldı |
| `documentChatTruncatedWarning` | Only part of the book was processed. Answers may be incomplete. | Kitabın yalnızca bir bölümü işlendi. Yanıtlar eksik olabilir. |
| `documentChatUnsupportedFormat` | Only PDF and EPUB files are supported. | Yalnızca PDF ve EPUB desteklenir. |
| `documentChatFileTooLarge` | File exceeds the {mb} MB limit. | Dosya {mb} MB sınırını aşıyor. |
| `documentChatAskPlaceholder` | Ask about this book… | Bu kitap hakkında sorun… |
| `documentChatSourcePage` | Page {page} | Sayfa {page} |
| `documentChatEphemeralNotice` | Chats are temporary and not saved to your account. | Sohbetler geçicidir; hesabınıza kaydedilmez. |

---

## Güvenlik ve uyumluluk

| Konu | Uygulama |
|------|----------|
| API key | `SEMANTIC_API_KEY` compile-time define; repo'ya commit edilmez |
| Dosya doğrulama | Sunucu MIME + magic bytes (`%PDF`, ZIP/EPUB) kontrol eder |
| Gizlilik | Soru/cevap sunucu loglarına yazılmaz |
| Telif | Kullanım şartlarında yalnızca hukuken kullanılabilen dosyalar; sunucu kalıcı kopya tutmaz |
| DRM | DRM'li EPUB desteklenmez |
| Abuse | IP başına saatlik oturum limiti, eşzamanlı oturum tavanı |

---

## RAG davranışı (istemci beklentisi)

Sunucu tarafı (`DocumentChatService`):

1. Chat öncesi `status` kontrolü (`processing` → 409, `failed` → 422)
2. Takip soruları için son N tur condense edilir (`document_max_chat_turns_memory = 4`)
3. Standalone soru embed edilir → cosine similarity ile top-k chunk
4. Gemini yalnızca bağlamdaki excerpt'lere dayanarak cevap verir
5. Bağlamda yoksa "bilmiyorum" tarzı cevap beklenir

İstemci uzun alıntı beklemez; cevaplar özet/parafraz ağırlıklıdır.

---

## Test planı

### API smoke test

```bash
cd bookapp-api
# API çalışırken:
python scripts/smoke_document_chat.py
```

Smoke script’in **poll** etmesi gerekir: `CREATE 201` (`status=processing`) → `GET` ile `ready` bekle → `CHAT 200` → `DELETE 204`.

### Flutter manuel test

| Senaryo | Beklenen |
|---------|----------|
| Küçük PDF yükle | 201 `processing` → poll → `ready` → chat açılır |
| Progress | `chunksEmbedded` artar; bar güncellenir |
| Erken chat | Input kapalı; API’ye 409 |
| Geçerli soru | 200, anlamlı cevap + sources |
| Takip sorusu ("peki ya o?") | Condense ile anlamlı cevap |
| 11. soru | 429, input disable |
| Extract edilemeyen PDF | `status=failed` + `errorMessage` |
| `.docx` seçimi | 415 veya picker filtresi |
| Poll sırasında DELETE | 204; sonraki GET 404 |
| 45+ dk idle | 404, yeniden yükle mesajı |
| `SEMANTIC_API_BASE_URL` boş | Feature gizli veya yapılandırma uyarısı |

### Birim test (öneri)

- `CreateSessionResponseModel` / `SessionStatusResponseModel` / `ChatResponseModel` fromJson
- `DocumentSession.embedProgress` (0 total → null)
- `DocumentChatException` 409 / 422 eşlemesi
- `DocumentSession.isExpired` hesabı

---

## Uygulama fazları

### Faz 1 — MVP (Flutter)

- [ ] `file_picker` bağımlılığı
- [ ] `document_chat` data + domain katmanı
- [ ] Upload + **status polling** + chat tek ekran
- [ ] Progress (`chunksEmbedded` / `chunksTotal`)
- [ ] Hata mesajları (409, 413, 415, 422, 404, 429)
- [ ] i18n anahtarları (EN + TR)
- [ ] SearchPage üçüncü sekme veya geçici giriş noktası

### Faz 2 — UX sağlamlaştırma

- [ ] `truncated` banner
- [ ] `questionsRemaining` + `expiresAt` göstergesi
- [ ] Kaynak chip'leri (sayfa / bölüm)
- [ ] Poll timer dispose + sayfa çıkışında `DELETE`
- [ ] `AsyncErrorView` ile tutarlı hata UI

### Faz 3 — Opsiyonel

- [ ] Oturum `sessionId` SharedPreferences (kısa süreli geri yükleme + poll resume)
- [ ] Analytics event (yalnızca `session_created`, `question_asked` — metin yok)
- [ ] Production Redis store notları (çok instance deploy)

---

## Deploy notları

| Konu | Not |
|------|-----|
| Bellek | ~1500 chunk × (metin + 768 float) ≈ birkaç MB/oturum |
| Upload timeout | Proxy body size ≥ 20 MB; upload yanıtı hızlı — uzun proxy timeout embedding için şart değil |
| Paralel embed | `DOCUMENT_EMBEDDING_CONCURRENCY` yüksekse Gemini rate limit artabilir; 429 retry mevcut |
| Ölçek | Horizontal scale → `SESSION_STORE_BACKEND=redis` zorunlu (BackgroundTasks instance-local) |
| Gemini kota | Semantic search ile aynı `GOOGLE_API_KEY`; kota paylaşılır |
| Android cleartext | Yerel dev (`http://192.168.x.x`) için `networkSecurityConfig` (mevcut semantic ile aynı) |

> **Önemli:** FastAPI `BackgroundTasks` isteği alan process içinde çalışır. Birden fazla worker/instance varsa oturum store’u **Redis** olmadan poll başka instance’a düşebilir ve 404 alınır.

---

## Referanslar

| Kaynak | Konum |
|--------|-------|
| API router | `bookapp-api/app/api/routers/sessions.py` |
| RAG + background process | `bookapp-api/app/domain/document_chat_service.py` |
| Paralel embedding | `bookapp-api/app/data/datasources/gemini.py` |
| Config (concurrency/batch) | `bookapp-api/app/core/config.py` |
| API entegrasyon spesifikasyonu | `bookapp-api/docs/DOCUMENT_CHAT_INTEGRATION.md` |
| Semantik keşif (paralel feature) | `xdocs/semantic_discovery.md` |
| Mevcut Dio örneği | `lib/features/semantic_discovery/data/datasources/semantic_api_datasource.dart` |
| Env | `lib/core/env.dart`, `env.example.json` |
| SearchPage | `lib/features/search/presentation/pages/search_page.dart` |

---

*Son güncelleme: API’de arka plan işleme (`BackgroundTasks`) ve paralel embedding (`document_embedding_concurrency` / `batch_size`) eklendi. Flutter document_chat feature henüz implemente edilmedi; istemci `POST` sonrası `GET` ile poll etmelidir.*
