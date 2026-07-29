// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Rubricator';

  @override
  String get navHome => 'Ana Sayfa';

  @override
  String get navSearch => 'Ara';

  @override
  String get navVirgil => 'Virgil';

  @override
  String get navLists => 'Listeler';

  @override
  String get virgilTagline => 'Virgil okuma yolculuğuna rehberlik eder';

  @override
  String get virgilRecommendationHint =>
      'Önerilerle bir sonraki favori kitabını bul.';

  @override
  String get virgilRecommendationTitle => 'Recommendation';

  @override
  String get virgilAboutBookTitle => 'About Book';

  @override
  String get virgilAboutBookHint => 'Bir kitap yükle ve hakkında sorular sor';

  @override
  String get virgilBetaBadge => 'BETA';

  @override
  String get virgilRecommendationEmptyBody =>
      'Keşfetmeye değer yeni yazarlar, farklı türler ve ilginizi çekebilecek eserler. Virgil, size öneriler sunarak keşfetmenizi kolaylaştırır.';

  @override
  String get virgilRecommendationInputHint => 'Bir şey yazın...';

  @override
  String get virgilQaInputHint => 'soru sorun';

  @override
  String get virgilQaUploadTitle => 'PDF veya Epub yükleyin';

  @override
  String get virgilQaSizeLimit => '20 MB Limit';

  @override
  String get virgilQaPagesLimit => '500 Sayfa Limit';

  @override
  String get virgilQaPrivacyNotice =>
      'Yüklediğiniz dosyalar ve sohbetleriniz kaydedilmez.';

  @override
  String get virgilQaProcessingTitle => 'Dosya işleniyor...';

  @override
  String get virgilQaProcessingSubtitle => 'Lütfen bekleyin';

  @override
  String virgilQaFileMeta(String filename, String format, int pages) {
    return '$filename | $format | $pages sayfa';
  }

  @override
  String virgilQaFileMetaChapters(
    String filename,
    String format,
    int chapters,
  ) {
    return '$filename | $format | $chapters bölüm';
  }

  @override
  String get virgilGenreLabel => 'Tür';

  @override
  String get virgilGenreAll => 'Tümü';

  @override
  String get virgilGenreFiction => 'Kurgu';

  @override
  String get virgilGenreNonfiction => 'Kurgu dışı';

  @override
  String get virgilGenreChildrensFiction => 'Çocuk kurgusu';

  @override
  String get virgilGenreChildrensNonfiction => 'Çocuk kurgu dışı';

  @override
  String get signInForVirgil =>
      'Virgil önerileri ve kitap soru-cevap için giriş yapın.';

  @override
  String get virgilDailyRecommendationLimit =>
      'Günde en fazla 3 kez kitap önerisi alabilirsiniz. Yarın tekrar deneyin.';

  @override
  String get virgilDailyUploadLimit =>
      'Günde en fazla 3 kitap yükleyebilirsiniz. Yarın tekrar deneyin.';

  @override
  String virgilQuestionsRemaining(int count) {
    return 'Bu kitap için $count soru kaldı';
  }

  @override
  String get listsFeedHeading => 'Listbox';

  @override
  String get profileZoneTitle => 'Zone';

  @override
  String get readingStatsListsTitle => 'Duruma gore okuma listeleri';

  @override
  String get homeShowAll => 'Tümünü gör';

  @override
  String get editProfile => 'Profili düzenle';

  @override
  String get pickPhotoFromGallery => 'Galeriden fotoğraf seç';

  @override
  String get pickProfilePhotoFromGallery => 'Fotoğraf seç';

  @override
  String get changeProfilePhoto => 'Fotoğrafı değiştir';

  @override
  String get removeProfilePhotoTooltip => 'Fotoğrafı kaldır';

  @override
  String get privacyPolicyCheckbox =>
      'Gizlilik politikasını okudum ve kabul ediyorum.';

  @override
  String get displayNameLabel => 'İsim';

  @override
  String get profilePhotoUrlOptional =>
      'Profil fotoğrafı URL\'si (isteğe bağlı)';

  @override
  String get profile => 'Profil';

  @override
  String get language => 'Dil';

  @override
  String get themeAppearance => 'Görünüm';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get notifications => 'Bildirimler';

  @override
  String get selectLanguage => 'Dil Seç';

  @override
  String get english => 'İngilizce';

  @override
  String get turkish => 'Türkçe';

  @override
  String get signInPrompt =>
      'Kütüphanenizi, listelerinizi ve okuma ilerlemenizi tüm cihazlarınızda senkronize etmek için giriş yapın.';

  @override
  String get signIn => 'Giriş yap';

  @override
  String get createAccount => 'Hesap oluştur';

  @override
  String get signedInFallback => 'Giriş yaptınız';

  @override
  String get signOut => 'Çıkış yap';

  @override
  String loadSessionError(Object error) {
    return 'Oturum yüklenemedi. $error';
  }

  @override
  String get invalidEmailOrPassword => 'E-posta veya şifre hatalı.';

  @override
  String get accountAlreadyExists => 'Bu e-posta ile bir hesap zaten var.';

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Şifre';

  @override
  String get passwordMin6 =>
      'Şifre (En az 6 karakter, büyük/küçük harf ve noktalama)';

  @override
  String get cancel => 'İptal';

  @override
  String get signUp => 'Kayıt ol';

  @override
  String get confirmAccountEmailNotice =>
      'Gerekirse hesabınızı doğrulamak için e-postanızı kontrol edin.';

  @override
  String get readingHabit => 'Okuma alışkanlığı';

  @override
  String get readingLoggedToday => 'Harika! Bugün okuma kaydınızı girdiniz.';

  @override
  String get didYouReadToday => 'Bugün okudunuz mu?';

  @override
  String todayStatusError(Object error) {
    return 'Bugünün durumu yüklenemedi. $error';
  }

  @override
  String get quickLog => 'Okumayı kaydet';

  @override
  String get details => 'Detaylar';

  @override
  String get readingStats => 'Okuma istatistikleri';

  @override
  String booksCount(Object count) {
    return '$count kitap';
  }

  @override
  String averageShort(Object avg) {
    return '$avg ort';
  }

  @override
  String get noRatingsYet => 'Henüz puan yok';

  @override
  String topGenre(Object genre) {
    return 'En çok: $genre';
  }

  @override
  String get viewAllStats => 'Tüm istatistikleri gör';

  @override
  String loadStatsError(Object error) {
    return 'İstatistikler yüklenemedi. $error';
  }

  @override
  String get searchBooksTitle => 'Kitap ara';

  @override
  String get searchByTitleOrAuthorHint => 'Başlık veya yazara göre ara…';

  @override
  String noBooksFoundFor(Object query) {
    return '\"$query\" için sonuç bulunamadı. Farklı bir başlık veya yazar deneyin.';
  }

  @override
  String get recentSearches => 'Son Aramalar';

  @override
  String get loadRecentSearchesError => 'Son aramalar yüklenemedi.';

  @override
  String get noRecentSearchesYet => 'Son aramalarınız burada görünecek.';

  @override
  String get recentSearchedBooks => 'Son görüntülenen kitaplar';

  @override
  String get loadRecentSearchedBooksError =>
      'Son görüntülenen kitaplar yüklenemedi.';

  @override
  String get noRecentSearchedBooksYet =>
      'Aradığınız kitaplar burada görünecek.';

  @override
  String get searchBooksMin2Hint => 'Aramak için en az 2 karakter yazın';

  @override
  String get searchTabKeyword => 'Anahtar kelime';

  @override
  String get searchTabSemantic => 'Anlamsal';

  @override
  String get searchTabDocumentChat => 'Kitabımla sor';

  @override
  String get documentChatPickFile => 'PDF veya EPUB seç';

  @override
  String get documentChatUploading => 'Yükleniyor…';

  @override
  String get documentChatProcessing => 'Kitabınız işleniyor…';

  @override
  String documentChatEmbedProgress(int done, int total) {
    return '$done / $total gömülüyor';
  }

  @override
  String get documentChatExtracting => 'Metin çıkarılıyor…';

  @override
  String get documentChatEmptyHint =>
      'İçerik hakkında soru sormak için kitap yükleyin.';

  @override
  String get documentChatSessionExpired =>
      'Oturumunuz sona erdi. Kitabı yeniden yükleyin.';

  @override
  String get documentChatProcessingFailed => 'Bu kitap işlenemedi.';

  @override
  String get documentChatStillProcessing => 'Hâlâ işleniyor — lütfen bekleyin.';

  @override
  String documentChatQuestionsRemaining(int count) {
    return '$count soru kaldı';
  }

  @override
  String get documentChatTruncatedWarning =>
      'Kitabın yalnızca bir bölümü işlendi. Yanıtlar eksik olabilir.';

  @override
  String get documentChatUnsupportedFormat =>
      'Yalnızca PDF ve EPUB desteklenir.';

  @override
  String documentChatFileTooLarge(int mb) {
    return 'Dosya $mb MB sınırını aşıyor.';
  }

  @override
  String get documentChatAskPlaceholder => 'Bu kitap hakkında sorun…';

  @override
  String documentChatSourcePage(int page) {
    return 'Sayfa $page';
  }

  @override
  String get documentChatEphemeralNotice =>
      'Sohbetler geçicidir; hesabınıza kaydedilmez.';

  @override
  String get documentChatSupportedFormats =>
      'Desteklenen: .pdf, .epub (en fazla 20 MB / ~500 PDF sayfası)';

  @override
  String get documentChatNewFile => 'Yeni dosya';

  @override
  String get documentChatPages => 'sayfa';

  @override
  String get documentChatChapters => 'bölüm';

  @override
  String documentChatExpiresIn(int minutes) {
    return '$minutes dk kaldı';
  }

  @override
  String get semanticSearchHint => 'Aradığınız kitabı tarif edin…';

  @override
  String get semanticSearchMinHint =>
      'Aradığınız kitabı tarif edin ve Ara\'ya dokunun';

  @override
  String get semanticFiltersTitle => 'Filtreler';

  @override
  String get semanticCategoryLabel => 'Kategori';

  @override
  String get semanticToneLabel => 'Ton';

  @override
  String get semanticApiNotConfigured => 'Anlamsal keşif yapılandırılmamış.';

  @override
  String get apply => 'Uygula';

  @override
  String get semanticModeSimple => 'Hızlı';

  @override
  String get semanticModeAdvanced => 'Derin';

  @override
  String get semanticModeAdvancedHint =>
      'Sorgunuzu yeniden yazar ve Google Books\'tan yeni kitaplar ekleyebilir';

  @override
  String get discover => 'Keşfet';

  @override
  String get noBooksFound => 'Kitap bulunamadı';

  @override
  String get searchCouldNotComplete =>
      'Arama tamamlanamadı. Lütfen tekrar deneyin.';

  @override
  String get continueReading => 'Okunanlar';

  @override
  String get popular => 'Popüler';

  @override
  String get loadPopularBooksError => 'Popüler kitaplar yüklenemedi.';

  @override
  String loadGenreBooksError(Object genre) {
    return '$genre kitapları yüklenemedi.';
  }

  @override
  String get genreFantasy => 'Fantastik';

  @override
  String get genreScienceFiction => 'Bilim Kurgu';

  @override
  String get genreRomance => 'Romantik';

  @override
  String get genreMystery => 'Gizem';

  @override
  String get genreThriller => 'Gerilim';

  @override
  String get genreHorror => 'Korku';

  @override
  String get loadHomeGenresError =>
      'Tür bölümleri yüklenemedi. Lütfen tekrar deneyin.';

  @override
  String homeGenreEmptySoft(Object genre) {
    return '$genre için henüz öneri yok. Yenilemek için aşağı çekin veya daha sonra tekrar deneyin.';
  }

  @override
  String get toRead => 'Okunacak';

  @override
  String get reading => 'Okunuyor';

  @override
  String get reReading => 'Tekrar Okunuyor';

  @override
  String get completed => 'Tamamlandı';

  @override
  String get dropped => 'Bırakıldı';

  @override
  String get addToFavorites => 'Favorilere ekle';

  @override
  String get removeFromFavorites => 'Favorilerden çıkar';

  @override
  String get favorites => 'Favoriler';

  @override
  String get signInToSeeLists =>
      'Okuma listelerinizi görüntülemek ve yönetmek için giriş yapın.';

  @override
  String noBooksInStatus(Object status) {
    return '$status olarak işaretlenmiş kitap yok.';
  }

  @override
  String get noFavoritesYet =>
      'Favorilere eklediğiniz kitaplar burada görünecek.';

  @override
  String couldNotLoadList(Object error) {
    return 'Liste yüklenemedi. $error';
  }

  @override
  String get bookDetails => 'Kitap Detayı';

  @override
  String get authorProfile => 'Yazar profili';

  @override
  String get ratingSubmitted => 'Puan gönderildi.';

  @override
  String get noDescriptionAvailable => 'Henüz açıklama yok.';

  @override
  String get reviewAdded => 'Yorum eklendi.';

  @override
  String get reviewUpdated => 'Yorum güncellendi.';

  @override
  String get reviewDeleted => 'Yorum silindi.';

  @override
  String get externalReviewAdded => 'Harici yorum eklendi.';

  @override
  String get invalidUrl => 'Geçersiz URL';

  @override
  String get couldNotOpenBrowser => 'Tarayıcı açılamadı.';

  @override
  String get quoteAdded => 'Alıntı eklendi.';

  @override
  String get relatedBooks => 'Benzer kitaplar';

  @override
  String get noRelatedTitlesFound => 'Bu kitap için benzer başlık bulunamadı.';

  @override
  String get couldNotLoadRelatedBooks => 'Benzer kitaplar yüklenemedi.';

  @override
  String get aiSummary => 'YZ Özeti';

  @override
  String get aiSummaryFailed =>
      'Özet oluşturulamadı. Daha sonra tekrar deneyin.';

  @override
  String couldNotLoadThisBook(Object error) {
    return 'Bu kitap yüklenemedi. $error';
  }

  @override
  String get addToList => 'Listeye Ekle';

  @override
  String get change => 'Değiştir';

  @override
  String progressPercent(Object progress) {
    return 'İlerleme: %$progress';
  }

  @override
  String get rating => 'Puan';

  @override
  String averageOutOfFive(Object avg) {
    return 'Ortalama: $avg / 5';
  }

  @override
  String get couldNotLoadRating => 'Puan yüklenemedi.';

  @override
  String get submitRating => 'Puanı gönder';

  @override
  String get reviews => 'Yorumlar';

  @override
  String get userReviews => 'Uygulama Yorumları';

  @override
  String get externalReviews => 'Harici Yorumlar';

  @override
  String get writeReviewHint => 'Düşüncelerinizi paylaşın (en az 10 karakter)';

  @override
  String get addReview => 'Yorum ekle';

  @override
  String get noUserReviewsYet => 'Bu kitap hakkında ilk yorumu siz yazın.';

  @override
  String reviewUserRating(int rating) {
    return 'Puan: $rating/10';
  }

  @override
  String get reviewInFavorites => 'Favorilerde';

  @override
  String get relativeTimeJustNow => 'az önce';

  @override
  String relativeTimeMinutesAgo(int count) {
    return '$count dk. önce';
  }

  @override
  String relativeTimeHoursAgo(int count) {
    return '$count sa. önce';
  }

  @override
  String relativeTimeDaysAgo(int count) {
    return '$count gün önce';
  }

  @override
  String relativeTimeWeeksAgo(int count) {
    return '$count hf. önce';
  }

  @override
  String get couldNotLoadReviews => 'Yorumlar yüklenemedi.';

  @override
  String get reviewTitle => 'Yorum başlığı';

  @override
  String get reviewUrlHint => 'https://example.com/review';

  @override
  String get addExternalReview => 'Harici yorum ekle';

  @override
  String get noExternalReviewsYet => 'Henüz harici yorum yok.';

  @override
  String get couldNotLoadExternalReviews => 'Harici yorumlar yüklenemedi.';

  @override
  String get quotes => 'Alıntılar';

  @override
  String get addMemorableQuote => 'Hatırlamak istediğiniz bir alıntı ekleyin';

  @override
  String get addQuote => 'Alıntı ekle';

  @override
  String get noQuotesYet =>
      'Bu kitaptan kaydettiğiniz alıntılar burada görünecek.';

  @override
  String get couldNotLoadQuotes => 'Alıntılar yüklenemedi.';

  @override
  String get notes => 'Notlar';

  @override
  String get myNotes => 'Notlarım';

  @override
  String get myNotesDescription =>
      'Okuma notlarınızı arayın, filtreleyin ve yönetin.';

  @override
  String get signInToSeeNotes =>
      'Notlarınızı görüntülemek ve yönetmek için giriş yapın.';

  @override
  String get addNote => 'Not ekle';

  @override
  String get editNote => 'Notu düzenle';

  @override
  String get noteTitleHint => 'Not başlığı';

  @override
  String get noteContentHint => 'Notunuzu yazın…';

  @override
  String get notePageHint => 'Sayfa (isteğe bağlı)';

  @override
  String get noteChapterHint => 'Bölüm (isteğe bağlı)';

  @override
  String get noteTagsHint => 'Etiketler (virgülle ayırın)';

  @override
  String get publicNote => 'Herkese açık not';

  @override
  String get publicNoteDescription =>
      'Herkese açık notlar kitabın Notlar sekmesinde herkese görünür.';

  @override
  String get privateNote => 'Özel';

  @override
  String get searchNotesHint => 'Notlarda ara…';

  @override
  String get noPublicNotesYet => 'Henüz herkese açık not yok.';

  @override
  String get noMyNotesYet => 'Henüz not eklemediniz.';

  @override
  String get noteAdded => 'Not eklendi.';

  @override
  String get noteUpdated => 'Not güncellendi.';

  @override
  String get noteDeleted => 'Not silindi.';

  @override
  String get deleteNoteTitle => 'Not silinsin mi?';

  @override
  String get deleteNoteMessage => 'Bu not kalıcı olarak silinecek.';

  @override
  String get allTags => 'Tümü';

  @override
  String notePageLabel(int page) {
    return 'Sayfa $page';
  }

  @override
  String get editReview => 'Yorumu düzenle';

  @override
  String get save => 'Kaydet';

  @override
  String get log => 'Kaydet';

  @override
  String get signInForHabit =>
      'Okumanızı takip etmek, seriler oluşturmak ve aktivite takviminizi görmek için giriş yapın.';

  @override
  String get readingLogged => 'Okuma kaydedildi!';

  @override
  String get readingLoggedOffline =>
      'Çevrimdışı kaydedildi—bağlantı gelince senkronize edilecek.';

  @override
  String get readingLogsSynced => 'Bekleyen okuma kayıtları senkronize edildi';

  @override
  String couldNotSave(Object error) {
    return 'Kaydedilemedi. $error';
  }

  @override
  String get addMinutesOrPagesPrompt =>
      'Bugün okuduğunuz dakika veya sayfa sayısını girin.';

  @override
  String get minutes => 'Dakika';

  @override
  String get plusTenMin => '+10 dk';

  @override
  String get pages => 'Sayfa';

  @override
  String get plusFivePages => '+5 sayfa';

  @override
  String get optionalAddBooksPrompt =>
      'İpucu: burada bağlamak için Okuyorum listenize kitap ekleyin.';

  @override
  String get bookOptional => 'Kitap (isteğe bağlı)';

  @override
  String get book => 'Kitap';

  @override
  String get none => 'Yok';

  @override
  String booksError(Object error) {
    return 'Kitaplar yüklenemedi. $error';
  }

  @override
  String get saveLog => 'Kaydet';

  @override
  String get selectReadingBook => 'Okuyorum listenizden bir kitap seçin';

  @override
  String get noReadingBooksForLog =>
      'Belirli bir kitap için ilerleme kaydetmek üzere Okuyorum listenize kitap ekleyin.';

  @override
  String get selectBooksToLog =>
      'Bugün okuduklarınızı seçin ve her biri için dakika ve/veya sayfa girin.';

  @override
  String get currentlyReadingBooks => 'Şu an okunanlar';

  @override
  String get generalReadingLog => 'Genel okuma';

  @override
  String get generalReadingLogHint =>
      'Belirli bir kitaba bağlamadan okuma süresi kaydedin.';

  @override
  String readingLoggedCount(int count) {
    return '$count okuma kaydi eklendi';
  }

  @override
  String calendarError(Object error) {
    return 'Takvim yüklenemedi. $error';
  }

  @override
  String get activity => 'Aktivite';

  @override
  String lastWeeksMoreReading(int weeks) {
    return 'Son $weeks hafta (daha koyu = daha fazla okuma)';
  }

  @override
  String get noLogsYetTapQuickLog =>
      'Henüz kayıt yok. Başlamak için Okumayı kaydet\'e dokunun.';

  @override
  String get recentLogs => 'Son kayıtlar';

  @override
  String minutesShort(int count) {
    return '$count dk';
  }

  @override
  String pagesShort(int count) {
    return '$count sayfa';
  }

  @override
  String bookIdLabel(Object bookId) {
    return 'Kitap: $bookId';
  }

  @override
  String logsError(Object error) {
    return 'Kayıtlar yüklenemedi. $error';
  }

  @override
  String chartError(Object error) {
    return 'Grafik yüklenemedi. $error';
  }

  @override
  String get dailyMinutes14Days => 'Günlük dakika (14 gün)';

  @override
  String get weeklyMinutes => 'Haftalık dakika';

  @override
  String get thisWeekShort => 'Bu hafta';

  @override
  String weeksAgoShort(int weeks) {
    return '-${weeks}h';
  }

  @override
  String get totals => 'Toplamlar';

  @override
  String statsError(Object error) {
    return 'İstatistikler yüklenemedi. $error';
  }

  @override
  String dayStreak(int days) {
    return '$days günlük seri';
  }

  @override
  String get currentStreak => 'Mevcut seri';

  @override
  String daysCount(int days) {
    return '$days gün';
  }

  @override
  String longestDays(int days) {
    return 'En uzun: $days gün';
  }

  @override
  String couldNotLoadStreak(Object error) {
    return 'Seri yüklenemedi. $error';
  }

  @override
  String get readingReminderTitle => 'Okuma Hatırlatması';

  @override
  String get readingReminderBodyNoStreak =>
      'Bugün henüz okuma kaydı eklemediniz. Alışkanlık oluşturmak için hızlıca bir kayıt ekleyin.';

  @override
  String readingReminderBodyWithStreak(int streak) {
    return '$streak günlük serinizi kaybetmeyin—gece yarısından önce okumanızı kaydedin.';
  }

  @override
  String get readingReminderChannelName => 'Okuma hatırlatmaları';

  @override
  String get readingReminderChannelDescription => 'Günlük okuma hatırlatmaları';

  @override
  String get signInToSeeStats =>
      'Okuma istatistiklerinizi keşfetmek ve okuma kimliğinizi görmek için giriş yapın.';

  @override
  String get contentYouAdded => 'Eklediğiniz içerik';

  @override
  String get reviewsAndQuotes => 'Yorumlar ve alıntılar';

  @override
  String get noDataYet =>
      'İstatistikleri görmek için okumaya ve içerik eklemeye başlayın.';

  @override
  String couldNotLoadContentStats(Object error) {
    return 'İçerik istatistikleri yüklenemedi. $error';
  }

  @override
  String get yourRatings => 'Puanlariniz';

  @override
  String get starsGivenToBooks => 'Verdiğiniz yıldız puanları';

  @override
  String couldNotLoadRatings(Object error) {
    return 'Puanlar yüklenemedi. $error';
  }

  @override
  String get library => 'Kütüphane';

  @override
  String get countsFromShelves => 'Raflarınızdaki kitaplar';

  @override
  String couldNotLoadLibraryStats(Object error) {
    return 'Kütüphane istatistikleri yüklenemedi. $error';
  }

  @override
  String get readingIdentity => 'Okuma kimliği';

  @override
  String get genresAndAuthorsFromCompleted =>
      'Tamamlanan kitaplardan türler ve yazarlar';

  @override
  String get topGenres => 'Favori türler';

  @override
  String couldNotLoadGenres(Object error) {
    return 'Türler yüklenemedi. $error';
  }

  @override
  String get topAuthors => 'Favori yazarlar';

  @override
  String couldNotLoadAuthors(Object error) {
    return 'Yazarlar yüklenemedi. $error';
  }

  @override
  String get author => 'Yazar';

  @override
  String get noBiographyAvailable => 'Bu yazar için biyografi bulunmuyor.';

  @override
  String couldNotLoadAuthor(Object error) {
    return 'Yazar yüklenemedi. $error';
  }

  @override
  String get listsForYou => 'Sana özel';

  @override
  String get listsTopTwenty => 'Zamansız';

  @override
  String get listsFollowing => 'Takip Edilenler';

  @override
  String get myLists => 'Listelerim';

  @override
  String get savedLists => 'Kaydedilen Listeler';

  @override
  String get createList => 'Liste oluştur';

  @override
  String get editList => 'Listeyi düzenle';

  @override
  String get title => 'Başlık';

  @override
  String get description => 'Açıklama';

  @override
  String get public => 'Herkese açık';

  @override
  String get bookSelector => 'Kitap ekle';

  @override
  String get searchViaGoogleBooks => 'Google Books ile ara';

  @override
  String get search => 'Ara';

  @override
  String get selectedBooks => 'Seçilen kitaplar';

  @override
  String get noBooksSelectedYet => 'Listenize kitap arayın ve ekleyin.';

  @override
  String get noListsYet =>
      'Henüz liste oluşturmadınız. İlk listenizi oluşturun!';

  @override
  String couldNotLoadLists(Object error) {
    return 'Listeler yüklenemedi. $error';
  }

  @override
  String byUser(Object userName) {
    return '$userName tarafından';
  }

  @override
  String get books => 'Kitaplar';

  @override
  String get comments => 'Yorumlar';

  @override
  String couldNotLoadListItems(Object error) {
    return 'Liste öğeleri yüklenemedi. $error';
  }

  @override
  String couldNotLoadComments(Object error) {
    return 'Yorumlar yüklenemedi. $error';
  }

  @override
  String get addCommentHint => 'Yorum yazın…';

  @override
  String get send => 'Gönder';

  @override
  String get deleteListTitle => 'Liste silinsin mi?';

  @override
  String get deleteListConfirm => 'Bu liste kalıcı olarak silinecek.';

  @override
  String get delete => 'Sil';

  @override
  String couldNotSaveList(Object error) {
    return 'Liste kaydedilemedi. $error';
  }

  @override
  String commentsCount(int count) {
    return '$count yorum';
  }

  @override
  String get stats => 'İstatistikler';

  @override
  String get myListsTooltip => 'Listelerim';

  @override
  String get editListTooltip => 'Listeyi düzenle';

  @override
  String get deleteListTooltip => 'Listeyi sil';

  @override
  String get uxErrorNetwork => 'İnternet bağlantınızı kontrol edin.';

  @override
  String get uxErrorTimeout => 'İstek zaman aşımına uğradı.';

  @override
  String get uxErrorUnknown => 'Bir hata oluştu, lütfen tekrar deneyin.';

  @override
  String get uxErrorBoundaryTitle => 'Beklenmeyen hata';

  @override
  String get uxRetry => 'Tekrar dene';

  @override
  String get uxOfflineBanner => 'İnternet bağlantısı yok';

  @override
  String get uxEmailRequired => 'E-posta gerekli';

  @override
  String get uxEmailInvalid => 'Geçerli bir e-posta girin';

  @override
  String get uxPasswordRequired => 'Şifre gerekli';

  @override
  String get uxUserNameRequired => 'Görünen ad gerekli';

  @override
  String get uxTitleRequired => 'Başlık gerekli';

  @override
  String get uxAcceptPrivacyRequired =>
      'Devam etmek için gizlilik politikasını kabul edin';

  @override
  String get uxListCreatedSuccess => 'Liste oluşturuldu';

  @override
  String get uxListUpdatedSuccess => 'Liste kaydedildi';

  @override
  String get uxRemoveBookFromListTitle => 'Bu kitap kaldırılsın mı?';

  @override
  String get uxRemoveBookFromListMessage =>
      'Kitap yalnızca bu listeden kaldırılacak.';

  @override
  String get uxRemove => 'Kaldır';

  @override
  String get uxDeleteReviewTitle => 'İnceleme silinsin mi?';

  @override
  String get uxDeleteReviewMessage => 'Bu inceleme kalıcı olarak silinecek.';

  @override
  String get uxGalleryPluginError =>
      'Galeri açılamadı. Uygulamayı tamamen kapatıp yeniden deneyin.';

  @override
  String get uxProfilePhotoStorageNotReady =>
      'Profil fotoğrafları henüz kullanılamıyor. Lütfen daha sonra tekrar deneyin.';

  @override
  String get uxProfilePhotoPermissionDenied =>
      'Profil fotoğrafı yükleme geçici olarak kullanılamıyor. Lütfen daha sonra tekrar deneyin.';

  @override
  String get forgotPassword => 'Şifremi unuttum?';

  @override
  String get forgotPasswordTitle => 'Şifremi unuttum';

  @override
  String get forgotPasswordPrompt =>
      'E-posta adresinizi girin, şifrenizi sıfırlamak için 8 haneli bir kod göndereceğiz.';

  @override
  String get sendResetCode => 'Kod gönder';

  @override
  String get resetCodeSent => '8 haneli kod için e-postanızı kontrol edin.';

  @override
  String get resetPasswordTitle => 'Şifreyi yenile';

  @override
  String resetPasswordPrompt(String email) {
    return '$email adresine gönderilen kodu girin.';
  }

  @override
  String get otpCodeLabel => '8 haneli doğrulama kodu';

  @override
  String get confirmPassword => 'Şifreyi onayla';

  @override
  String get updatePassword => 'Şifreyi güncelle';

  @override
  String get resendCode => 'Kodu tekrar gönder';

  @override
  String get uxOtpIncomplete => 'Lütfen 8 haneli kodu eksiksiz girin.';

  @override
  String get uxPasswordMismatch => 'Şifreler eşleşmiyor.';

  @override
  String get passwordResetSuccess => 'Şifreniz başarıyla güncellendi.';

  @override
  String get invalidOrExpiredOtp =>
      'Geçersiz veya süresi dolmuş doğrulama kodu.';

  @override
  String get uxPasswordTooShort => 'Şifre en az 6 karakter olmalıdır.';

  @override
  String get uxPasswordMissingUppercase =>
      'Şifre en az bir büyük harf içermelidir.';

  @override
  String get uxPasswordMissingLowercase =>
      'Şifre en az bir küçük harf içermelidir.';

  @override
  String get uxPasswordMissingPunctuation =>
      'Şifre en az bir noktalama işareti içermelidir.';

  @override
  String get uxMustSignIn => 'Devam etmek için giriş yapın.';

  @override
  String get uxReviewMinLength => 'İnceleme en az 10 karakter olmalıdır.';

  @override
  String get privacyPolicyAppBar => 'Gizlilik Politikası';

  @override
  String get privacyPolicyTitle => 'Rubricator Gizlilik Politikası';

  @override
  String get privacyPolicyLastUpdated => 'Son güncelleme: 28.07.2026';

  @override
  String get privacyPolicyMeta =>
      'Uygulama: Rubricator (Flutter tabanlı, iOS/Android/Web/Masaüstü)\nGeliştirici/Veri Sorumlusu: İsmail Yücel Ölmez\nİletişim: support@rubricator.app';

  @override
  String get privacyPolicySection1Title => '1. Giriş';

  @override
  String get privacyPolicySection1Body1 =>
      'Rubricator (\"uygulama\", \"biz\", \"bizim\"), kitap keşfi, kişisel okuma takibi, kitap notları/incelemeleri, okuma listeleri ve yapay zekâ destekli kitap özellikleri sunan bir mobil/masaüstü uygulamasıdır.';

  @override
  String get privacyPolicySection1Body2 =>
      'Bu Gizlilik Politikası; Rubricator\'ı kullanırken hangi verilerin toplandığını, bu verilerin nasıl kullanıldığını, kimlerle ve neden paylaşıldığını, ne kadar süreyle saklandığını ve verileriniz üzerindeki haklarınızı açıklar. Politika, uygulamanın gerçek teknik mimarisi (Supabase, özel API sunucusu ve Google Gemini tabanlı yapay zekâ özellikleri dâhil) incelenerek hazırlanmıştır.';

  @override
  String get privacyPolicySection1Body3 =>
      'Uygulamayı kullanarak bu politikada açıklanan veri işleme faaliyetlerini kabul etmiş olursunuz. Politikayı kabul etmiyorsanız lütfen uygulamayı kullanmayınız.';

  @override
  String get privacyPolicySection2Title => '2. Hangi Verileri Topluyoruz';

  @override
  String get privacyPolicySection21Title =>
      '2.1 Hesap Oluştururken Verdiğiniz Bilgiler';

  @override
  String get privacyPolicySection21Body =>
      'Rubricator\'da hesap, e-posta adresi ve şifre ile oluşturulur (üçüncü taraf ile tek tıkla giriş — Google/Apple girişi — kullanılmamaktadır). Kayıt ve kimlik doğrulama sırasında topladığımız veriler:';

  @override
  String get privacyPolicySection21Item1 => '- E-posta adresiniz';

  @override
  String get privacyPolicySection21Item2 =>
      '- Şifreniz (şifreleriniz bizim sunucularımızda değil, kimlik doğrulama altyapımız olan Supabase Auth tarafından güvenli biçimde (hash\'lenerek) saklanır; düz metin olarak hiçbir yerde tutulmaz)';

  @override
  String get privacyPolicySection21Item3 => '- Kullanıcı adı / görünen ad';

  @override
  String get privacyPolicySection21Item4 =>
      '- (Varsa) e-posta doğrulama / şifre sıfırlama sürecinde oluşturulan tek kullanımlık kod (OTP)';

  @override
  String get privacyPolicySection22Title => '2.2 Profil Bilgileri';

  @override
  String get privacyPolicySection22Item1 =>
      '- Profil fotoğrafı (isteğe bağlıdır; galerinizden seçtiğiniz bir görseli yükleyebilirsiniz, cihaz galerisine erişim yalnızca sizin başlattığınız yükleme anında istenir)';

  @override
  String get privacyPolicySection22Item2 =>
      '- Profilde görünmesini seçtiğiniz diğer bilgiler';

  @override
  String get privacyPolicySection23Title =>
      '2.3 Uygulama İçinde Oluşturduğunuz İçerikler';

  @override
  String get privacyPolicySection23Body =>
      'Uygulamayı kullanırken oluşturduğunuz aşağıdaki içerikler hesabınızla ilişkilendirilerek saklanır:';

  @override
  String get privacyPolicySection23Item1 =>
      '- Kitap incelemeleri ve puanlamalar (10 üzerinden derecelendirme sistemi)';

  @override
  String get privacyPolicySection23Item2 => '- Kitap notları ve alıntılar';

  @override
  String get privacyPolicySection23Item3 =>
      '- Oluşturduğunuz okuma listeleri (sosyal listeler) ve bu listelere eklediğiniz kitaplar';

  @override
  String get privacyPolicySection23Item4 => '- Favori kitaplarınız';

  @override
  String get privacyPolicySection23Item5 =>
      '- \"Okudum / okuyorum\" durumları, okuma günlükleri ve tamamlanan kitap kayıtları';

  @override
  String get privacyPolicySection23Item6 =>
      '- İnceleme, liste ve içeriklere verdiğiniz beğeniler';

  @override
  String get privacyPolicySection23Item7 =>
      '- Alışkanlık takibi verileri — örneğin okuma hedefi/serisi (streak) kayıtlarınız';

  @override
  String get privacyPolicySection23Item8 =>
      '- Uygulama içi arama geçmişiniz (öneri kalitesini artırmak amacıyla tutulabilir)';

  @override
  String get privacyPolicySection24Title =>
      '2.4 Yapay Zekâ Özellikleri Kapsamında İşlenen Veriler';

  @override
  String get privacyPolicySection24Body =>
      'Rubricator, aşağıdaki yapay zekâ destekli özellikleri sunar ve bu özellikler kapsamında girdileriniz işlenmek üzere Google Gemini modellerine (embedding ve gemini-2.5-flash) aktarılır:';

  @override
  String get privacyPolicySection24Item1 =>
      '- Semantik Kitap Keşfi (Virgil): Doğal dilde yazdığınız arama sorguları, kendi sunucumuz (FastAPI) üzerinden Google Gemini API\'sine iletilir.';

  @override
  String get privacyPolicySection24Item2 =>
      '- Belge Sohbeti (PDF/EPUB): Yüklediğiniz PDF veya EPUB dosyaları geçici olarak sunucumuza aktarılır, parçalara ayrılıp vektörleştirilir ve Google Gemini\'ye gönderilir. Belgeler ve oturum verileri kalıcı olarak kaydedilmez; oturum süresi sonunda veya siz sonlandırdığınızda silinir.';

  @override
  String get privacyPolicySection24Item3 =>
      '- Kitap Hakkında Sohbet / Öneri (Virgil): Kitaplarla ilgili sorularınız ve öneriler benzer şekilde yapay zekâ sağlayıcısına iletilir. Anonim kullanım sayaçları (günlük istek adedi gibi) tutulabilir.';

  @override
  String get privacyPolicySection24Note =>
      'Önemli: Yapay zekâ sağlayıcısına (Google Gemini) gönderilen veriler, ilgili sağlayıcının kendi gizlilik politikası ve veri işleme koşullarına tabidir. Hassas kişisel veri içeren belgeleri belge sohbeti özelliğine yüklememenizi tavsiye ederiz.';

  @override
  String get privacyPolicySection25Title =>
      '2.5 Kitap Kataloğu Verileri (Üçüncü Taraf Kaynaklı)';

  @override
  String get privacyPolicySection25Body =>
      'Kitap arama, kapak görseli, açıklama ve yazar bilgileri Google Books API\'sinden, sunucumuz üzerinden bir vekil (proxy) aracılığıyla çekilir. Bu veriler kitaplara aittir, sizinle ilgili kişisel veri içermez.';

  @override
  String get privacyPolicySection26Title =>
      '2.6 Otomatik Olarak Toplanan Teknik Veriler';

  @override
  String get privacyPolicySection26Item1 =>
      '- Hata/çökme raporları: Uygulama kararlılığı için Sentry kullanılır. Cihaz/işletim sistemi bilgisi, uygulama sürümü, hata yığın izi ve bağlam iletilir; varsayılan olarak isim/e-posta gibi doğrudan kimliklendirici bilgi gönderilmez.';

  @override
  String get privacyPolicySection26Item2 =>
      '- Bağlantı durumu: Yalnızca cihaz üzerinde kontrol edilir; sunucularımıza gönderilmez.';

  @override
  String get privacyPolicySection26Item3 =>
      '- Yerel bildirim verileri: Okuma hatırlatıcıları tamamen cihazınızda planlanır; sunucularımıza aktarılmaz.';

  @override
  String get privacyPolicySection27Title => '2.7 Cihaz İzinleri';

  @override
  String get privacyPolicySection27Body =>
      'Konum, kamera, kişi listesi, mikrofon gibi izinler uygulama tarafından talep edilmez. Talep edilebilecek izinler:';

  @override
  String get privacyPolicySection27Item1 =>
      '- İnternet erişimi: Sunucularımızla ve üçüncü taraf servislerle iletişim';

  @override
  String get privacyPolicySection27Item2 =>
      '- Bildirim gönderme: Okuma hatırlatıcıları ve uygulama içi bildirimler';

  @override
  String get privacyPolicySection27Item3 =>
      '- Tam zamanlı alarm / zamanlayıcı: Belirlediğiniz saatte okuma hatırlatıcısı gösterebilmek';

  @override
  String get privacyPolicySection27Item4 =>
      '- Galeri / dosya erişimi: Profil fotoğrafı yükleme, belge sohbeti için PDF/EPUB seçme';

  @override
  String get privacyPolicySection3Title => '3. Verilerinizi Neden İşliyoruz';

  @override
  String get privacyPolicySection3Item1 =>
      '- Hesabınızı oluşturmak, kimliğinizi doğrulamak ve oturumunuzu güvenli şekilde yönetmek';

  @override
  String get privacyPolicySection3Item2 =>
      '- Kitap keşfi, arama, favoriler, listeler, notlar, incelemeler gibi temel işlevleri sunmak';

  @override
  String get privacyPolicySection3Item3 =>
      '- Yapay zekâ destekli semantik arama, kitap önerisi ve belge sohbeti özelliklerini çalıştırmak';

  @override
  String get privacyPolicySection3Item4 =>
      '- Size kişiselleştirilmiş kitap önerileri sunmak';

  @override
  String get privacyPolicySection3Item5 =>
      '- Okuma hatırlatıcıları ve alışkanlık takibi bildirimleri göndermek';

  @override
  String get privacyPolicySection3Item6 =>
      '- Uygulama performansını izlemek, hataları tespit edip gidermek';

  @override
  String get privacyPolicySection3Item7 =>
      '- Kötüye kullanımı önlemek, hizmet kotalarını uygulamak';

  @override
  String get privacyPolicySection3Item8 =>
      '- Yasal yükümlülüklere uymak ve kullanıcı güvenliğini korumak';

  @override
  String get privacyPolicySection3Body =>
      'Verileriniz; rızanız (ör. yapay zekâ özelliklerini kullanmayı tercih etmeniz), sözleşmenin ifası (hesabınızın ve hizmetin sağlanması) ve meşru menfaat (güvenlik, hata giderme, hizmet iyileştirme) hukuki sebeplerine dayanarak işlenmektedir.';

  @override
  String get privacyPolicySection4Title =>
      '4. Verilerin Saklandığı Yer ve Güvenlik';

  @override
  String get privacyPolicySection4Body =>
      'Verileriniz şu altyapılarda barındırılır: Supabase (veritabanı, kimlik doğrulama, dosya depolama); kendi API sunucumuz (FastAPI — semantik arama ve belge sohbeti; belge oturumları geçicidir); Google Gemini API; Sentry (hata raporları).';

  @override
  String get privacyPolicySection4Item1 =>
      '- Tüm iletişim şifreli bağlantılar (HTTPS/TLS) üzerinden yapılır';

  @override
  String get privacyPolicySection4Item2 =>
      '- Şifreler asla düz metin olarak saklanmaz';

  @override
  String get privacyPolicySection4Item3 =>
      '- Veritabanı erişimi satır düzeyi güvenlik (RLS) ile hesap sahibine özgülenir';

  @override
  String get privacyPolicySection4Item4 =>
      '- Sunucu tarafı yetkilendirme ve erişim kontrolü uygulanır';

  @override
  String get privacyPolicySection4Body2 =>
      'Hiçbir internet tabanlı sistemin %100 güvenli olduğu garanti edilemez; ancak verilerinizi korumak için makul teknik ve idari önlemleri alıyoruz.';

  @override
  String get privacyPolicySection5Title => '5. Verilerin Paylaşımı';

  @override
  String get privacyPolicySection5Body =>
      'Kişisel verilerinizi satmıyoruz. Verileriniz yalnızca aşağıdaki durumlarda ve taraflarla paylaşılır:';

  @override
  String get privacyPolicySection5Item1 =>
      '- Supabase: Hesap, profil, kullanıcı içerikleri — barındırma, kimlik doğrulama, dosya depolama';

  @override
  String get privacyPolicySection5Item2 =>
      '- Google Gemini: Arama sorgunuz, belge içerikleri, sohbet mesajlarınız — yapay zekâ özellikleri';

  @override
  String get privacyPolicySection5Item3 =>
      '- Google Books API: Kitap arama terimleri — katalog verisi (kişisel veri içermez)';

  @override
  String get privacyPolicySection5Item4 =>
      '- Sentry: Cihaz/uygulama teknik bilgisi, hata izleri — kararlılık izleme';

  @override
  String get privacyPolicySection5Body2 =>
      'Ayrıca yasal yükümlülük, mahkeme kararı veya resmi talep; kullanıcı/uygulama güvenliğini koruma; birleşme, devralma veya varlık satışı hâlinde (önceden bilgilendirilirsiniz) paylaşım yapılabilir.';

  @override
  String get privacyPolicySection6Title => '6. Herkese Açık İçerikler';

  @override
  String get privacyPolicySection6Body =>
      'Bazı içerikler varsayılan veya tercihinize göre diğer kullanıcılar (ve bazı durumlarda oturum açmamış ziyaretçiler) tarafından görülebilir:';

  @override
  String get privacyPolicySection6Item1 =>
      '- Herkese açık olarak paylaştığınız okuma listeleri';

  @override
  String get privacyPolicySection6Item2 =>
      '- Kitap incelemeleriniz, puanlarınız, notlarınız ve alıntılarınız (kullanıcı adınızla)';

  @override
  String get privacyPolicySection6Item3 => '- Aldığınız/verdiğiniz beğeniler';

  @override
  String get privacyPolicySection6Body2 =>
      'Herkese açık paylaştığınız içerikler, siz silseniz dahi başka kullanıcılar tarafından önceden görüntülenmiş, kopyalanmış veya paylaşılmış olabilir; bu tür ikincil paylaşımlar üzerinde kontrolümüz bulunmamaktadır.';

  @override
  String get privacyPolicySection7Title => '7. Veri Saklama Süreleri';

  @override
  String get privacyPolicySection7Item1 =>
      '- Hesap ve içerik verileriniz, hesabınız aktif olduğu sürece saklanır.';

  @override
  String get privacyPolicySection7Item2 =>
      '- Belge sohbeti dosyaları ve oturum verileri işlem/oturum bitince otomatik silinir; kalıcı saklanmaz.';

  @override
  String get privacyPolicySection7Item3 =>
      '- Hesap silme talebinde, doğrulamadan itibaren 7 gün içinde silinir; yasal yükümlülük nedeniyle bazı veriler en fazla 30 gün daha saklanabilir.';

  @override
  String get privacyPolicySection7Item4 =>
      '- Hata/çökme raporları Sentry\'nin saklama süresi politikasına tabidir.';

  @override
  String get privacyPolicySection8Title => '8. Haklarınız';

  @override
  String get privacyPolicySection8Body =>
      'KVKK ve/veya GDPR kapsamında, uygulanabilir olduğu ölçüde aşağıdaki haklara sahipsiniz:';

  @override
  String get privacyPolicySection8Item1 =>
      '- Kişisel verilerinizin işlenip işlenmediğini öğrenme';

  @override
  String get privacyPolicySection8Item2 =>
      '- İşlenen verileriniz hakkında bilgi talep etme';

  @override
  String get privacyPolicySection8Item3 =>
      '- Verilerinize erişme ve bir kopyasını (taşınabilir formatta) alma';

  @override
  String get privacyPolicySection8Item4 =>
      '- Yanlış veya eksik verilerin düzeltilmesini isteme';

  @override
  String get privacyPolicySection8Item5 =>
      '- Verilerinizin silinmesini veya yok edilmesini talep etme';

  @override
  String get privacyPolicySection8Item6 =>
      '- İşlemeye itiraz etme veya rızanızı geri çekme';

  @override
  String get privacyPolicySection8Item7 =>
      '- Otomatik sistemlerle aleyhinize sonuç çıkmasına itiraz etme';

  @override
  String get privacyPolicySection8Item8 =>
      '- Kanuna aykırı işleme nedeniyle zarara uğramanız hâlinde giderim talep etme';

  @override
  String get privacyPolicySection8Body2 =>
      'Bu haklarınızı kullanmak için support@rubricator.app adresinden bizimle iletişime geçebilirsiniz.';

  @override
  String get privacyPolicySection9Title => '9. Hesap ve Veri Silme';

  @override
  String get privacyPolicySection9Body1 =>
      'Hesabınızı ve ilişkili verilerinizi silmek isterseniz:';

  @override
  String get privacyPolicySection9Item1 =>
      '1. support@rubricator.app adresine e-posta gönderin.';

  @override
  String get privacyPolicySection9Item2 =>
      '2. Konu satırına \"Account Deletion Request\" yazın.';

  @override
  String get privacyPolicySection9Item3 =>
      '3. E-posta metnine Rubricator\'a kayıtlı e-posta adresinizi ekleyin.';

  @override
  String get privacyPolicySection9Body2 =>
      'Talebiniz doğrulandıktan sonra hesap profiliniz ve kişisel verileriniz 7 gün içinde silinir; yasal saklama gereken sınırlı veriler en fazla 30 gün daha tutulabilir.';

  @override
  String get privacyPolicySection10Title => '10. Çocukların Gizliliği';

  @override
  String get privacyPolicySection10Body =>
      'Rubricator, 13 yaşın altındaki çocuklara yönelik değildir ve bu yaş grubundaki kullanıcılardan bilerek veri toplamaz. 13 yaşın altındaki bir çocuğun bize kişisel veri sağladığını fark edersek, bu veriyi makul süre içinde sileriz. Bir ebeveyn veya vasi olarak çocuğunuzun bize veri sağladığını düşünüyorsanız lütfen support@rubricator.app adresinden bizimle iletişime geçin.';

  @override
  String get privacyPolicySection11Title =>
      '11. Yerel Depolama (Cihaz Üzerinde Saklanan Veriler)';

  @override
  String get privacyPolicySection11Body =>
      'Uygulama, bazı tercihlerinizi ve önbellek verilerini (ör. oturum bilgisi, tema tercihi, geçici içerik önbelleği) doğrudan cihazınızda yerel olarak saklar. Bu veriler uygulamayı kaldırdığınızda cihazınızdan silinir ve sunucularımıza otomatik olarak aktarılmaz.';

  @override
  String get privacyPolicySection12Title => '12. Uluslararası Veri Aktarımı';

  @override
  String get privacyPolicySection12Body =>
      'Kullandığımız altyapı sağlayıcıları (Supabase, Google, Sentry) verilerinizi Türkiye dışındaki sunucularda (ör. Avrupa Birliği veya Amerika Birleşik Devletleri) işleyebilir. Bu tür aktarımlarda, ilgili sağlayıcıların sunduğu güvenlik ve uyumluluk mekanizmalarına (standart sözleşme hükümleri, veri işleme anlaşmaları vb.) güveniyoruz.';

  @override
  String get privacyPolicySection13Title =>
      '13. Üçüncü Taraf Servisler ve Bağlantılar';

  @override
  String get privacyPolicySection13Body =>
      'Uygulama içinde üçüncü taraf web sitelerine veya kaynaklara bağlantılar bulunabilir. Bu üçüncü taraf sitelerin kendi gizlilik politikaları geçerlidir; bu politika yalnızca Rubricator\'ın kendi veri işleme faaliyetlerini kapsar.';

  @override
  String get privacyPolicySection13Item1 =>
      '- Supabase Gizlilik Politikası: https://supabase.com/privacy';

  @override
  String get privacyPolicySection13Item2 =>
      '- Google Gizlilik Politikası: https://policies.google.com/privacy (Gemini API ve Google Books API)';

  @override
  String get privacyPolicySection13Item3 =>
      '- Sentry Gizlilik Politikası: https://sentry.io/privacy/';

  @override
  String get privacyPolicySection14Title => '14. Politikadaki Değişiklikler';

  @override
  String get privacyPolicySection14Body =>
      'Bu Gizlilik Politikasını zaman zaman güncelleyebiliriz. Önemli değişikliklerde uygulama içi bildirim veya e-posta yoluyla sizi bilgilendirebiliriz. Güncel politika her zaman bu sayfanın en üstündeki \"Son güncelleme\" tarihiyle yayınlanır. Politikayı düzenli olarak gözden geçirmenizi öneririz.';

  @override
  String get privacyPolicySection15Title => '15. İletişim';

  @override
  String get privacyPolicySection15Body =>
      'Bu Gizlilik Politikası veya kişisel verilerinizin işlenmesiyle ilgili sorularınız, talepleriniz veya şikâyetleriniz için bizimle iletişime geçebilirsiniz:';

  @override
  String get privacyPolicySection15Contact =>
      'Rubricator\nE-posta: support@rubricator.app\nGeliştirici: İsmail Yücel Ölmez';

  @override
  String get privacyPolicyFooter =>
      'Rubricator\'ı kullanarak bu Gizlilik Politikasını kabul etmiş olursunuz.';
}
