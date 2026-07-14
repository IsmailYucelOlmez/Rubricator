# Semantik Kitap Öneri Sistemi – Entegrasyon Dökümanı

> **Kapsam:** `llm-semantic-book-recommender` projesinin BookApp (Flutter) + Supabase (pgvector) + FastAPI mimarisine entegrasyonu.
> **Kaynak proje:** `llm-semantic-book-recommender-main/modules/`
> **Hedef:** Kullanıcının doğal dilde (TR/EN) yazdığı sorguya göre semantik kitap keşfi.

---

## Amaç

Kullanıcıların *"yalnızlık ve içsel yolculuk temalı kısa roman"* gibi serbest metin sorgularıyla kitap keşfetmesini sağlamak.

Bu sistem:

- Mevcut **liste öneri sistemi** (`For You` sekmesi) ile **çakışmaz** — o SQL tabanlı liste önerisidir; bu **kitap keşfi**dir.
- Mevcut **Google Books arama** (`SearchPage`) ile **tamamlar** — keyword arama yerine anlamsal (semantic) arama sunar.
- **Kitap kimliği çözümlemesi öneri sayfasında yapılmaz** — kullanıcı karta tıklayınca `BookDetailPage` açılır; Google Books volume ID orada çözülür.

---

## Mimari Özet

```
┌─────────────────────────────────────────────────────────────┐
│  Flutter (BookApp)                                          │
│  features/semantic_discovery/                               │
│    UI → Provider → UseCase → Repository → Dio (FastAPI)     │
│    Kitap detay → mevcut BookDetailPage + resolve katmanı    │
└──────────────┬──────────────────────────────┬───────────────┘
               │                              │
               ▼                              ▼
┌──────────────────────────┐    ┌────────────────────────────┐
│  FastAPI                  │    │  Supabase                   │
│  - query rewrite (Gemini) │    │  - pgvector (book_catalog)  │
│  - embedding (Gemini)     │◄──►│  - identity cache           │
│  - hybrid search          │    │  - search logs (opsiyonel)  │
│  - Google Books ingest    │    │  - auth, user_books, RLS    │
└──────────────────────────┘    └────────────────────────────┘
               │
               ▼
        Google Books API
        (mevcut Edge Function proxy)
```

### Sorumluluk ayrımı

| Katman | Sorumluluk |
|--------|------------|
| **Supabase** | Vektör kataloğu, kimlik önbelleği, kullanıcı verisi, RLS, opsiyonel arama logları |
| **FastAPI** | Embedding üretimi, semantik arama, LLM sorgu rewrite, Advanced modda Google Books ingest |
| **Flutter** | UI, FastAPI çağrısı, kitap detayına yönlendirme, volume ID çözümleme (detay sayfasında) |

### Zorunlu mimari kural (mevcut projeyle uyumlu)

```
UI → Provider → UseCase → Repository → (FastAPI | Supabase)
```

- Supabase ve FastAPI çağrıları **UI içinde yapılmamalı**.
- `book_detail_page.dart` içine semantik arama mantığı **eklenmez** — yalnızca `resolveBookProvider` gibi ayrı bir provider embed edilir.

---

## Mevcut sistemlerle ilişki

| Özellik | Mevcut | Semantik öneri |
|---------|--------|----------------|
| Liste önerisi | `list_recommendations` + nightly batch | Ayrı feature |
| Kitap arama | Google Books keyword (`SearchPage`) | Doğal dil / anlamsal |
| Benzer kitaplar | Subject/author (`relatedBooksProvider`) | Sorgu tabanlı keşif |
| Kitap `book_id` | Google Books volume ID (`text`) | Öneride yok; detayda çözülür |
| Google Books proxy | Edge Function `google-books` | FastAPI sunucu tarafı + Flutter detay çözümlemesi |

---

## Veri modeli (Supabase)

### 1. `book_catalog` — vektör kataloğu

Kaynak: `books_with_emotions.csv` (~5200 kitap). Birincil anahtar **ISBN-13**.

```sql
-- Migration: 20260701000000_semantic_book_catalog.sql

create extension if not exists vector;

create table if not exists public.book_catalog (
  isbn13            text primary key,
  isbn10            text,
  title             text not null,
  authors           text not null,
  description       text not null default '',
  thumbnail_url     text,
  google_volume_id  text,              -- thumbnail URL'den parse; opsiyonel hızlandırma
  simple_category   text,                -- Fiction | Nonfiction
  published_year    integer,
  emotion_scores    jsonb not null default '{}'::jsonb,
  -- joy, surprise, anger, fear, sadness vb.
  embedding         vector(768) not null, -- Gemini embedding-001 boyutu; deploy öncesi doğrula
  source            text not null default 'local',  -- local | google_books
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create index if not exists book_catalog_embedding_idx
  on public.book_catalog
  using ivfflat (embedding vector_cosine_ops)
  with (lists = 100);

create index if not exists book_catalog_category_idx
  on public.book_catalog (simple_category);

create index if not exists book_catalog_title_trgm_idx
  on public.book_catalog using gin (title gin_trgm_ops);  -- opsiyonel; pg_trgm extension gerekir
```

**RLS:** Katalog herkese okunabilir; yazma yalnızca `service_role`.

```sql
alter table public.book_catalog enable row level security;

create policy "book_catalog_select_all"
  on public.book_catalog for select
  to anon, authenticated
  using (true);

-- INSERT/UPDATE/DELETE: service_role only (policy yok = deny for authenticated)
```

> **Not:** Embedding boyutu (`768`) Gemini `models/gemini-embedding-001` ile uyumludur. İlk batch import öncesi bir test embedding ile doğrulanmalıdır.

---

### 2. `book_identity_cache` — ISBN → Google volume ID önbelleği

Kitap detay sayfasında tekrarlayan Google Books çağrılarını azaltır.

```sql
create table if not exists public.book_identity_cache (
  isbn13            text primary key,
  google_volume_id  text not null,
  resolved_title    text,
  resolved_at       timestamptz not null default now(),
  resolve_method    text not null default 'isbn'  -- isbn | thumbnail | title_author
);

alter table public.book_identity_cache enable row level security;

create policy "book_identity_cache_select_all"
  on public.book_identity_cache for select
  to anon, authenticated
  using (true);

-- Yazma: service_role veya SECURITY DEFINER RPC
```

---

### 3. `semantic_search_logs` — analitik (opsiyonel, Faz 2)

Mevcut `search_logs` tablosundan ayrı tutulur; semantik sorgular farklı yapıdadır.

```sql
create table if not exists public.semantic_search_logs (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid references auth.users (id) on delete set null,
  query         text not null,
  mode          text not null check (mode in ('simple', 'advanced')),
  category      text,
  tone          text,
  result_count  integer not null default 0,
  created_at    timestamptz not null default now()
);

alter table public.semantic_search_logs enable row level security;

create policy "semantic_search_logs_insert_own"
  on public.semantic_search_logs for insert
  to authenticated
  with check (user_id = auth.uid() or user_id is null);

create policy "semantic_search_logs_select_own"
  on public.semantic_search_logs for select
  to authenticated
  using (user_id = auth.uid());
```

---

### 4. `semantic_query_cache` — sorgu sonuç önbelleği (opsiyonel)

FastAPI SQLite cache yerine Supabase'te tutulabilir (Faz 2).

```sql
create table if not exists public.semantic_query_cache (
  cache_key     text primary key,   -- hash(query + mode + category + tone)
  isbn13_list   text[] not null,
  rewrite_json  jsonb,
  expires_at    timestamptz not null,
  created_at    timestamptz not null default now()
);
```

Yazma: yalnızca `service_role` / FastAPI.

---

### 5. pgvector arama RPC

```sql
create or replace function public.semantic_search_books(
  p_query_embedding vector(768),
  p_category        text default null,
  p_limit           int  default 16,
  p_initial_k       int  default 50
)
returns table (
  isbn13          text,
  title           text,
  authors         text,
  description     text,
  thumbnail_url   text,
  simple_category text,
  emotion_scores  jsonb,
  similarity      float
)
language sql
stable
security definer
set search_path = public
as $$
  select
    bc.isbn13,
    bc.title,
    bc.authors,
    bc.description,
    bc.thumbnail_url,
    bc.simple_category,
    bc.emotion_scores,
    1 - (bc.embedding <=> p_query_embedding) as similarity
  from public.book_catalog bc
  where (p_category is null or p_category = 'All' or bc.simple_category = p_category)
  order by bc.embedding <=> p_query_embedding
  limit least(greatest(p_limit, 1), p_initial_k);
$$;

grant execute on function public.semantic_search_books(vector, text, int, int)
  to service_role;
-- Flutter doğrudan çağırmaz; FastAPI service_role ile çağırır
```

---

## FastAPI servisi

### Proje yapısı

```
bookapp-api/
├── app/
│   ├── main.py
│   ├── config.py
│   ├── routers/
│   │   └── semantic.py
│   ├── services/
│   │   ├── hybrid_recommender.py    # llm-semantic-book-recommender'dan uyarlanmış
│   │   ├── query_rewriter.py
│   │   ├── embeddings.py
│   │   ├── google_books_client.py
│   │   └── supabase_client.py
│   └── models/
│       └── schemas.py
├── scripts/
│   ├── build_embeddings.py          # CSV → Supabase pgvector import
│   └── parse_thumbnail_ids.py
├── requirements.txt
└── Dockerfile
```

Kaynak projeden **taşınacaklar:** `modules/hybrid_recommender.py`, `query_rewriter.py`, `google_books_client.py`, `book_normalizer.py`, `category_mapping.py`, `types.py`, `config.py` (Chroma referansları kaldırılır, Supabase RPC eklenir).

**Taşınmayacaklar:** `gradio-dashboard.py`, notebook'lar, Chroma persist dizini.

---

### Ortam değişkenleri

```env
# FastAPI
GOOGLE_API_KEY=...                    # Gemini embedding + rewrite (zorunlu)
GOOGLE_BOOKS_API_KEY=...              # Advanced mod (önerilir)
SUPABASE_URL=...
SUPABASE_SERVICE_ROLE_KEY=...         # pgvector RPC + catalog yazma
SEMANTIC_QUERY_CACHE_TTL_SECONDS=3600
MAX_NEW_BOOKS=5
CORS_ORIGINS=https://...
API_KEY=...                           # Flutter → FastAPI auth (Bearer)
```

Flutter `.env`:

```env
SEMANTIC_API_BASE_URL=https://api.bookapp.example.com
SEMANTIC_API_KEY=...                  # veya Supabase JWT doğrulaması
```

> **Güvenlik:** `GOOGLE_API_KEY` ve `SUPABASE_SERVICE_ROLE_KEY` yalnızca FastAPI sunucusunda; Flutter bundle'a girmez. Mevcut Google Books proxy (`supabase/functions/google-books`) Flutter tarafında kalır.

---

### API sözleşmesi

#### `POST /api/v1/semantic/search`

**Request:**

```json
{
  "query": "yalnızlık ve içsel yolculuk temalı roman",
  "mode": "simple",
  "category": "Fiction",
  "tone": "Sad",
  "limit": 16
}
```

| Alan | Tip | Varsayılan | Açıklama |
|------|-----|------------|----------|
| `query` | string | — | Max 500 karakter |
| `mode` | `simple` \| `advanced` | `simple` | Advanced: LLM rewrite + Google Books ingest |
| `category` | string | `All` | `Fiction`, `Nonfiction`, `All` |
| `tone` | string | `All` | `Happy`, `Sad`, `Suspenseful`, `Angry`, `Surprising`, `All` |
| `limit` | int | 16 | Max 32 |

**Response:**

```json
{
  "results": [
    {
      "isbn13": "9780006280934",
      "title": "The Problem of Pain",
      "author": "Clive Staples Lewis",
      "description": "...",
      "coverImageUrl": "https://...",
      "category": "Nonfiction",
      "similarity": 0.87,
      "source": "local"
    }
  ],
  "meta": {
    "mode": "simple",
    "queryRewritten": null,
    "resultCount": 12
  }
}
```

**Önemli:** Yanıtta `googleVolumeId` **döndürülmez** (bilinçli tasarım). Öneri kartı yalnızca metadata gösterir.

#### `GET /api/v1/health`

Deploy ve monitoring için.

---

### FastAPI iş akışı (Simple mod)

```
1. query al
2. Gemini ile query embedding üret
3. Supabase RPC: semantic_search_books(embedding, category, limit)
4. tone != All ise emotion_scores ile sırala (hybrid_recommender._apply_tone_sort mantığı)
5. Sonuçları JSON döndür
6. (opsiyonel) semantic_search_logs insert
```

### FastAPI iş akışı (Advanced mod)

```
1. query rewrite (Gemini) → İngilizce Google Books sorguları
2. Paralel: Google Books fetch + local query embedding
3. Yeni kitapları normalize et → book_catalog'a upsert + embedding
4. semantic_search_books RPC
5. tone sort + limit
6. semantic_query_cache upsert
```

---

## Veri pipeline (ilk kurulum)

### Adım 1: CSV hazırlığı

Kaynak: `books_with_emotions.csv`

Gerekli kolonlar:

| Kolon | Kullanım |
|-------|----------|
| `isbn13` | PK |
| `title`, `authors`, `description` | Metadata + embedding metni |
| `thumbnail` | Kapak URL |
| `simple_categories` | Filtre |
| `joy`, `sadness`, … | Tone sıralama |
| `tagged_description` | Embedding kaynağı (`"<isbn13> <description>"`) |

### Adım 2: Thumbnail'den volume ID parse (opsiyonel)

```
http://books.google.com/books/content?id=Kk-uVe5QK-gC&...
                                      └─ google_volume_id
```

`book_catalog.google_volume_id` alanına yazılır; detay sayfası çözümlemesini hızlandırır.

### Adım 3: Embedding batch script

```bash
python scripts/build_embeddings.py \
  --csv books_with_emotions.csv \
  --batch-size 50 \
  --resume
```

- Gemini rate limit için batch + retry (kaynak projedeki `build_vector_db.py` mantığı)
- Her batch: embedding üret → Supabase `book_catalog` upsert
- `tagged_description` satırı embedding input'u olarak kullanılır (kaynak projeyle aynı)

### Adım 4: IVFFlat index rebuild

~5200 kayıt sonrası:

```sql
reindex index book_catalog_embedding_idx;
analyze book_catalog;
```

---

## Flutter entegrasyonu

### Feature yapısı

```
lib/features/semantic_discovery/
 ├── presentation/
 │    ├── pages/
 │    │    └── semantic_discovery_page.dart   # veya SearchPage'e sekme
 │    ├── widgets/
 │    │    ├── semantic_search_bar.dart
 │    │    ├── semantic_result_card.dart
 │    │    └── semantic_filters_sheet.dart    # category + tone
 │    └── providers/
 │         └── semantic_discovery_providers.dart
 │
 ├── domain/
 │    ├── entities/
 │    │    ├── semantic_search_request.dart
 │    │    └── semantic_book_result.dart
 │    ├── repositories/
 │    │    └── semantic_discovery_repository.dart
 │    └── usecases/
 │         └── search_semantic_books_usecase.dart
 │
 └── data/
      ├── models/
      │    └── semantic_book_result_model.dart
      ├── datasources/
      │    └── semantic_api_datasource.dart   # Dio → FastAPI
      └── repositories/
           └── semantic_discovery_repository_impl.dart
```

### Entity: `SemanticBookResult`

```dart
class SemanticBookResult {
  const SemanticBookResult({
    required this.isbn13,
    required this.title,
    required this.author,
    required this.description,
    this.coverImageUrl,
    this.category,
    this.similarity,
  });

  final String isbn13;
  final String title;
  final String author;
  final String description;
  final String? coverImageUrl;
  final String? category;
  final double? similarity;

  /// Öneri sayfasından detaya geçiş için — volume ID yok.
  Book toUnresolvedBook() => Book(
    id: '',  // veya 'pending:$isbn13'
    title: title,
    author: author,
    coverImageUrl: coverImageUrl,
    description: description,
  );
}
```

### Öneri sayfası davranışı

- Kart gösterir: kapak, başlık, yazar, kısa açıklama, similarity badge (opsiyonel)
- Tıklanınca:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => BookDetailPage(book: result.toUnresolvedBook()),
  ),
);
```

- **Bu sayfada:** favori ekleme, puanlama, not yok — yalnızca keşif ve yönlendirme

### Dio datasource

```dart
class SemanticApiDataSource {
  SemanticApiDataSource(this._dio);
  final Dio _dio;

  Future<List<SemanticBookResultModel>> search(SemanticSearchRequest req) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/semantic/search',
      data: req.toJson(),
    );
    // parse results
  }
}
```

`ApiService` (Google Books Edge Function) ile **ayrı Dio instance** kullanılır — farklı `baseUrl`.

---

## Kitap kimliği çözümleme (BookDetailPage)

### Tasarım kararı

Tüm Supabase işlemleri (`user_books`, `ratings`, `reviews`, `book_notes`) **Google Books volume ID** (`book_id text`) gerektirir. Çözümleme **detay sayfası açılışında** yapılır.

### Yeni provider: `resolvedBookProvider`

Mevcut `bookDetailProvider`'ın önüne veya yerine:

```
lib/features/books/presentation/providers/book_resolve_providers.dart
```

**Akış:**

```
1. book.id geçerli volume ID ise → mevcut bookDetailProvider akışı
2. book.id boş veya 'pending:' ile başlıyorsa:
   a. isbn13 varsa (widget veya pending prefix'ten)
   b. book_identity_cache Supabase sorgusu
   c. cache miss → Google Books: isbn:978...
   d. hâlâ yok → intitle:"Y" inauthor:"X" (mevcut searchBooks)
   e. en iyi eşleşme seç (title normalize + author match + language score)
3. Çözülen Book döndür → bookDetailProvider beslenir
4. book_identity_cache upsert (service_role RPC veya Edge Function)
```

### Çözümleme öncelik sırası

| Sıra | Yöntem | Güvenilirlik |
|------|--------|--------------|
| 1 | `book_identity_cache` hit | Yüksek |
| 2 | `isbn:978...` Google Books | Çok yüksek |
| 3 | `google_volume_id` (katalogdan taşınmışsa) | Yüksek |
| 4 | `intitle + inauthor` | Orta |
| 5 | Seed veri + hata UI | Düşük |

### BookDetailPage değişiklik gereksinimi

Mevcut kod `widget.book.id` ile favori/okuma durumunu **sayfa açılışında** bağlıyor. Çözümleme sonrası ID değişeceği için:

**Seçenek A (önerilen):** Sayfa açılmadan önce resolve + loading overlay

```dart
onTap: () async {
  final resolved = await ref.read(resolveBookUseCaseProvider)(result.toUnresolvedBook());
  if (!context.mounted) return;
  Navigator.push(context, MaterialPageRoute(
    builder: (_) => BookDetailPage(book: resolved),
  ));
}
```

**Seçenek B:** `BookDetailPage` içinde resolve; `detailedBook.id` gelene kadar favori/aksiyonlar disabled.

### Yeni use case

```
lib/features/books/domain/usecases/resolve_book_usecase.dart
lib/features/books/data/repositories/book_resolve_repository_impl.dart
```

Mevcut `BookRepository.searchBooks` ve `GoogleBooksUtils.buildUnifiedSearchQueries` (ISBN desteği) yeniden kullanılır.

---

## Duygu tonu sıralaması

Kaynak projedeki mapping korunur:

| UI Tone | CSV kolonu |
|---------|------------|
| Happy | joy |
| Surprising | surprise |
| Angry | anger |
| Suspenseful | fear |
| Sad | sadness |

FastAPI, pgvector sonuçlarını döndürmeden önce `emotion_scores` JSON'dan sıralar. `tone = All` ise similarity sırası korunur.

---

## Fazlama

### Faz 1 – MVP (öncelikli)

- [ ] Supabase: `book_catalog` + pgvector + `semantic_search_books` RPC
- [ ] Batch script: CSV → embedding → import (~5200 kitap)
- [ ] FastAPI: `POST /semantic/search` (Simple mod only)
- [ ] Flutter: `semantic_discovery` feature + sonuç listesi
- [ ] `resolveBookUseCase` + detay yönlendirmesi (ISBN öncelikli)
- [ ] `book_identity_cache` tablosu + resolve cache

### Faz 2

- [ ] Advanced mod (LLM rewrite + Google Books ingest → catalog upsert)
- [ ] `semantic_search_logs` analitik
- [ ] `semantic_query_cache` (Supabase)
- [ ] SearchPage'e "Semantik" sekmesi veya ayrı keşif ekranı
- [ ] Kategori + ton filtre UI

### Faz 3

- [ ] Kullanıcı kitaplığına göre kişiselleştirme (okunan kitapların embedding ortalaması)
- [ ] Ana sayfada "Sana özel keşif" rail'i
- [ ] IVFFlat → HNSW index geçişi (katalog büyürse)

---

## UI giriş noktaları (öneri)

1. **Arama sayfası** — mevcut `SearchPage`'e "Anlamsal" sekmesi (keyword / semantic toggle)
2. **Keşfet** — bottom nav veya home'da ayrı bölüm
3. **Kitap detay** — "Benzer hissettiren kitaplar" (Faz 3; mevcut `relatedBooksProvider`'a alternatif)

`SearchPage` mevcut debounce + `BookSearchResultTile` pattern'i semantik sonuçlar için yeniden kullanılabilir.

---

## Migration dosyaları (planlanan)

| Dosya | İçerik |
|-------|--------|
| `20260701000000_semantic_book_catalog.sql` | extension, tablo, index, RLS |
| `20260701000001_semantic_search_rpc.sql` | `semantic_search_books` RPC |
| `20260701000002_book_identity_cache.sql` | cache tablosu + resolve RPC |
| `20260702000000_semantic_search_logs.sql` | Faz 2 log tablosu |

---

## Manuel test

### Supabase SQL

```sql
-- Katalog kayıt sayısı
select count(*) from public.book_catalog;

-- Örnek vektör arama (test embedding ile)
select isbn13, title, similarity
from public.semantic_search_books(
  p_query_embedding := (select embedding from book_catalog limit 1),
  p_category := 'Fiction',
  p_limit := 5
);

-- Identity cache
select * from public.book_identity_cache where isbn13 = '9780006280934';
```

### FastAPI

```bash
curl -X POST https://api.example.com/api/v1/semantic/search \
  -H "Authorization: Bearer $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"lonely journey introspective novel","mode":"simple","limit":8}'
```

### Flutter

1. Semantik sorgu gir → sonuçlar listelenir
2. Karta tıkla → loading → detay açılır
3. Detayda favori ekle → `user_books.book_id` geçerli volume ID
4. Aynı kitaba tekrar gir → cache hit, hızlı açılış

---

## Yapılmaması gerekenler

- Gradio UI'ı Flutter'a embed etmek
- Chroma'yı production'da tutmak (pgvector hedefi)
- Öneri sayfasında Google Books ID zorunlu kılmak
- Gemini API key'i Flutter bundle'a koymak
- `book_detail_page.dart` içine semantik arama mantığı eklemek
- Mevcut liste öneri sistemini (`list_recommendations`) semantik arama ile karıştırmak
- `book_id` olarak ISBN kullanmak (`user_books` ve tüm tablolar volume ID bekler)

---

## Riskler ve azaltma

| Risk | Azaltma |
|------|---------|
| Gemini rate limit (batch import) | Resume destekli script, gece batch |
| Yanlış kitap eşleşmesi (title+author) | ISBN öncelikli resolve |
| FastAPI cold start gecikmesi | Keep-warm cron, sonuç cache |
| pgvector index kalitesi | `lists` parametresini kayıt sayısına göre ayarla; `analyze` |
| Katalog ile Google Books veri farkı | Detay sayfası her zaman Google Books'tan zenginleştirir |
| Çift cache (SQLite + Supabase) | Faz 1'de FastAPI in-memory/SQLite; Faz 2'de Supabase'e taşı |

---

## Bağımlılıklar özeti

| Bileşen | Paket / servis |
|---------|----------------|
| Flutter | `dio` (mevcut), yeni FastAPI base URL |
| FastAPI | `fastapi`, `uvicorn`, `langchain-google-genai`, `supabase-py`, `pandas` |
| Supabase | `pgvector` extension |
| Harici | Google Gemini API, Google Books API |

---

## Başarı kriterleri

- [ ] TR/EN serbest metin sorgusu anlamlı sonuç döndürür
- [ ] Öneri → detay geçişi volume ID ile çalışır; favori/puan/not kaydedilebilir
- [ ] Simple mod p95 yanıt süresi < 3 sn
- [ ] Katalog import tamamlanır (~5200 kitap)
- [ ] API anahtarları client'ta görünmez
- [ ] Mevcut clean architecture ve RLS kurallarına uyum

---

## İlgili dökümanlar

- `xdocs/foryoutab.md` — liste öneri sistemi (For You sekmesi)
- `xdocs/supabase.md` — Supabase entegrasyon kuralları
- `xdocs/booknote.md` — kitap notları mimari örneği
