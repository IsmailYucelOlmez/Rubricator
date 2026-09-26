# RLS ve yetki denetimi

## Yöntem
Repodaki **tüm migration'lar** (46 dosya) gerçek bir Postgres motorunda (PGlite) sırayla çalıştırıldı; Supabase'in `anon`/`authenticated`/`service_role` rolleri, `auth.uid()`, `storage`, `cron`, `net` taklit edildi ve — en önemlisi — Supabase'in **varsayılan yetkileri** eklendi (her yeni tablo/fonksiyon API rollerine açık gelir; tek engel RLS ve fonksiyon gövdesidir). Sonra tablolar, politikalar, view'lar ve fonksiyon yetkileri sorgulandı.

> **Sınır:** Bu, *migration'ların* ürettiği durumu denetler. Üretim veritabanı farklı olabilir (dashboard'dan oluşturulanlar, sonradan elle değişenler). Bu yüzden canlıda çalıştırılacak aynı sorgu hazır: [`supabase/tests/rls_audit_prod.sql`](../supabase/tests/rls_audit_prod.sql) (SQL editörüne yapıştırın, salt okunur). İki çıktıyı karşılaştırın.

Tekrarlanabilir kontroller:
```bash
npm install --no-save @electric-sql/pglite
node supabase/tests/rls_hardening_pglite.mjs   # 36 kontrol: aşağıdaki düzeltmeler + uygulamanın kullandıkları çalışmaya devam ediyor
node supabase/tests/virgil_quota_pglite.mjs    # 66 kontrol: sunucu tarafı kota
```

## Bulgular

### Düzeltildi (`20260926000000_rls_hardening.sql`)
| # | Bulgu | Etki | Düzeltme |
|---|---|---|---|
| 1 | `quotes` UPDATE politikası `USING true / WITH CHECK true` | Giriş yapmış **herkes** başkasının alıntısını yeniden yazabilir, `user_id`'sini devralabilirdi | Yalnızca sahibi günceller. Uygulama zaten `quotes`'u güncellemiyor (beğeni `toggle_quote_like` RPC'siyle) |
| 2 | `process_dirty_list_recommendations_batch`, `compute_list_recommendations_for_user`, `mark_list_recommendation_dirty` ve 4 tetikleyici fonksiyonu `SECURITY DEFINER` + `anon` çalıştırabiliyordu (migration'lar `service_role`'e grant etti ama PUBLIC/anon'u **revoke etmedi**) | Anonim biri `/rest/v1/rpc/...` ile gece toplu işini tetikleyebilir, herhangi bir kullanıcı için önerileri yeniden hesaplatabilir (yük/DoS) | `EXECUTE` public/anon/authenticated'dan alındı; tetikleyiciler çalışmaya devam ediyor (testle kanıtlı) |
| 3 | `search_logs` SELECT: `user_id IS NULL OR own` | **Anonim aramalar (Virgil sorguları dahil) herkes tarafından okunabilir** (anon dahil) | Yalnızca kendi satırları. "Popüler aramalar" `SECURITY DEFINER` RPC'lerinden gidiyor, etkilenmedi; anonim INSERT çalışıyor |
| 4 | `trbooks_scrape_runs` SELECT `anon, authenticated` `true` | Kazıma çalıştırma durumu/hata metinleri herkese açık | Politika kaldırıldı (yalnızca `service_role`) |
| 5 | `profile-photos` SELECT `anon, authenticated` `bucket_id = ...` | Bucket'taki tüm dosyalar listelenip kullanıcı id'leri (klasör adları) toplanabilir | Yalnızca kendi klasörü (`upload(upsert: true)` bunu gerektiriyor). Bucket public, `getPublicUrl` etkilenmedi |

### Edge Function'lar (aynı denetimin uzantısı)
| Bulgu | Düzeltme |
|---|---|
| `scrape-tr-books` ve `warm-genre-cache` **hiç kimlik doğrulaması yapmıyor**; `verify_jwt=false` ve servis rolüyle çalışıyorlar. İnternetten herkes kazıma / önbellek yazımı tetikleyebilirdi (Kitapyurdu WAF engeli, Google Books kotası) | `Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>` (veya isteğe bağlı `CRON_SECRET`) zorunlu; sabit zamanlı karşılaştırma. Cron zaten `vault.service_role_key` ile gönderiyor |
| `google-books`: `googleapis.com/books/v1` altındaki **her yol** iletiliyordu, `..` ile başka Google API'lerine çıkılabilirdi (aynı anahtarla); CORS `*`; hata mesajı **API anahtarını içeren URL'yi** istemciye yansıtıyordu | Yalnızca `GET /volumes` ve `/volumes/{id}`; bilinen parametreler ve sınırlı değerler; izinli origin'ler; hata mesajı istemciye gitmiyor (anahtar loglarda da maskeli) |

### Bilerek açık olanlar / bilinen kalanlar
| Konu | Durum |
|---|---|
| `genre_books_cache`, `google_books_search_cache`: `anon`+`authenticated` `INSERT/UPDATE true` | **Ertelendi.** Herkes önbelleğe sahte kitap/kapak yazabilir (tüm kullanıcılara sunulur). Kapatılamıyor çünkü yayındaki uygulama yazımları `try/catch`'siz `await` ediyor; reddedilirse kitap araması patlar. İstemci artık yazımı "en iyi çaba" yapıyor (`book_repository.dart`, `home_repository_impl.dart`). Yeni sürüm yayılınca [`supabase/deferred/cache_write_lockdown.sql`](../supabase/deferred/cache_write_lockdown.sql) uygulanmalı |
| `search_logs` anonim INSERT | Bilerek açık (giriş yapmamış kullanıcı araması). Sınırsız doldurulabilir (depolama); hız sınırı yok |
| `book_identity_cache`, `semantic_search_logs`, `upsert_book_identity_cache()` | **Migration'larda yok**, uygulama kullanıyor. RLS'leri denetlenemedi; canlı sorguyla (`rls_audit_prod.sql`) bakın |
| Okuma herkese açık tablolar (`reviews`, `ratings`, `quotes`, `review_likes`, `external_reviews`… `authenticated`'a `SELECT true`) | Tasarım gereği herkese açık içerik; `user_id`'ler görünüyor |
| `list_top_by_engagement`, `profile_display_name`, `search_logs_popular_*` `anon`'a açık `SECURITY DEFINER` | Bilerek: giriş yapmamış kullanıcı anasayfası ve toplu sayılar |

## Canlıda uygulananlar (27 Eylül 2026)
CLI ile `bookapp` projesine (`lnlqbrzetaofjwxudord`) uygulandı; `supabase db push` **kullanılmadı** çünkü uzak migration geçmişi tamamen boştu (veritabanı dashboard'dan yönetilmiş), 46 dosyanın hepsini yeniden çalıştırmaya kalkardı. Yalnızca seçilen dosyalar SQL olarak çalıştırıldı:

| Ne | Durum |
|---|---|
| `20260925000000_virgil_server_side_quota.sql` | Zaten uygulanmıştı (canlı tanımlar aynı) |
| `20260926000000_rls_hardening.sql` | Uygulandı; canlıda politika adları migration'la aynıydı. Geri dönüş: [`deferred/rollback_rls_hardening.sql`](../supabase/deferred/rollback_rls_hardening.sql) |
| `20260926000001_virgil_quota_refund_and_trbooks.sql` | Uygulandı; mevcut kullanım satırları korundu |
| `20260926000002_warm_genre_cache_cron_auth.sql` | **Yeni** (aşağıya bakın), uygulandı |
| `submit_user_trbook` (10 Eylül migration'ının 4. kısmı) | Yalnızca fonksiyon + grant uygulandı; kısıt/indeks/yardımcı fonksiyon zaten canlıdaydı |
| Edge Function'lar `rubricatorApi` (v4), `google-books`, `scrape-tr-books`, `warm-genre-cache` | `supabase functions deploy --use-api`; `AUTH_MODE` varsayılanı `enforce` |

Canlıda denetim sorgusu: **39 → 29 bulgu**; kalanlar aşağıdaki "bilerek açık" ve "ertelenen" listeleri.

### Canlıda ortaya çıkan ek bulgular
1. **`warm-genre-books-cache-weekly` cron işi hiç `Authorization` göndermiyordu** (`headers:='{}'`, dashboard'dan kurulmuş). Servis anahtarı kuralıyla Pazartesi 02:00'de 401 alıp sessizce çalışmayı bırakacaktı. Vault'tan anahtarı çalışma anında okuyacak şekilde yeniden planlandı (`20260926000002`). 7 kazıma işi ve `process-dirty` işi kontrol edildi: gömülü anahtar güncel anahtarla aynı, `process-dirty` `postgres` olarak çalıştığı için revoke'tan etkilenmedi.
2. **`upsert_book_identity_cache(...)`** (migration'larda yok): `SECURITY DEFINER`, oturum denetimi yok, `anon` çalıştırabiliyor ve `on conflict do update` ile üzerine yazıyor. Herkes bir ISBN'i başka bir Google kitap kimliğine bağlayabilir (kitap detayında yanlış kitap gösterilir). Önbellek tablolarıyla aynı sınıf; istemci yayınlanmadan kilitlenemez. Öneri: sıkı biçim doğrulaması (ISBN-13 rakam, kısa kimlik) ve taze kaydı ezmeme.
3. `submit_user_trbook` canlıda **yoktu** (mobilde "Türkçe kitap ekle" çalışmıyordu); yukarıda uygulandı.
4. Uzak migration geçmişi boş: ileride `db push` kullanılacaksa önce `supabase migration repair --status applied <sürüm>` ile uygulananlar işaretlenmeli.

## Elle yapmanız gerekenler
1. **Google Cloud Console → API anahtarı kısıtı:** `GOOGLE_BOOKS_API_KEY` yalnızca "Books API" ile sınırlansın ve günlük kota konsun. (Fonksiyon artık dar ama anahtar başka yerden sızarsa kısıt son savunmadır. Anahtar hata mesajıyla sızmış olabileceği için, önceki sürüm canlıyken bir kez **anahtarı yenilemeyi** düşünün.)
2. **Canlıda** `rls_audit_prod.sql`'i çalıştırıp çıktıyı bu belgedeki "bilerek açık olanlar"la karşılaştırın; özellikle `unmanaged_object` satırları.
3. **Cron:** `warm-genre-cache` ve `scrape-tr-books` artık servis anahtarı ister. Cron işleri Vault'taki `service_role_key` ile gönderiyor; bu değer fonksiyonun `SUPABASE_SERVICE_ROLE_KEY` ortamına **eşit değilse** (örn. Vault'ta yeni `sb_secret_...`, ortamda eski JWT) cron sessizce 401 alır. O durumda fonksiyonlara `CRON_SECRET` secret'ı ekleyip Vault'taki değerle aynı yapın. Dağıtımdan sonra bir kez elle tetikleyip (`curl -H "Authorization: Bearer <key>"`) doğrulayın.

## Geriye dönük uyumluluk
Tüm migration değişiklikleri yayındaki uygulamalarla uyumlu (istemcinin okuduğu/yazdığı hiçbir şeyi kaldırmıyor); bu `rls_hardening_pglite.mjs`'te "uygulamanın kullandıkları çalışıyor" bölümüyle doğrulanıyor. Tek istisna bilerek ertelenen önbellek yazma kilidi.

## Genel öneri (henüz yapılmadı)
`alter default privileges in schema public revoke execute on functions from public, anon, authenticated;` — bundan sonra oluşturulan her fonksiyon varsayılan olarak API'ye kapalı olur ve açıkça `grant` gerekir. Bu, #2'deki sınıf hatayı (grant ekleyip revoke unutmak) yapısal olarak engeller; ama gelecekte yazılacak migration'ların davranışını değiştirdiği için ayrıca karar verilmeli.
