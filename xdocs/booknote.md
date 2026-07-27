# Kitap Not Alma Modülü – Gereksinimler ve Uygulama Kuralları

## Amaç

Kullanıcıların okumakta olduğu veya okuduğu kitaplara, isteğe bağlı sayfa veya bölüm bilgisiyle bağlı notlar oluşturmasını sağlamak.

Notlar varsayılan olarak **özel**dir; kullanıcı isterse `is_public = true` ile herkese açık yapabilir. Kitap detayındaki **Notlar** sekmesinde yalnızca public notlar listelenir.

---

## Quote vs Note

| | Quote | Note |
|---|-------|------|
| Amaç | Kitaptan kısa alıntı paylaşımı | Okuma notu (özel veya public) |
| Görünürlük | Tüm giriş yapmış kullanıcılara açık | Public notlar herkese açık; özel notlar yalnızca sahibine |
| Sayfa / bölüm | Yok | Opsiyonel |
| Etiket | Yok | Var |
| Arama / filtre | Kitap detayda basit liste | Kitap detay (public) + My Notes (kendi notları) |
| İçerik | Kısa düz metin | Başlık + uzun metin (markdown) |

---

## Kapsam ve Fazlama

### Faz 1 – MVP (öncelikli)

* `book_notes` tablosu + RLS (`is_public` desteği)
* CRUD: ekle, düzenle, sil (`is_public` toggle ile)
* Kitap detayda **Notlar** sekmesi — `is_public = true` notlar herkes tarafından okunabilir
* Profil → **My Notes** ekranı (son eklenen notlar, arama, etiket filtreleme, düzenleme, silme)
* Basit metin arama (`ilike`; debounce ile)
* Etiket ekleme (chip tabanlı filtre)
* Sayfalama (cursor veya offset)
* Düz metin içerik (markdown render yok)

### Faz 2

* Markdown editör + render (kalın, italik, liste, başlık)
* Görünüm toggle: kronolojik / sayfa sırası / bölüm gruplama
* Habit okuma log'undan not oluştururken sayfa önerisi (opsiyonel)

---

# Mimari (ZORUNLU)

Diğer feature'larla aynı clean architecture:

```
UI → Provider → UseCase → Repository → Supabase
```

Supabase çağrıları UI içinde yapılmamalı.

## Feature yapısı

```
features/book_notes/
 ├── presentation/
 │    ├── pages/
 │    │    ├── my_notes_page.dart
 │    │    └── book_notes_tab.dart      # kitap detay sekmesi widget'ı
 │    ├── widgets/
 │    └── providers/
 │
 ├── domain/
 │    ├── entities/
 │    └── repositories/
 │
 └── data/
      ├── models/
      ├── repositories/
      └── datasources/
```

`book_detail_page.dart` içine iş mantığı eklenmemeli; yalnızca `BookNotesTab` widget'ı embed edilir.

---

# Temel Özellikler (MVP)

Giriş yapmış kullanıcı:

* Bir kitaba sınırsız sayıda not ekleyebilir.
* Notunu belirli bir sayfaya bağlayabilir (opsiyonel).
* Notu bölüm veya başlık bilgisine bağlayabilir (opsiyonel, serbest metin).
* İsterse sayfa ve bölüm bilgisini birlikte kullanabilir.
* Notlarını düzenleyebilir ve silebilir (hard delete).
* Notunu public veya özel olarak işaretleyebilir (`is_public`; varsayılan `false`).
* Notlarını arayabilir ve etikete göre filtreleyebilir (My Notes).

Giriş yapmamış kullanıcı not ekleyemez; public notları kitap detay **Notlar** sekmesinde okuyabilir.

---

# Giriş Noktaları

1. **Kitap detay → Notlar sekmesi** — bu kitaba ait public notlar; herkes okuyabilir, giriş yapmış kullanıcı ekleyebilir
2. **Profil → My Notes** — kullanıcının tüm notları (public + özel); düzenleme ve silme
3. *(Faz 2)* Habit okuma log sheet — mevcut kitap ve sayfa bağlamıyla hızlı not

---

# Veri Modeli

## Tablo: `book_notes`

```sql
id            uuid primary key default gen_random_uuid()
user_id       uuid not null references auth.users (id) on delete cascade
book_id       text not null          -- Open Library work id (FK yok; kitap DB'de tutulmaz)
page_number   integer null check (page_number is null or page_number > 0)
chapter_title text null              -- serbest metin; API'den bölüm listesi gelmez
note_title    text not null check (char_length(trim(note_title)) > 0)
note_content  text not null check (char_length(trim(note_content)) > 0)
tags          text[] not null default '{}'
is_public     boolean not null default false
created_at    timestamptz not null default now()
updated_at    timestamptz not null default now()
```

## Entity

```dart
class BookNoteEntity {
  final String id;
  final String userId;
  final String bookId;
  final int? pageNumber;
  final String? chapterTitle;
  final String noteTitle;
  final String noteContent;
  final List<String> tags;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

---

# Validasyon

| Alan | Kural |
|------|-------|
| `note_title` | Zorunlu, trim sonrası 1–200 karakter |
| `note_content` | Zorunlu, trim sonrası 1–10.000 karakter |
| `page_number` | Opsiyonel; pozitif tam sayı |
| `chapter_title` | Opsiyonel; max 100 karakter |
| `tags` | Max 10 etiket; her biri max 40 karakter; trim + küçük harfe normalize (uygulama katmanında) |

---

# Not İçeriği

## Faz 1 (MVP)

Düz metin `TextField` / `TextFormField`. Markdown syntax kaydedilebilir ancak render edilmez.

## Faz 2

Markdown destekli editör ve önizleme (kalın, italik, liste, başlık).

---

# Etiket Sistemi

* Notlara en fazla 10 etiket eklenebilir.
* Etiketler kayıt öncesi trim edilir ve küçük harfe çevrilir (`flutter` = `Flutter`).
* MVP'de filtreleme: chip listesi (kullanıcının tüm notlarındaki benzersiz etiketler).

Örnek etiketler: `flutter`, `clean-code`, `architecture`, `important`

---

# Arama

## MVP

* Client veya Supabase `ilike` ile arama
* Debounce: ~500 ms
* Aranacak alanlar: `note_title`, `note_content`, `chapter_title`, `tags`
* Kitap detay **Notlar** sekmesinde arama yalnızca o kitaba ait public notları kapsar
* My Notes'ta arama kullanıcının tüm notlarını (public + özel) kapsar

---

# Kitap Detay Sayfası

Mevcut **Reviews | Quotes** tab yapısına **Notlar** sekmesi eklenir.

**Sekme sırası:** Reviews → Notlar → Quotes

### Notlar sekmesi (MVP)

* Bu kitaba ait `is_public = true` notlar listelenir; **herkes okuyabilir** (giriş gerekmez)
* Sıralama: `created_at desc`
* Arama kutusu (yalnızca public notlar, bu kitap kapsamında)
* Giriş yapmış kullanıcılar not ekleyebilir; formda public/özel toggle bulunur
* Form alanları: başlık, içerik, opsiyonel sayfa, opsiyonel bölüm, etiketler
* Boş durum: "Henüz public not yok"
* Düzenleme ve silme yalnızca not sahibine aittir

Not UI'ı `BookNotesTab` widget'ı olarak ayrı dosyada tutulur; `book_detail_page.dart` şişirilmez.

---

# Görünüm Modları

## MVP

Varsayılan: **kronolojik** (`created_at desc`).

## Faz 2

Kullanıcı toggle ile seçebilir:

**Sayfa sırası** — `page_number asc nulls last`, sayfasız notlar en sonda

```
Sayfa 18
  • Not 1
Sayfa 22
  • Not 2
(sayfasız)
  • Not 3
```

**Bölüm gruplama** — `chapter_title` alfabetik; boş bölüm "Bölüm belirtilmemiş" grubunda

```
Bölüm 1
  • Notlar
Bölüm 2
  • Notlar
```

`chapter_title` kullanıcı tarafından girilen serbest metindir; Google Books API bölüm listesi sağlamaz.

---

# Kullanıcı Paneli – My Notes

Profil sayfasından erişilebilen **My Notes** ekranı.

### MVP içeriği

* Son eklenen notlar (kitap başlığı + not başlığı + tarih)
* Arama kutusu
* Etiket chip filtreleme
* Nota tıklanınca ilgili kitap detayına yönlendirme
* Sayfalama

---

# Repository Metodları

```dart
Future<List<BookNoteEntity>> getPublicNotesByBook(
  String bookId, {
  String? searchQuery,
  int limit = 20,
  int offset = 0,
}); // is_public = true; kitap detay Notlar sekmesi

Future<List<BookNoteEntity>> getMyNotes({
  String? searchQuery,
  List<String>? tagFilter,
  int limit = 20,
  int offset = 0,
});

Future<List<String>> getMyTags(); // benzersiz etiket listesi

Future<BookNoteEntity> addNote(BookNoteEntity note);
Future<BookNoteEntity> updateNote(BookNoteEntity note);
Future<void> deleteNote(String noteId);
```

---

# Performans

* Liste sorgularında sayfalama zorunlu (varsayılan `limit: 20`).
* `ListView.builder` ile sanal liste; tüm notlar tek seferde çekilmez.

---

# Güvenlik

Supabase Row Level Security (RLS) etkin olmalıdır.

## Politikalar

| İşlem | Kural |
|-------|-------|
| SELECT | `is_public = true OR user_id = auth.uid()` — `anon` ve `authenticated` rolleri |
| INSERT | `user_id = auth.uid()` — yalnızca `authenticated` |
| UPDATE | `user_id = auth.uid()` |
| DELETE | `user_id = auth.uid()` |

Public notlar kitap detayda herkese okunabilir; özel notlar yalnızca sahibi tarafından görülür ve yönetilir.

---

# i18n ve UX

* Tüm kullanıcıya dönük metinler `app_en.arb` / `app_tr.arb` üzerinden.
* Hata mesajları mevcut `AppFeedback` / `l10n` kalıbını takip eder.
* Auth hatası: "Giriş yapmanız gerekiyor" snackbar'ı (mevcut review/quote davranışıyla uyumlu).
* Silme işlemi onay dialogu ile.

---

# İlişkili Özellikler (bilgi)

* `user_books.progress` yüzde (0–100) tutar; not `page_number` ile otomatik senkronize edilmez (Faz 2'de opsiyonel öneri).
* `reading_logs.pages_read` günlük toplam sayfa tutar; tek sayfa numarası değildir.
* Kitap bilgisi (başlık, kapak) Open Library / cache üzerinden çözülür; `book_id` text olarak saklanır.

---

# Uygulama Kontrol Listesi

- [ ] Supabase migration: `book_notes` tablosu + RLS + indeksler
- [ ] `BookNoteEntity` + repository + datasource
- [ ] Riverpod provider'lar (kitap bazlı + global)
- [ ] `BookNotesTab` widget (kitap detay)
- [ ] `MyNotesPage` + profil giriş noktası
- [ ] l10n string'leri (EN + TR)
- [ ] Boş durum ve hata durumu widget'ları
