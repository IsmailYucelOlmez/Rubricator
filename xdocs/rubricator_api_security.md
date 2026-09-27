# rubricatorApi güvenliği ve dağıtım runbook'u

`supabase/functions/rubricatorApi` FastAPI (Gemini) için bir vekildir ve sunucudaki gizli anahtarı isteğe ekler. Eskiden kimlik doğrulaması, kota ve yol kısıtı yoktu (`verify_jwt = false`, CORS `*`); günlük kota yalnızca istemcide uygulanıyordu ve herkes API'yi doğrudan çağırıp atlayabiliyordu.

## Şimdi ne yapıyor
Her istek sırayla: (1) izinli **yol + metot** listesinde mi (`handler.ts` → `ROUTES`; başka her şey 404/405, sorgu dizesi iletilmez), (2) izinli **tarayıcı origin**'i mi (Origin başlığı olmayan mobil istemciler etkilenmez), (3) geçerli bir **Supabase kullanıcı JWT**'si taşıyor mu, (4) **gövde boyutu** sınırı içinde mi (arama/sohbet 16 KB, yükleme 25 MB), (5) maliyetli rotalarda **günlük kotayı sunucuda** düşüyor mu.

| Rota | Kota |
|---|---|
| `POST /api/v1/semantic/search` | öneri kotası (5/gün) — aynı sorgu için 30 dk'lık **bilet**: ilk çağrı 1 hak düşer, aynı sorgunun sonraki 9 çağrısı (tür filtresi vb.) ücretsiz |
| `POST /api/v1/sessions` (belge yükleme) | yükleme kotası (3/gün) |
| `POST /api/v1/trbooks/generate-description` | Türkçe kitap açıklaması kotası (10/gün) |
| `GET/DELETE /api/v1/sessions/{id}`, `POST .../chat` | yok (yalnızca kimlik; sohbet sınırı FastAPI'de) |

Kota veritabanında: `authorize_virgil_action(uid, action, query_hash)` (yalnızca `service_role`). Sorgu metni saklanmaz, yalnızca normalize edilmiş sorgunun SHA-256'sı. Limitler tek yerde: `virgil_usage_limit()`.

## Başarısız çağrıların iadesi ve zaman aşımı
Kota çağrıdan önce düşülür; üst akış **5xx / 429** dönerse ya da bağlantı hatası / zaman aşımı olursa Edge Function harcananı geri verir (`refund_virgil_action`). Ne harcandığı `authorize_virgil_action_ex` ile bilinir: `unit` (günlük hak) ya da `ticket` (açık bilet çağrısı). Bir `unit` iadesi aramanın biletini de siler, yeniden deneme yeniden öder (başarısız çağrının ödeyeceği gibi). 4xx iade edilmez (istemci hatası). İade hatası yanıtı değiştirmez, `quota_refund_failed` olarak loglanır.

Rota bazlı üst akış zaman aşımı, uygulamanın kendi HTTP zaman aşımının **altında**: arama ve açıklama 25 sn (uygulama 30 sn bekler), belge yükleme 55 sn, sohbet 80 sn (uygulama 90 sn), oturum okuma/silme 30 sn. Böylece kullanıcı vazgeçtikten sonra tamamlanan çağrı sessizce hak yakmaz; 504 + iade olur.

## Kullanıcı kimliğinin API'ye iletilmesi
FastAPI'ye gelen her istek Edge Function'ın çıkış IP'sinden gelir; IP'ye dayalı sınır (`DOCUMENT_MAX_SESSIONS_PER_IP_HOUR`) bu yüzden **tüm kullanıcıların paylaştığı tek bir kovaya** dönüşüyordu. Edge Function artık doğruladığı kullanıcının id'sini `X-User-Id` başlığıyla iletir (istemcinin kendi gönderdiği bu başlık asla iletilmez). API (`bookapp-api`, `app/api/routers/sessions.py`) belge oturumu sınırını bu id'ye göre uygular (`DOCUMENT_MAX_SESSIONS_PER_USER_HOUR`, varsayılan 10); başlık yoksa ya da UUID biçiminde değilse IP kovasına geri döner. Güven, API anahtarına dayanır: anahtarı yalnızca Edge Function bilir.

Sıra fark etmez: eski API başlığı yok sayıp IP'ye düşer, yeni API başlık gelmezse IP'ye düşer. Yine de önce API'yi, sonra fonksiyonu dağıtın.

## Eski uygulama sürümleriyle uyumluluk
Yayındaki uygulamalar çağrıdan önce `try_consume_virgil_usage` RPC'sini çağırıyor. Bu RPC artık **yalnızca kontrol eder** (sayacı artırmaz); artırmayı sunucu yapar. Böylece eski sürümler değişmeden çalışır ve çift sayılmaz.

Bilinen eski-istemci sorunu: Dio başlıkları (oturum jetonu dahil) veri kaynağı oluşturulurken **bir kez** hesaplanıyordu; jeton ~1 saat sonra bitiyor ve sunucu 401 döner. Yeni istemci başlıkları **her istekte** tazeliyor (`SupabaseService.edgeFunctionAuthInterceptor`). Kimlik doğrulama iki modda:

- `AUTH_MODE=enforce` (**varsayılan**): geçerli JWT'si olmayan istek 401.
- `AUTH_MODE=monitor` (geçici, isteğe bağlı secret): geçerli JWT'si olmayan istek eskisi gibi iletilir (kota yok) ve `unauthenticated_request_allowed` olarak loglanır. Yalnızca eski uygulama sürümlerinin 1 saat sonraki 401'lerini tolere etmek için; kapıyı kapatmaz. Yol/origin/boyut kuralları her iki modda da geçerlidir.

> **Not:** Varsayılan `enforce` olduğu için yeni istemci yayınlanmadan dağıtılırsa, eski sürümlerde uygulamayı 1 saatten uzun açık tutan kullanıcılar Virgil/belge sohbetinde hata alabilir (yeniden başlatınca düzelir). Bunu tolere etmiyorsanız önce `AUTH_MODE=monitor` secret'ını ekleyin, yeni sürüm yayılınca silin.

## Dağıtım sırası
Bu tur birden fazla bileşeni etkiliyor; sıra önemli:
1. **API** (`bookapp-api`): önce dağıtın. `X-User-Id` ile hesap bazlı sınır, yükleme boyutu ara katmanı. Eski/yeni fark etmeksizin geriye dönük uyumlu.
2. **Migration'lar, sırayla:** `20260925000000_virgil_server_side_quota.sql`, `20260926000000_rls_hardening.sql`, `20260926000001_virgil_quota_refund_and_trbooks.sql` (`supabase db push` ya da SQL editör; dosyaları sırayla yapıştırın). İlkinden itibaren istemci RPC'si sayaç artırmaz.
3. **Hemen ardından fonksiyonlar:** `rubricatorApi`, `google-books`, `scrape-tr-books`, `warm-genre-cache`. Migration ile `rubricatorApi` arasındaki boşlukta kota geçici olarak düşülmez; art arda yapın. Tersi sıra (fonksiyon önce), `authorize_virgil_action_ex` bulunamayıp `503` verdiği için Virgil'i keser.
   - CLI: `supabase functions deploy <ad>`.
   - Dashboard (yalnızca `index.ts` yükler, yan/paylaşılan dosyaları paketlemez): `deno run --allow-read --allow-write supabase/tools/single_file.ts <ad>` ile `supabase/functions/<ad>/index.single.ts` üretin, içeriğini editöre yapıştırın. **"Verify JWT" kapalı kalmalı** (dashboard `config.toml`'u okumaz).
4. Secret'lar (gerekirse): `ALLOWED_ORIGINS` (virgülle; GitHub Pages ve `localhost` her zaman izinli), geçici `AUTH_MODE=monitor`, `CRON_SECRET` (bkz. [rls_audit.md](rls_audit.md), "Cron").
5. Mobil uygulamanın yeni sürümünü yayınlayın (başlık tazeleme, önbellek yazımı en iyi çaba).
6. Yeni sürüm yayılınca [`supabase/deferred/cache_write_lockdown.sql`](../supabase/deferred/cache_write_lockdown.sql).
7. Web'de canlı alan adı belli olunca `ALLOWED_ORIGINS`'e ekleyin.

## Elle duman testi (dağıtımdan sonra)
```bash
URL=https://<proje>.supabase.co/functions/v1/rubricatorApi
# 1) izinli olmayan yol -> 404
curl -s -o /dev/null -w "%{http_code}\n" -H "apikey: <publishable>" $URL/api/v1/admin
# 2) JWT'siz arama: enforce'ta (varsayılan) 401, monitor'de 200
curl -s -w "\n%{http_code}\n" -H "apikey: <publishable>" -H "Content-Type: application/json" \
  -d '{"query":"karanlık fantazi"}' $URL/api/v1/semantic/search
# 3) yabancı origin -> 403
curl -s -o /dev/null -w "%{http_code}\n" -H "Origin: https://evil.example" $URL/api/v1/sessions/abc
```
JWT'li kota doğrulaması için giriş yapmış bir kullanıcının access token'ıyla 6. farklı sorgu `429 {"error":"daily_limit_reached"}` dönmeli.

## Testler
- Edge Function'lar: `cd supabase/functions && deno test --allow-read rubricatorApi/ google-books/ _shared/` (60 senaryo, ağ gerekmez)
- Kota SQL'i: `node supabase/tests/virgil_quota_pglite.mjs` (66 kontrol, gerçek Postgres motorunda)
- RLS/yetki: `node supabase/tests/rls_hardening_pglite.mjs` (36 kontrol) — önce `npm install --no-save @electric-sql/pglite`
- API: `cd bookapp-api && python -m pytest` (`tests/api/test_sessions_rate_limit.py`, `tests/api/test_upload_limit.py` dahil)

## Bilinen kalanlar
- `google-books` oturum açmamış kullanıcıya da açık olmak zorunda (JWT istenemez); bu yüzden hız sınırı yok. Google anahtarını konsolda kısıtlayın ([rls_audit.md](rls_audit.md)).
- İstemci `429 daily_limit_reached`'i ayrıştırmıyor; yarış durumunda genel hata gösterir.
- Belge oturumları hâlâ sahibine bağlı değil (API artık `X-User-Id`'yi biliyor; bağlamak sonraki adım).
- Önbellek tablolarının yazma kilidi ertelendi ([rls_audit.md](rls_audit.md)).
