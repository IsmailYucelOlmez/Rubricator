# DESIGN.md — Rubricator (Web)

> Rubricator'ın web yüzü için tasarım kimliği. Agent her web UI işinde önce bunu okur.
> **Kapsam şimdilik sadece web (`site/`).** Mobil uygulamanın tasarımı hazırdır ve kaynağı `lib/core/theme/` altındadır.
> Web, marka değerlerini oradan alır ama kendi CSS token katmanını kullanır.
> Not: `xdocs/design.md` eski bir paleti anlatıyor (#8B1E2D, altın vb.). Güncel değerler koddadır ve bu dosyadadır.

## 1. Ürün
- **Ne:** Kitap keşfi, okuma takibi ve yapay zekâ önerileri sunan bir uygulama. Web sitesi (rubricator.site) uygulamanın tanıtım yüzüdür ve **Virgil** öneri özelliğinin web sürümünü içerir.
- **Web sayfaları:** Ana sayfa (landing), Virgil, Hakkımızda, İletişim, Gizlilik Politikası, Hesap silme, e-posta onay sayfası, 404. Tüm sayfalar **EN + TR** olarak üretilir.
- **Teknoloji:** Deno ile TypeScript şablonlarından üretilen statik HTML (`site/build.ts`), tek CSS dosyası (`site/static/site.css`), framework'süz ES module JS (`site/static/js/`). GitHub Pages'e deploy edilir. React, Tailwind veya bundler kullanılmaz.
- **Ton:** Modern ve temiz. Nötr yüzeyler, bol boşluk, tek vurgu rengi. Editoryal dokunuş sadece logo yazısında (Nouveau), Virgil wordmark'ında (Megrim) ve kitap kapaklarındadır.
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
| `--v-paper` | #FFFFFF | #161A1D | Virgil "kâğıdı" (mobildeki `VirgilColors.paper`): Virgil sayfası ve landing'deki Virgil bölümü zemini |
| `--scrim` | #161A1D @60% | aynı | Dialog arka planı (`::backdrop`), iki temada da koyu |
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
- **Megrim** (`site/static/fonts/Megrim-Regular.woff2`, OFL; kaynak `assets/Virgil/Megrim`): **sadece "Virgil" wordmark'ında** (`.v-word`: Virgil sayfası ve landing'deki Virgil bölümü), mobildeki Virgil modülüyle aynı. Başka metinde kullanılmaz.
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
| İletişim formu | `.contact-form`, `.panel`, `.field`, `.field.hp`, `.status` | İletişim sayfası. Ad (isteğe bağlı), e-posta, mesaj; alan altı hatalar (`fields.js`, Virgil ile ortak). JS veya Supabase yoksa form gizli kalır, e-posta adresi gösterilir. `.field.hp` bot tuzağı (ekran dışı, `tabindex=-1`) |
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
- **Kitap kapağı:** 2:3 oran, `object-fit: cover`. `.book-cover` kutusu her sonuçta vardır ve `--soft` zeminlidir. Kapak yoksa veya yüklenemezse `--icon-book` ikonlu yer tutucu kalır, hizalama bozulmaz. Virgil ızgarasında 10px yarıçap (mobildeki gibi).
- **Tipografik kapak** (`.tcover` + `.tc-ink/.tc-red/.tc-soft`): gerçek kapak görseli yerine token renkleriyle çizilen örnek kapak. Yalnızca dekoratif çizimlerde (landing hero) kullanılır; telif/marka sorunu yoktur, iki temada da çalışır.
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
| Hero | `.hero`, `.hero-art`, `.tile`, `.tile-reading`, `.tcover`, `.progress`, `.week`, `.fan`, `.eyebrow`, `.lead` | Landing. Sağda uygulamanın bir görünümü (`aria-hidden`, örnek veri EN+TR): okuduğun kitap + ilerleme, okuma serisi, liste. Logo tekrar edilmez, Virgil'e özel görsel yok |
| Buton | `.btn`, `.btn.secondary`, `.btn.store` (ikonlu, Google Play), `.link-button`, `.actions` | Pill. Devre dışı (`:disabled` / `aria-disabled`) nötr: `--soft` zemin, `--muted` metin. `.link-button` yatay padding'siz (sol hizayı korur) |
| Kart | `.cards`, `.card` | 3 kart: 832px altında tek sütun, üstünde 3 sütun. 4 kart: 640px'ten itibaren 2×2. Diğer sayılar auto-fit ≥260px |
| Bilgi kutusu | `.note` | `--soft` zemin |
| Durum mesajı | `.status[data-kind=info\|ok\|error]` | `role=status`, `aria-live=polite`. Tür ikonla da gösterilir: CSS `::before` + `mask` (`--icon-info/ok/error`, `data:` SVG). Markup ve `say()` düz metin kalır. Sol çubuk yok |
| Form | `.field`, `.field-narrow`, `.field.check`, `.hint`, `.field-error`, input/textarea/select | Görünür label zorunlu. Alan yüksekliği 44px, hover'da `--text` kenar. Doğrulama hatası alanın altında: `aria-invalid` (2px `--primary-text` kenar) + ikonlu `.field-error` (`aria-describedby` ile bağlı, JS `checkFields`). `#status` yalnızca form geneli hatalar için |
| Sekme | `.tabs`, `.tab[aria-pressed]` | Giriş / Kayıt. Tek kaplı segmented control (`--bg` zemin, pill). Seçili parça `--surface` + `--border-strong` kenar, seçili olmayan `--muted`. Kırmızı sadece gönder butonunda |
| Panel | `.panel` | Virgil giriş/kayıt formları, max 44rem |
| Virgil ekranı | `.v-screen`, `.v-frame`, `.v-head`, `.v-brand`, `.v-word`, `.v-badge`, `.v-account`, `.v-auth`, `.v-tagline`, `.v-lead`, `.v-app`, `.v-content`, `.v-intro`, `.v-note`, `.v-dock` | Mobildeki öneri ekranının düzeni: `--v-paper` zeminli, ekran yüksekliğinde; üstte marka satırı (`h1` = Megrim "Virgil" + BETA, sağda hesap; telefonda yalnızca "Çıkış yap"), ortada içerik (aramadan önce ortalanmış `.v-intro`, sonra sonuçlar), altta `position: sticky` arama alanı (`.v-dock`). Giriş yapılmamışken slogan + açıklama + giriş paneli |
| Virgil arama | `.v-bar`, `.v-input`, `.v-round`, `.v-submit`, `.v-genres`, `.v-chips`, `.v-chip` | `.v-dock` içinde. Tek satır giriş (15px köşe, `--text` kenar, `--v-paper` zemin), yuvarlak tür düğmesi (yalnızca EN, `aria-expanded`), kırmızı yuvarlak gönder (tüy kalem, `aria-label`). Tür çipleri çubuğun hemen üstünde, tek satır yatay kaydırmalı. Arama alanının etiketi bilinçli olarak `.sr-only` (mobildeki gibi yalnızca placeholder görünür) |
| Kitap sonucu | `.v-query`, `.v-category`, `.v-grid`, `.v-card`, `.v-card-title`, `.v-card-author`, `.v-card.skeleton`, `.book-cover`, `.empty`, `.v-dialog` | Mobildeki gibi: sorgu sonuçların başlığı (`h2`, önünde gizli "Öneriler:"), EN'de seçili tür altında. Kapak ızgarası: telefonda 2 sütun, genişte ~150px kapak; kartta yalnızca başlık (2 satır) + yazar. Kart bir `button` → `<dialog>`: kapak, başlık, yazar, açıklama. Kategori gösterilmez (katalog değerleri "Unknown", "Literature" gibi anlamsız olabiliyor). Aranırken 6 iskelet kart; hata olursa önceki sonuçlar geri gelir. Sonuç yok: `.empty` |
| Landing Virgil bölümü | `.section.v-showcase`, `.v-steps`, `.v-phone`, `.v-phone-brand`, `.v-phone-body`, `.v-fake-input` | `--v-paper` zeminli bölüm: solda Megrim wordmark (`h2`, görünmez başlık metniyle), slogan, açıklama, yuvarlak numaralı 3 adım ve "Virgil'i dene"; sağda telefon çerçevesinde Virgil'in öneri ekranı (örnek veri EN+TR, `aria-hidden`) |
| Uzun metin | `.prose`, `.table-wrap`, `.meta`, `.contact-box` | Gizlilik, Hakkımızda, İletişim |

## 8. Ekrana özel kurallar
- **İki dil:** Her metin `en` ve `tr` karşılığıyla birlikte TS string nesnelerine yazılır (`UI` → layout.ts, `VIRGIL_STRINGS` → virgil.ts, `PAGES` → pages.ts). Türkçe metin ~%20–30 daha uzundur, düzen buna göre test edilir.
- **JS sadece gerektiği yerde:** Düz sayfalarda script yoktur. Script'li sayfa `PageRef.scripts` ile tanımlanır ve CSP ona göre üretilir.
- **CSP:** `style-src 'self'` (inline `style=""` ve `<style>` çalışmaz), harici script/font yok. Görsel stil her zaman `site.css` içindeki sınıflarla verilir.
- **Virgil sayfası durumları:** unavailable (env yok), noscript, giriş, giriş hatası, kayıt, şifre sıfırlama (2 adım), arama boş, sorgu hatası, aranıyor, sonuçlar, sonuç yok, günlük limit, oturum süresi doldu. Her değişiklikte `virgil_states.mjs` ile görüntülenir.
- **Günlük limit:** Hak bitince (`usage.used >= usage.limit` ya da 429 `daily_limit_reached`) "Öneri al" butonu `aria-disabled="true"` olur (odaklanabilir kalır), gönderim JS'te engellenir. `#usage` (`aria-live="polite"`, butonun `aria-describedby`'ı) `errDailyLimit` metnini gösterir: neden + yarın yenilenir. Mesaj `#status`'ta tekrarlanmaz. `virgil_states.mjs` iki yolu da görüntüler: `limit_error` (429) ve `limit_reached` (sayfa açılırken hak bitmiş).
- **Durumlar görüntüleri:** `virgil_states.mjs` ayrıca `auth_field_error` (alan altı hatalar), `searching` (iskelet) ve `book_dialog` (ayrıntı penceresi) durumlarını alır. Tür paneli (EN) script'te yok, elle doğrulanır.
- **Virgil ve mobil:** Web Virgil sayfası mobildeki Virgil modülünün dilini izler (wordmark, çubuk, çip paneli, sorgu = başlık, kapak ızgarası). Düzen mobildeki öneri ekranıyla aynı (çubuk altta, sticky). Bilinçli farklar: hub ekranı yok (sayfa doğrudan öneri ekranıyla açılır); kitap sayfası yerine dialog; vurgu rengi sitenin `--primary`'si (mobildeki #EF233C eklenmedi).
- **Kitap sonuçları:** Kullanıcı ve katalog verisi sadece `textContent` ile basılır (XSS). Açıklamalar uzun olabilir, uzun metin testi mock'ta var.
- **Onay sayfası:** Statik durum mesajı `data-kind="ok"` ile gelir. JS hata bulursa `error` yapar.
- **İletişim formu:** `static/js/contact.js` → edge function `contact` (Resend ile support adresine e-posta, gönderenin adresi yalnızca Reply-To). Sunucu tarafı: izinli origin, alan doğrulaması, bot tuzağı, IP başına saatte 3 mesaj (`contact_allow`, IP'nin tuzlanmış özeti 1 gün tutulur). Gizlilik politikasında Resend listelidir.
- **Landing:** Hero uygulamanın tamamını anlatır: birincil eylem "Android uygulamasını indir" (`.btn.store` → Google Play, `PLAY_STORE_URL`), ikincil "Virgil'i dene" (`.btn.secondary`). Siteden dışarı giden linkler `build_test.ts` içinde izin listesindedir. Özellikler `.cards` ile gösterilir, her kart kısa başlık ve tek cümleden oluşur.
- **Hukuki sayfalar:** `.prose` + `.table-wrap`. Gizlilik politikası sürümü `PRIVACY_POLICY_VERSION` ile "Last updated" tarihi eşleşmeli (test kontrol eder).

## 9. Karar günlüğü ve bilinen sorunlar
**Kararlar**
- 2026-09-30 — Web tonu "modern, temiz". Marka değerleri mobille aynı (kırmızı #BA181B, #161A1D / #F5F3F4, Outfit + Nouveau logo).
- 2026-09-30 — Web tasarım kapsamı `site/`. Mobil tasarım bu dosyanın kapsamı dışında.
- 2026-09-30 — `--success` token'ı eklendi (açık #2A8A4A, koyu #5CC98A). `.status[data-kind=ok]` kenarı bunu kullanır.
- 2026-09-30 — Tasarım gözden geçirmesi: ince kırmızı göstergeler `--primary-text`'e geçti, seçili sekme nötr yapıldı, kapak yer tutucusu eklendi, limit dolunca buton kapanıyor, mobil header'da dil düğmesi logo satırına alındı, kart ızgarası tek kalan kartı önleyecek şekilde sabitlendi, dokunma hedefleri 44px'e çıkarıldı, landing'deki "mobil uygulama" notu özellikler bölümüne taşındı.

- 2026-09-30 — ui-reviewer bulguları uygulandı: limit `aria-disabled` + canlı ipucu, seçili sekme sakinleştirildi, `--border-strong`, 3 kart 52rem'de 3 sütun, hero görseli 900px altında gizli, kategori etiketi nötr, nötr devre dışı buton, not tam genişlik (metin 70ch), onay sayfası `ok`.

- 2026-10-01 — Bileşen iyileştirmesi 1–4 (mockup: `design/mockups/components.html`): kitap sonucu kartı, ikonlu durum mesajı, alan altı form hataları, segmented sekmeler.
- 2026-10-01 — Hero yeniden tasarlandı (mockup: `design/mockups/hero-virgil.html`, seçenek A revize): logo yerine uygulamanın görünümü, Google Play birincil eylem. Virgil sayfası mobil modüle yaklaştırıldı; liste kartları yerine kapak ızgarası + dialog. Megrim fontu yalnızca Virgil wordmark'ı için eklendi. Vurgu rengi değişmedi.

- 2026-10-03 — Virgil sayfası mobil öneri ekranının düzenine geçirildi (mockup `design/mockups/virgil-layout.html`, V1): marka satırı, ortada içerik, altta sticky arama alanı. Landing'deki Virgil tanıtımı L2: adımlar + telefon çerçevesinde Virgil ekranı. Kitap ayrıntısından kategori kaldırıldı.

- 2026-10-03 — Hakkımızda'dan "Kim geliştiriyor?" bölümü kaldırıldı. İletişim sayfasına Supabase + Resend ile çalışan form eklendi; gizlilik politikası 03.10.2026 sürümüne güncellendi.

**Bilinen sorunlar (öneri; kullanıcı onayı olmadan uygulanmaz)**
- [Boşluk] site.css'te ölçek dışı rem değerleri var. Bir kurala dokunulduğunda o kuralın değerleri ölçeğe çekilir. Toplu refactor yapılmaz.
- [Odak sırası] Mobilde `.lang-switch` görsel olarak nav'dan önce (logo satırında) ama DOM'da sonra. Klavye sırası görsel sıradan farklı. Düşük önem.
- [Kenar] `.tab`, `.lang-switch`, `.btn.secondary` hâlâ `--border` (≤1.6:1) kullanıyor. Metinleriyle tanınabildikleri için bırakıldı.
