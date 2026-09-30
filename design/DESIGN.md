# DESIGN.md — Rubricator (Web)

> Rubricator'ın web yüzü için tasarım kimliği. Agent her web UI işinde önce bunu okur.
> **Kapsam şimdilik sadece web (`site/`).** Mobil uygulamanın tasarımı hazırdır ve kaynağı `lib/core/theme/` altındadır.
> Web, marka değerlerini oradan alır ama kendi CSS token katmanını kullanır.
> Not: `xdocs/design.md` eski bir paleti anlatıyor (#8B1E2D, altın vb.). Güncel değerler koddadır ve bu dosyadadır.

## 1. Ürün
- **Ne:** Kitap keşfi, okuma takibi ve yapay zekâ önerileri sunan bir uygulama. Web sitesi (rubricator.site) uygulamanın tanıtım yüzüdür ve **Virgil** öneri özelliğinin web sürümünü içerir.
- **Web sayfaları:** Ana sayfa (landing), Virgil, Hakkımızda, İletişim, Gizlilik Politikası, Hesap silme, e-posta onay sayfası, 404. Tüm sayfalar **EN + TR** olarak üretilir.
- **Teknoloji:** Deno ile TypeScript şablonlarından üretilen statik HTML (`site/build.ts`), tek CSS dosyası (`site/static/site.css`), framework'süz ES module JS (`site/static/js/`). GitHub Pages'e deploy edilir. React, Tailwind veya bundler kullanılmaz.
- **Ton:** Modern ve temiz. Nötr yüzeyler, bol boşluk, tek vurgu rengi. Editoryal dokunuş sadece logo yazısında (Nouveau) ve kitap kapaklarındadır.
- **İlkeler (uygulamayla ortak):** Kapaklar ön plandadır, metin ikincildir. Kırmızı sadece eylemlerde kullanılır. Görsel gürültü düşük, okunabilirlik yüksek tutulur.
- **Kaçınılacaklar:** Rastgele renkler, inline style, tutarsız boşluk, büyük gölgeler, gradyanlar, dekoratif animasyonlar, ikinci bir vurgu rengi.

## 2. Renk
Tek kaynak: `site/static/site.css` → `:root` (açık) ve `@media (prefers-color-scheme: dark)` (koyu). Tema sistem tercihini izler; manuel tema düğmesi yoktur.

| Token | Açık | Koyu | Kullanım |
|---|---|---|---|
| `--bg` | #F5F3F4 | #161A1D | Sayfa arka planı (uygulamanın off-white / deep black'i) |
| `--surface` | #FFFFFF | #1F2428 | Kart, panel, `.section.alt` |
| `--text` | #161A1D | #F5F3F4 | Ana metin |
| `--muted` | #5B5F63 | #B4B8BC | İkincil metin, yazar, ipucu |
| `--primary` | #BA181B | #BA181B | Marka kırmızısı. **Dolu buton zemini** |
| `--primary-text` | #BA181B | #FF7A7D | Kırmızı **metin**, link ve **ince göstergeler** (nav alt çizgisi, hata kenarı) |
| `--on-primary` | #FFFFFF | #FFFFFF | Kırmızı zemin üstü metin |
| `--border` | #161A1D @14% | #F5F3F4 @16% | Kenarlıklar, ayraçlar (dekoratif) |
| `--border-strong` | #7E8286 | #787E83 | Form alanı kenarı (input, textarea, select). ≥3:1 |
| `--soft` | #F0EBD8 | #2A2E31 | Hero görsel zemini, `.note`, `.status`, kod |
| `--focus` | #1A5FD0 | #7FB0FF | Odak halkası (bilinçli olarak markadan farklı) |
| `--success` | #2A8A4A | #5CC98A | Başarı **göstergesi** (`.status[data-kind=ok]` kenarı). Metin rengi olarak kullanılmaz (açıkta 4.5:1 altında) |

Ölçülen kontrastlar (`check_contrast.py`):

| Çift | Açık | Koyu |
|---|---|---|
| text / bg | 15.85 | 15.85 |
| muted / bg | 5.83 | 8.77 |
| muted / soft | 5.39 | 6.86 |
| primary-text / bg | 5.88 | 6.95 |
| success / soft (gösterge, ≥3) | 3.64 | 6.64 |
| border-strong / bg (≥3) | 3.50 | 4.26 |
| border-strong / surface (≥3) | 3.87 | 3.81 |
| on-primary / primary | 6.49 | 6.49 |
| primary-text (UI göstergesi) / bg | 5.88 | 6.95 |

Kurallar:
- Yeni renk eklerken **iki bloğa birden** ekle (açık + koyu) ve kontrastı ölç.
- Kırmızı metin/link ve ince göstergeler (kenar, alt çizgi) için `--primary-text`, kırmızı zemin için `--primary` kullan. `--primary` koyu temada `--bg` üzerinde 2.70:1 kalır, gösterge olarak kullanılmaz.
- Mobildeki Virgil vurgu rengi (#EF233C) web'de kullanılmıyor. Karar verilmeden eklenmez.

## 3. Tipografi
- **Outfit** (400/500/600/700, `site/static/fonts/`, self-host): tüm başlık ve gövde metni.
- **Nouveau** (DT Nouveau): **sadece "Rubricator" logo yazısında** (`.brand-name`) kullanılır. Türkçe karakter içermediği için başka hiçbir metinde kullanılmaz.
- Harici font servisi yok (CSP `font-src 'self'`).

| Rol | Değer |
|---|---|
| body | 1.0625rem (17px), satır yüksekliği 1.65 |
| h1 | clamp(2.1rem, 5.2vw, 3.4rem), 700, lh 1.15, letter-spacing −0.01em |
| h2 | clamp(1.45rem, 3vw, 1.95rem), 600 |
| h3 | 1.15rem, 600 |
| `.lead` | clamp(1.1rem, 2vw, 1.3rem), `--muted`, max 46ch |
| `.eyebrow` | 0.85rem, 600, BÜYÜK HARF, letter-spacing 0.08em, `--primary-text` |
| `.hint`, `.meta` | 0.92–0.95rem, `--muted` |
| Uzun metin | `.prose` max 70ch (`--prose`) |

## 4. Şekil, boşluk ve derinlik
- **Yarıçap:** `--radius` 14px (kart, panel, not, status) · pill 999px (buton, sekme, dil düğmesi) · 10px (input) · 28px/20px (hero görseli) · 6px (kitap kapağı).
- **Derinlik:** Gölge yok. Katmanlar `--surface` ile `--bg` arasındaki ton farkı ve 1px `--border` ile ayrılır.
- **Düzen:** `.container` max 1080px (`--maxw`), yatay padding 1.25rem. Bölüm dikey boşluğu `clamp(2rem, 5vw, 3.5rem)`.
- **Boşluk ölçeği (yeni CSS için):** 0.25 · 0.5 · 0.75 · 1 · 1.25 · 1.5 · 2 · 2.5 · 3 · 4 rem. Mevcut CSS'te ölçek dışı değerler var (0.35, 0.6, 0.85, 1.1…). Bunlar dokunulan kurala göre zamanla ölçeğe çekilir (bkz. §9).
- **Breakpoint'ler:** Mobile-first. 40rem (640px): 4 kartlık `.cards` 2×2. 48rem (768px): header tek satır. 52rem (832px): 3 kartlık `.cards` 3 sütun. 900px: hero iki sütun ve hero görseli görünür (altında gizli; dekoratif, header logosunu tekrar eder). Kontrol genişlikleri 375 / 768 / 1280.
- **Dokunma hedefi:** Nav linkleri, dil düğmesi, sekmeler, `.link-button` ve footer linkleri en az 2.75rem (44px) yüksekliktedir.

## 5. İkonlar ve görseller
- İkon seti yok. Gerekirse inline SVG kullanılır (`currentColor`, `aria-hidden="true"`). Harici ikon fontu/CDN kullanılmaz.
- **Kitap kapağı:** 2:3 oran (72×108 liste), `object-fit: cover`, 6px yarıçap. `.book-cover` kutusu her sonuçta vardır ve `--soft` zeminlidir. Kapak yoksa veya yüklenemezse boş yer tutucu olarak kalır, hizalama bozulmaz.
- Kapak URL'leri farklı kataloglardan gelir. Script'li sayfalarda sadece `https:` görsellere izin var (CSP).
- Uygulama ikonu ve favicon: `web/icons/`, `web/favicon.png` (build sırasında kopyalanır).

## 6. Hareket
- Minimal. Sadece `scroll-behavior: smooth` var ve `prefers-reduced-motion` ile kapanır.
- Yeni geçişler 150–250 ms, `ease-out` olur, sadece opacity/transform kullanır ve reduced-motion'da kapanır.

## 7. Bileşen envanteri (`site/static/site.css`)
| Bileşen | Sınıf | Not |
|---|---|---|
| Sayfa kabuğu | `.site-header`, `.brand`, `.nav`, `.lang-switch`, `.site-footer`, `.skip-link` | `site/src/layout.ts` üretir. `.lang-switch` `<nav>` dışındadır: mobilde logo ile aynı satırda, linkler alt satırda |
| Kapsayıcı | `.container`, `.page`, `.section`, `.section.alt` | |
| Hero | `.hero`, `.hero-art`, `.eyebrow`, `.lead` | Landing |
| Buton | `.btn`, `.btn.secondary`, `.link-button`, `.actions` | Pill. Devre dışı (`:disabled` / `aria-disabled`) nötr: `--soft` zemin, `--muted` metin. `.link-button` yatay padding'siz (sol hizayı korur) |
| Kart | `.cards`, `.card` | 3 kart: 832px altında tek sütun, üstünde 3 sütun. 4 kart: 640px'ten itibaren 2×2. Diğer sayılar auto-fit ≥260px |
| Bilgi kutusu | `.note` | `--soft` zemin |
| Durum mesajı | `.status[data-kind=info\|ok\|error]` | `role=status`, `aria-live=polite` |
| Form | `.field`, `.field-narrow`, `.field.check`, `.hint`, input/textarea/select | Görünür label zorunlu |
| Sekme | `.tabs`, `.tab[aria-pressed]` | Giriş / Kayıt. Seçili sekme sakin: `--soft` zemin, `--text` kenar. Kırmızı sadece gönder butonunda |
| Panel | `.panel`, `.account-bar` | Virgil, max 44rem |
| Kitap sonucu | `.results`, `.book`, `.book-cover`, `.book-author`, `.book-category` | JS ile oluşturulur (`resultCard`). Kategori `--muted`, büyük harf yok (katalog dili sayfa dilinden farklı olabilir: TR'de "FİCTION" sorunu) |
| Uzun metin | `.prose`, `.table-wrap`, `.meta`, `.contact-box` | Gizlilik, Hakkımızda, İletişim |

## 8. Ekrana özel kurallar
- **İki dil:** Her metin `en` ve `tr` karşılığıyla birlikte TS string nesnelerine yazılır (`UI` → layout.ts, `VIRGIL_STRINGS` → virgil.ts, `PAGES` → pages.ts). Türkçe metin ~%20–30 daha uzundur, düzen buna göre test edilir.
- **JS sadece gerektiği yerde:** Düz sayfalarda script yoktur. Script'li sayfa `PageRef.scripts` ile tanımlanır ve CSP ona göre üretilir.
- **CSP:** `style-src 'self'` (inline `style=""` ve `<style>` çalışmaz), harici script/font yok. Görsel stil her zaman `site.css` içindeki sınıflarla verilir.
- **Virgil sayfası durumları:** unavailable (env yok), noscript, giriş, giriş hatası, kayıt, şifre sıfırlama (2 adım), arama boş, sorgu hatası, aranıyor, sonuçlar, sonuç yok, günlük limit, oturum süresi doldu. Her değişiklikte `virgil_states.mjs` ile görüntülenir.
- **Günlük limit:** Hak bitince (`usage.used >= usage.limit` ya da 429 `daily_limit_reached`) "Öneri al" butonu `aria-disabled="true"` olur (odaklanabilir kalır), gönderim JS'te engellenir. `#usage` (`aria-live="polite"`, butonun `aria-describedby`'ı) `errDailyLimit` metnini gösterir: neden + yarın yenilenir. Mesaj `#status`'ta tekrarlanmaz. `virgil_states.mjs` iki yolu da görüntüler: `limit_error` (429) ve `limit_reached` (sayfa açılırken hak bitmiş).
- **Kitap sonuçları:** Kullanıcı ve katalog verisi sadece `textContent` ile basılır (XSS). Açıklamalar uzun olabilir, uzun metin testi mock'ta var.
- **Onay sayfası:** Statik durum mesajı `data-kind="ok"` ile gelir. JS hata bulursa `error` yapar.
- **Landing:** Hero'da tek birincil eylem ("Virgil'i dene" → `.btn`) ve bir ikincil eylem ("Hakkımızda" → `.btn.secondary`) var. Özellikler `.cards` ile gösterilir, her kart kısa başlık ve tek cümleden oluşur.
- **Hukuki sayfalar:** `.prose` + `.table-wrap`. Gizlilik politikası sürümü `PRIVACY_POLICY_VERSION` ile "Last updated" tarihi eşleşmeli (test kontrol eder).

## 9. Karar günlüğü ve bilinen sorunlar
**Kararlar**
- 2026-09-30 — Web tonu "modern, temiz". Marka değerleri mobille aynı (kırmızı #BA181B, #161A1D / #F5F3F4, Outfit + Nouveau logo).
- 2026-09-30 — Web tasarım kapsamı `site/`. Mobil tasarım bu dosyanın kapsamı dışında.
- 2026-09-30 — `--success` token'ı eklendi (açık #2A8A4A, koyu #5CC98A). `.status[data-kind=ok]` kenarı bunu kullanır.
- 2026-09-30 — Tasarım gözden geçirmesi: ince kırmızı göstergeler `--primary-text`'e geçti, seçili sekme nötr yapıldı, kapak yer tutucusu eklendi, limit dolunca buton kapanıyor, mobil header'da dil düğmesi logo satırına alındı, kart ızgarası tek kalan kartı önleyecek şekilde sabitlendi, dokunma hedefleri 44px'e çıkarıldı, landing'deki "mobil uygulama" notu özellikler bölümüne taşındı.

- 2026-09-30 — ui-reviewer bulguları uygulandı: limit `aria-disabled` + canlı ipucu, seçili sekme sakinleştirildi, `--border-strong`, 3 kart 52rem'de 3 sütun, hero görseli 900px altında gizli, kategori etiketi nötr, nötr devre dışı buton, not tam genişlik (metin 70ch), onay sayfası `ok`.

**Bilinen sorunlar (öneri; kullanıcı onayı olmadan uygulanmaz)**
- [Boşluk] site.css'te ölçek dışı rem değerleri var. Bir kurala dokunulduğunda o kuralın değerleri ölçeğe çekilir. Toplu refactor yapılmaz.
- [Odak sırası] Mobilde `.lang-switch` görsel olarak nav'dan önce (logo satırında) ama DOM'da sonra. Klavye sırası görsel sıradan farklı. Düşük önem.
- [Kenar] `.tab`, `.lang-switch`, `.btn.secondary` hâlâ `--border` (≤1.6:1) kullanıyor. Metinleriyle tanınabildikleri için bırakıldı.
