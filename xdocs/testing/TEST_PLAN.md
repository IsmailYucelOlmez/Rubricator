# Rubricator (bookapp) — Kapsamlı Test Planı ve Flutter Test Rehberi

> Durum (2026-09-21): 6 test dosyası, 28 test, hepsi geçiyor. Entegrasyon testi, mock kütüphanesi, coverage ve CI test adımı yok.
> Bu doküman hem **plan** (ne, nerede, hangi teknolojiyle) hem de **Flutter test öğrenme rehberi**dir.

İçindekiler
1. Hedefler ve ilkeler
2. Test piramidi ve etiketleme
3. Test türleri × teknoloji matrisi (Traditional vs Agentic)
4. Altyapı kurulumu (paketler, klasör yapısı, komutlar)
5. Katman katman: nasıl yazılır (öğretici örneklerle)
6. Feature bazlı test planı
7. Agentic test stratejisi
8. Backend (Supabase) testleri
9. Performans, erişilebilirlik, güvenlik, i18n
10. CI/CD
11. Yol haritası (fazlar)
12. Öğrenme yolu ve kaynaklar

---

## 1. Hedefler ve ilkeler

| Hedef | Ölçüt |
|---|---|
| Regresyonu deploy öncesi yakalamak | CI'da `analyze` + `test` geçmeden deploy yok |
| İş mantığı güvenliği | domain/usecase + utils katmanı **%90+** satır kapsamı |
| Kritik akışlar çalışıyor | 6–8 uçtan uca (E2E) senaryo her release öncesi yeşil |
| AI özelliklerinde kalite düşüşünü görmek | Sabit bir "golden set" üzerinde skor takibi |

İlkeler:
- **Deterministik olan deterministik test edilir** (traditional). **Belirsiz/LLM çıktısı** ve **keşif** işleri agentic test edilir.
- Testler ağa, gerçek Supabase'e, gerçek LLM'e **çıkmaz** (unit/widget). Sadece integration/E2E ve agentic katman gerçek/staging ortamına çıkar.
- Bir hata düzeltilince önce onu yakalayan test yazılır (regression test).
- Testler okunabilir olmalı: `Arrange – Act – Assert`, tek davranış/test.

## 2. Test piramidi ve etiketleme

```
            /\        Agentic keşif + E2E (az, yavaş, pahalı)
           /  \       Integration test (cihaz/emülatör/web)
          /----\      Widget test + Golden (çok, hızlı)
         /------\     Unit test (en çok, en hızlı)
        /________\    Statik analiz (her commit)
```

Hedef dağılım: Unit %60 · Widget/Golden %30 · Integration %8 · E2E/Agentic %2.

Etiketleme (`dart_test.yaml`):
```yaml
tags:
  unit:
  widget:
  golden:
  integration:
  slow:
```
Test dosyasında: `@Tags(['golden'])` (library seviyesinde), çalıştırma: `flutter test --tags golden`, `--exclude-tags slow`.

## 3. Test türleri × teknoloji matrisi

Yaklaşım sütunu: **T** = Traditional (deterministik, kod ile yazılmış), **A** = Agentic (LLM ajanı karar veriyor/üretiyor/değerlendiriyor), **H** = Hibrit.

| # | Test türü | Ne doğrular | Teknoloji / Araç | Yaklaşım | Sıklık |
|---|---|---|---|---|---|
| 1 | Statik analiz | Lint, tip, ölü kod | `flutter analyze`, `flutter_lints`, `dart format --set-exit-if-changed`, `dart_code_metrics` (opsiyonel) | T | Her commit |
| 2 | Unit | Saf Dart mantığı (utils, usecase, mapper, notifier) | `flutter_test`, `test`, `mocktail`, `fake_async` | T | Her commit |
| 3 | Provider/State (Riverpod) | Notifier/AsyncNotifier durum geçişleri | `ProviderContainer` + `overrides`, `mocktail` | T | Her commit |
| 4 | Repository/Data | JSON parse, DTO→entity, hata eşleme, cache | `mocktail`, `http_mock_adapter` (dio), sabit JSON fixture'lar | T | Her commit |
| 5 | Widget | Tek ekran/bileşen davranışı | `flutter_test` (`WidgetTester`), `ProviderScope(overrides)` | T | Her commit |
| 6 | Golden (görsel regresyon) | Piksel düzeyi UI değişimi | `flutter_test` `matchesGoldenFile`, `alchemist` (platformdan bağımsız golden) | T | PR |
| 7 | Navigasyon/Route | Yönlendirme, deep link, guard | Widget test + `Navigator`/router mock | T | PR |
| 8 | i18n/Lokalizasyon | TR/EN anahtar eşitliği, taşma, plural | Script (arb karşılaştırma) + widget test (iki locale) | T | PR |
| 9 | Integration | Gerçek uygulama, gerçek cihaz/tarayıcı, sahte backend | `integration_test` (SDK), `patrol` (native izin/bildirim diyalogları) | T | PR/Gece |
| 10 | E2E (staging) | Uçtan uca kritik yolculuk | `integration_test` + Supabase **staging** projesi | T | Gece/Release |
| 11 | Backend/DB | Migration, RLS, RPC, Edge Function | `supabase test db` (pgTAP), `supabase functions` için Deno test | T | PR |
| 12 | Sözleşme (contract) | Google Books / RAG API cevap şeması | JSON schema doğrulama testi, kaydedilmiş fixture + haftalık canlı "smoke" | H | Haftalık |
| 13 | Performans | Kare süresi, açılış, liste kaydırma | `integration_test` + `traceAction`/`IntegrationTestWidgetsFlutterBinding.watchPerformance`, Flutter DevTools | T | Release |
| 14 | Erişilebilirlik | Semantics, kontrast, dokunma hedefi | `meetsGuideline(androidTapTargetGuideline, labeledTapTargetGuideline, textContrastGuideline)` | T | PR |
| 15 | Güvenlik | Gizli anahtar sızıntısı, bağımlılık açığı, RLS | `gitleaks`, `dart pub outdated`/`osv-scanner`, RLS pgTAP testleri | T | PR |
| 16 | AI çıktı kalitesi (RAG, virgil, semantic discovery, document_chat) | Doğruluk, dayanaklılık, dil, halüsinasyon | Golden set + **LLM-as-judge** (Claude API), `promptfoo` veya kendi Dart/Python script'i | **A** | Haftalık / prompt değişince |
| 17 | Keşifsel (exploratory) UI testi | Beklenmeyen bozuklukları bulma | Claude + tarayıcı (Claude in Chrome / Browser pane) ile web build üzerinde gezinme | **A** | Release öncesi |
| 18 | Test üretimi / bakımı | Eksik testleri yazma, kırılanı onarma | Claude Code (`/code-review`, alt ajanlar), Dart & Flutter MCP server (`dart mcp-server`: `run_tests`, widget tree) | **A** | Sürekli |
| 19 | Fuzz/Property | Çok girdili saf fonksiyonlar (arama normalizasyonu, ISBN) | `glados` veya `kiri_check` (property-based) | T | PR |
| 20 | Mutasyon testi (test kalitesi) | Testler gerçekten hata yakalıyor mu | `mutation_test` paketi | T | Aylık |
| 21 | Görsel LLM incelemesi | Ekran görüntüsünde bariz UI hatası | Golden/ekran görüntüleri → Claude vision ile "bozuk mu?" | **A** | Release |
| 22 | Manuel + beta | Cihaz çeşitliliği, gerçek kullanıcı hissi | Firebase App Distribution / TestFlight / Play Internal | – | Release |

Karar kuralı: *"Beklenen sonuç tek ve tam biliniyor mu?"* → Evet: **Traditional**. Hayır (serbest metin, öneri, "iyi görünüyor mu?") → **Agentic/LLM-judge**.

## 4. Altyapı kurulumu

### 4.1 Paketler (`pubspec.yaml` → `dev_dependencies`)
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mocktail: ^1.0.4
  fake_async: ^1.3.1
  http_mock_adapter: ^0.6.1     # dio için
  alchemist: ^0.10.0            # golden
  patrol: ^3.0.0                # native etkileşim (opsiyonel, faz 3)
  glados: ^1.1.0                # property-based (opsiyonel)
  mutation_test: ^1.9.0         # opsiyonel
```
(Sürümleri `flutter pub add --dev <paket>` ile güncel al.)

### 4.2 Klasör yapısı (lib'i yansıtır)
```
test/
  helpers/
    pump_app.dart            # ProviderScope + MaterialApp + l10n + tema sarmalayıcı
    fakes.dart               # elle yazılmış Fake repository'ler
    mocks.dart               # mocktail Mock sınıfları
    fixtures/                # JSON: google_books_*.json, rag_*.json ...
    test_data.dart           # Book(), UserList() builder'ları
  core/                      # validation, utils, errors, network
  features/<feature>/
    data/ domain/ presentation/
  goldens/                   # *.png (git'e commit edilir)
  i18n/arb_parity_test.dart
integration_test/
  app_test.dart
  flows/  (auth_flow, search_and_add_flow, list_flow, notes_flow, habit_flow)
  robots/ (robot pattern: LoginRobot, SearchRobot ...)
evals/                       # AI kalite değerlendirme
  golden_set/*.jsonl
  judge_prompt.md
  run_evals.py|dart
supabase/tests/              # pgTAP .sql
```

### 4.3 Komutlar
```bash
flutter test                                   # hepsi
flutter test test/features/books               # klasör
flutter test --name "Turkish fold"             # isme göre
flutter test --tags unit --exclude-tags golden
flutter test --coverage                        # coverage/lcov.info
flutter test --update-goldens                  # golden'ları yenile (bilinçli!)
flutter test integration_test -d chrome        # web (chromedriver gerekir: flutter drive)
flutter test integration_test -d <emulator-id>
supabase test db                               # pgTAP
```
Coverage HTML: `genhtml coverage/lcov.info -o coverage/html` (lcov gerekir).

## 5. Katman katman: nasıl yazılır

### 5.1 Unit test
Saf fonksiyon/sınıf, Flutter gerektirmez. Örnek (projede zaten var: `google_books_utils_test.dart`).
```dart
test('İstanbul ile istanbul eşit sayılır', () {
  expect(textSimilarity('İstanbul', 'istanbul'), 1.0);
});
```
Kural: girdi tablosu (table-driven) kullan:
```dart
for (final c in [('ISBN-10', '0-306-40615-2'), ('ISBN-13', '9780306406157')]) {
  test('isbn: ${c.$1}', () => expect(buildPlainSearchQuery(c.$2), startsWith('isbn:')));
}
```

### 5.2 Mocking (mocktail)
```dart
class MockTrbooksRepository extends Mock implements TrbooksRepository {}

setUp(() => repo = MockTrbooksRepository());

test('başarısız kayıt hata fırlatır', () {
  when(() => repo.submit(any())).thenThrow(TrbookSubmissionException('dup'));
  expect(() => useCase(book), throwsA(isA<TrbookSubmissionException>()));
  verify(() => repo.submit(book)).called(1);
});
```
`registerFallbackValue(FakeBook());` `any()` için gerekir.
Mock mu Fake mi? **Fake**: basit, durumlu, tekrar kullanılabilir (örn. `InMemoryListsRepository` zaten var → Fake olarak kullan). **Mock**: çağrı doğrulaması ve tek seferlik davranış.

### 5.3 Riverpod testi
```dart
final container = ProviderContainer(overrides: [
  booksRepositoryProvider.overrideWithValue(FakeBooksRepository()),
]);
addTearDown(container.dispose);

final sub = container.listen(searchNotifierProvider, (_, __) {});
await container.read(searchNotifierProvider.notifier).search('dune');
expect(container.read(searchNotifierProvider).results, isNotEmpty);
```
Debounce/zamanlayıcı için `fakeAsync((async) { ...; async.elapse(const Duration(milliseconds: 400)); })`.

### 5.4 Widget test — `pumpApp` yardımcısı
```dart
extension PumpApp on WidgetTester {
  Future<void> pumpApp(Widget child, {List<Override> overrides = const [], Locale locale = const Locale('tr')}) =>
    pumpWidget(ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    ));
}
```
Temel API'ler: `find.text/byType/byKey/bySemanticsLabel`, `tester.tap`, `enterText`, `pump()` (tek kare), `pump(duration)`, `pumpAndSettle()` (animasyon bitene kadar; sonsuz animasyonda takılır → `pump` kullan), `expect(find..., findsOneWidget)`.
Kural: Widget'ları `Key('search_field')` gibi anlamlı key'lerle işaretle; metne bağımlı bulma i18n'de kırılır.

### 5.5 Golden test
```dart
goldenTest('BookCard', fileName: 'book_card',
  builder: () => GoldenTestGroup(children: [
    GoldenTestScenario(name: 'tr', child: BookCard(book: testBook)),
    GoldenTestScenario(name: 'uzun başlık', child: BookCard(book: longTitleBook)),
  ]));
```
Kurallar: sabit font (Ahem/`alchemist` varsayılanı), ağ görselleri yerine yerel fixture, golden'lar CI'da **aynı OS**'ta üretilir (Linux). Yalnızca kararlı bileşenlere golden ekle.

### 5.6 Dio / ağ katmanı
```dart
final dio = Dio(); final adapter = DioAdapter(dio: dio);
adapter.onGet('/volumes', (s) => s.reply(200, jsonDecode(fixture('google_books_dune.json'))));
```
Test edilecekler: 200 parse, boş sonuç, 429/5xx → beklenen hata tipi, timeout, bozuk JSON, eksik alan (null-safety).

### 5.7 Integration test + Robot pattern
```dart
// integration_test/flows/search_and_add_flow_test.dart
IntegrationTestWidgetsFlutterBinding.ensureInitialized();
testWidgets('ara → detay → listeye ekle', (tester) async {
  await app.main(); await tester.pumpAndSettle();
  final r = SearchRobot(tester);
  await r.open(); await r.search('Dune'); await r.openFirstResult();
  await BookDetailRobot(tester).addToList('Okunacaklar');
  expect(find.text('Okunacaklar'), findsWidgets);
});
```
Robot = sayfa başına "kullanıcı eylemleri" sınıfı; selector'lar tek yerde toplanır, testler okunur kalır.
Backend: Supabase'e **staging** projesi veya `supabase start` (yerel Docker) — `env.development.json` ile ayrı `--dart-define-from-file`.
Native izin/bildirim (`flutter_local_notifications`, `image_picker`, `file_picker`) için `patrol`.

### 5.8 Test edilebilirlik için kodda yapılacaklar
- Bağımlılıkları provider ile ver (zaten Riverpod var) → `overrides` ile değiştirilebilir.
- `DateTime.now()`, `Random`, `Supabase.instance` doğrudan çağrılmasın; provider/`Clock` arkasına al.
- `main.dart` başlangıç kodunu (Sentry, dotenv, Supabase init) `bootstrap()` fonksiyonuna ayır; testte sahte ile çalıştır.

## 6. Feature bazlı test planı

Öncelik: **P0** kritik/para-veri-kayıp riski · **P1** çekirdek kullanım · **P2** yardımcı.
Tür: U=unit, P=provider, W=widget, G=golden, I=integration, A=agentic.

| Feature | Öncelik | Mevcut | Planlanan testler |
|---|---|---|---|
| **core/validation, utils, errors** | P0 | – | U: tüm validator'lar (sınır değerleri, Türkçe karakter), hata→mesaj eşleme, network hata sınıflandırma; Property: normalizasyon idempotent |
| **core/network** (dio, connectivity) | P0 | – | U/Data: interceptor'lar, retry, timeout, offline davranışı |
| **core/i18n** | P1 | – | Script: `app_tr.arb` ↔ `app_en.arb` anahtar/placeholder eşitliği; W: iki locale'de taşma yok |
| **auth** | P0 | – | P: giriş/çıkış/oturum yenileme durumları; W: form doğrulama, hata mesajı; I: kayıt→giriş→çıkış; RLS: yetkisiz erişim reddi |
| **books** (Google Books, detay, resolve) | P0 | utils (17 test) | Data: repository + fixture (parse, dedupe, cache key); P: resolve provider'ları; W: detay sayfası (yükleme/hata/boş); G: kart & detay; Contract: Google Books şema |
| **search** | P0 | – | P: `search_notifier` (debounce, iptal, hata, boş sorgu, ISBN); W: sonuç listesi, geçmiş, boş durum; I: arama→detay |
| **home** | P1 | – | Data: `home_book_model` parse, scraping çıktısı fixture; P: home providers; W: bölümler, pull-to-refresh, hata; G: ana sayfa |
| **lists** (sosyal listeler) | P0 | 2 widget testi | Data: in-memory vs supabase repo eşdeğerlik testi (aynı kontrat testi iki implementasyona); P; W: oluştur/düzenle/sil, sıralama; I: liste akışı; RLS: başkasının özel listesi okunamaz |
| **user_books / favorites** | P0 | – | U/P: durum geçişleri (okunacak→okunuyor→bitti), puan 1–10 sınırı (migration: 10'a genişletildi); W; I |
| **book_notes** | P1 | – | P/W: not ekle/düzenle/sil; boş/uzun metin; I |
| **habit / profile_stats** | P1 | – | U: seri (streak) hesabı, tarih sınırları, saat dilimi (`fake_async`/sabit clock); P; W; Property: streak invariantları |
| **profile** | P2 | – | W: fotoğraf seçimi (mock `image_picker`), kimlik senkronu; storage RLS |
| **trbooks** (kullanıcı katkılı TR kitap) | P0 | usecase + repo (2 dosya) | Mevcut testleri genişlet: tüm `TrbooksSubmissionException` dalları, açıklama repo, SQL script'leri; W: gönderim formu; pgTAP: migration `user_submitted` RLS |
| **ai / virgil / document_chat / semantic_discovery** | P0 (maliyet+güven) | – | U/Data: istek gövdesi, dil parametresi (`rag api language option`), akış (stream) parse, hata/timeout/rate-limit; W: sohbet UI durumları; **A: eval seti + LLM-judge (bkz. 7.2)** |
| **notification / background** | P1 | – | U: zamanlama hesabı (timezone); Patrol: izin diyaloğu, bildirim gösterimi (Android/iOS) |
| **navigation** | P1 | – | W: rota tablosu, geri tuşu, deep link, auth guard |
| **app.dart / main.dart** | P1 | 1 duman testi | Duman testini bootstrap+sahte provider'larla güçlendir |

## 7. Agentic test stratejisi

### 7.1 Neden ve nerede?
Traditional testler "bildiğimiz" hataları yakalar. Agentic testler (a) **bilinmeyen** UI/akış hatalarını arar, (b) **LLM çıktısı** gibi tek doğru cevabı olmayan şeyi değerlendirir, (c) **test yazma/bakım** yükünü azaltır.

| Amaç | Araç | Nasıl |
|---|---|---|
| Keşifsel UI gezinmesi | Claude + Claude in Chrome / Claude Browser pane, `flutter build web` çıktısı (`gh-pages` zaten var) | Ajana "yeni kullanıcı gibi kaydol, kitap ara, liste oluştur, hataları ve tuhaflıkları raporla" görevi + checklist. Çıktı: bulgu listesi + ekran görüntüleri. **Yalnızca staging/test hesabıyla**, prod'da değil |
| Görsel inceleme | Ekran görüntüsü → Claude vision | Golden'lar geçse bile "kırpılmış metin, çakışma, kontrast" gibi anlamsal sorunları yakalar |
| Test üretimi | Claude Code + Dart/Flutter MCP (`dart mcp-server`) | Bir dosyayı ver → `run_tests` ile döngüde test yaz/koş/düzelt. Çıktı mutlaka insan review'ından geçer; yeşil olsa da **anlamlı assert** var mı kontrol et |
| Kırık test onarımı | Claude Code | CI log'unu ver; ajan kök nedeni bulur. Golden'ı körlemesine `--update-goldens` ile geçirmeyi **yasakla** |
| PR incelemesi | `/code-review` | Değişen kodda hangi testin eksik olduğunu listeletme |
| AI özellik kalitesi | LLM-as-judge | Bkz. 7.2 |

### 7.2 AI özellikleri için eval hattı (`evals/`)
1. **Golden set**: 50–100 örnek (`jsonl`): `{id, feature, locale, input, context, must_include[], must_not_include[], reference}`. TR ve EN karışık; zor durumlar (yanlış yazım, çok kısa sorgu, alakasız soru, prompt-injection denemesi, kitapta olmayan bilgi).
2. **Çalıştırıcı**: Uygulamanın gerçek RAG/AI endpoint'ini (staging) çağırır, cevapları kaydeder.
3. **Kural tabanlı (Traditional) kontroller önce**: dil doğru mu (TR sorusuna TR cevap), JSON şeması, uzunluk, `must_include` anahtar kelimeler, kaynak/atıf var mı.
4. **LLM-judge (Agentic)**: Rubrik ile puanlar — *dayanaklılık (context'te var mı), doğruluk, yardımcılık, dil/ton, güvenlik*. Judge ayrı, sabit sürümlü bir model; temperature 0; yapılandırılmış JSON çıktı; rubrik `judge_prompt.md`'de sürümlenir. Judge'ı kalibre et: elle etiketlenmiş 20 örnekle uyum ölç.
5. **Eşik ve trend**: Skor düşüşü (örn. ortalama −%5) → CI uyarısı. Prompt/model değişince zorunlu koş. Sonuçlar `evals/results/<tarih>.json`.
6. **Güvenlik seti**: Prompt injection, kişisel veri sızdırma, sistem promptunu ifşa denemeleri — bunlar `must_not_include` ile **deterministik** kontrol edilir.
7. Maliyet: eval'ler PR'da değil, gece/haftalık ve prompt değişiminde koşar.

### 7.3 Agentic testin sınırları (öğretici not)
- Deterministik değildir → **kapı (gate) olarak kullanma**, bulgu üretici olarak kullan; bulguyu sonra Traditional teste çevir (regression).
- Prod verisine/gerçek hesaplara dokunma. Sadece test hesabı ve staging.
- Ajanın ürettiği testler de kodtur: review, mutation testi ile kalite kontrolü.

## 8. Backend (Supabase) testleri
- **pgTAP** (`supabase/tests/*.sql`, `supabase test db`): her tabloda RLS — sahibi okur/yazar, başkası okuyamaz, anon erişimi; `list_top_engagement_rpc` sonuçları; `expand_ratings_scale_to_10` migration'ında eski veriler bozulmuyor; `user_submitted` trbooks kısıtları.
- **Migration testi**: boş DB'ye tüm migration'ları sırayla uygula (`supabase db reset`) → hatasız.
- **Edge Functions** (`supabase/functions`): Deno test (`deno test`), dış API'ler mock'lu; girdi doğrulama, yetkilendirme, hata kodları.
- **Sözleşme**: Uygulama DTO'ları ↔ DB/RPC kolonları; kolon adı değişince kırılan test.

## 9. Performans, erişilebilirlik, güvenlik, i18n
- **Performans**: Uzun listeler (arama sonuçları, liste feed'i) için `traceAction` ile kare süresi; hedef 95. yüzdelik < 16 ms (60 fps), soğuk açılış < 3 sn (orta segment cihaz). Bellek sızıntısı: `leak_tracker` (Flutter testlerinde `LeakTesting` ile).
- **Erişilebilirlik**: Ana ekranlarda `meetsGuideline` 4 kural; `Semantics` etiketleri; 200% yazı ölçeği ile taşma testi.
- **i18n**: `arb` eşitlik scripti (anahtar + placeholder), TR/EN ile her ana ekran widget testi, uzun Türkçe kelimelerde taşma (golden senaryosu).
- **Güvenlik**: `gitleaks` (env dosyaları — `env.*.json` repo'da; gizli anahtar içermediğini doğrula), `osv-scanner`/`dart pub outdated`, Sentry'ye PII gitmiyor testi (beforeSend filtresi unit test), WebView/URL launcher whitelist.

## 10. CI/CD (GitHub Actions)
Yeni `ci.yml` (PR + push) ve mevcut `deploy-gh-pages.yml`'e bağımlılık:
```yaml
name: ci
on: [pull_request, push]
jobs:
  static:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { channel: stable, cache: true }
      - run: flutter pub get
      - run: dart format --output=none --set-exit-if-changed .
      - run: flutter analyze
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { channel: stable, cache: true }
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v4   # veya coverage eşiği script'i
  db:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: supabase/setup-cli@v1
      - run: supabase start && supabase test db
  integration-web:      # gece / release
    if: github.event_name == 'schedule'
    ...
```
- `deploy-gh-pages.yml` → `needs: [static, test]` (veya deploy job'unun başına `flutter analyze && flutter test` ekle).
- Kapı: coverage eşiği kademeli (%30 → %50 → %70), yeni kod için diff-coverage %80.
- Gece (`schedule`): integration + E2E + AI eval; sonuçları artifact olarak sakla.
- Branch koruması: `dev`/`main`'e merge için `static` + `test` zorunlu.

## 11. Yol haritası

| Faz | Süre | İçerik | Çıkış kriteri |
|---|---|---|---|
| 0 | 1 gün | `mocktail`, `integration_test`, `test/helpers/pump_app.dart`, `dart_test.yaml`, CI'da analyze+test | CI yeşil, deploy test'e bağlı |
| 1 | 1–2 hf | core + books + search + trbooks unit/provider testleri; `arb` eşitlik scripti | Domain/utils kapsamı %70+ |
| 2 | 2 hf | Widget testleri (search, home, lists, book detail, auth formu) + ilk golden'lar (`alchemist`) | Ana ekranlar iki locale'de testli |
| 3 | 1–2 hf | pgTAP RLS/migration testleri; sözleşme fixture'ları | Tüm tablolarda RLS testi |
| 4 | 2 hf | `integration_test` + robot pattern: 6–8 kritik akış; web + Android emülatör gece koşusu | Gece CI yeşil |
| 5 | 2 hf | AI eval hattı (golden set, kural + LLM-judge), güvenlik seti | Skor baz çizgisi kaydedildi |
| 6 | Sürekli | Agentic keşif oturumları (release öncesi), a11y/performans, mutation testi, patrol | Release checklist'ine bağlı |

Release öncesi checklist: CI yeşil · gece E2E yeşil · eval skoru düşmedi · agentic keşif raporundaki P0/P1 bulgular kapandı · 2 fiziksel cihazda manuel duman testi.

## 12. Öğrenme yolu (Flutter testi öğrenmek isteyen biri için)

Bu repoda sırayla:
1. **Unit**: `test/features/books/data/utils/google_books_utils_test.dart` — `group/test/expect`, table-driven.
2. **Mock/UseCase**: `test/features/trbooks/domain/usecases/trbooks_usecases_test.dart` — bağımlılık enjeksiyonu, istisna testi.
3. **Widget**: `test/features/lists/presentation/pages/lists_feed_page_search_test.dart` — `pumpWidget`, `find`, `tap`, `pump`.
4. **Daha karmaşık widget**: `list_search_page_test.dart` (219 satır) — sahte repository + arama akışı.
5. Sonra bu plandaki Faz 1 görevlerinden birini al (örn. `search_notifier` testi) ve PR aç.

Kavram sözlüğü: **Unit** (tek fonksiyon/sınıf) · **Widget test** (sanal ekranda widget ağacı, cihaz yok) · **Integration** (gerçek uygulama, cihaz/tarayıcı) · **Golden** (referans görüntü karşılaştırma) · **Mock/Fake/Stub** (sahte bağımlılık türleri) · **Pump** (Flutter'a "kare çiz" demek) · **Robot pattern** · **LLM-as-judge** · **Flaky** (bazen geçen, bazen kalan test — bulunca hemen karantinaya al ve düzelt).

Kaynaklar: docs.flutter.dev/testing (overview, unit, widget, integration, golden, performance) · pub.dev: `mocktail`, `alchemist`, `patrol`, `http_mock_adapter`, `glados` · Riverpod dokümantasyonu "Testing" bölümü · supabase.com/docs/guides/local-development/testing/overview (pgTAP) · Andrea Bizzotto'nun Riverpod/Flutter test yazıları (codewithandrea.com).

## Ekler

### A. Anti-pattern listesi
- `pumpAndSettle()`'ı her yerde kullanmak (sonsuz animasyonda timeout).
- Gerçek ağ/DB çağrısı yapan unit/widget test.
- Sadece "çökmedi" diyen (assert'siz) testler.
- Golden'ı sebepsiz `--update-goldens` ile yenilemek.
- Test arası paylaşılan durum (`setUp` yerine global değişken).
- Implementasyon detayını test etmek (private metot, çağrı sırası) — davranışı test et.

### B. Kontrat testi örneği (in-memory ↔ Supabase repo)
Aynı test paketini iki implementasyona uygula; ikisi de aynı davranışı vermeli:
```dart
void listsRepositoryContract(String name, ListsRepository Function() create) {
  group('ListsRepository contract — $name', () {
    test('oluşturulan liste getirilir', () async { ... });
    test('silinen liste döndürülmez', () async { ... });
  });
}
void main() {
  listsRepositoryContract('in-memory', InMemoryListsRepository.new);
  // supabase: integration katmanında yerel Supabase ile
}
```
