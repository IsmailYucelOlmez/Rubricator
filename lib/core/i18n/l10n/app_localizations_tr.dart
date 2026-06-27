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
  String get navLists => 'Listeler';

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
  String get pickProfilePhotoFromGallery => 'Profil fotoğrafını galeriden seç';

  @override
  String get changeProfilePhoto => 'Profil fotoğrafını değiştir';

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
  String get passwordMin6 => 'En az 6 karakter, büyük/küçük harf ve noktalama';

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
  String get discover => 'Keşfet';

  @override
  String get noBooksFound => 'Kitap bulunamadı';

  @override
  String get searchCouldNotComplete =>
      'Arama tamamlanamadı. Lütfen tekrar deneyin.';

  @override
  String get continueReading => 'Okumaya Devam Et';

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
  String get userReviews => 'Kullanıcı Yorumları';

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
  String get privacyPolicyLastUpdated => 'Son güncelleme: 19.04.2026';

  @override
  String get privacyPolicySection1Title => '1. Giriş';

  @override
  String get privacyPolicySection1Body1 =>
      'Rubricator\'a hoş geldiniz (\"biz\", \"bizim\" veya \"bize\"). Rubricator; kullanıcıların kitap keşfedebildiği, liste oluşturabildiği, okuma alışkanlıklarını takip edebildiği ve içerik paylaşabildiği sosyal bir okuma platformudur.';

  @override
  String get privacyPolicySection1Body2 =>
      'Bu Gizlilik Politikası, mobil uygulamamızı kullanırken bilgilerinizi nasıl topladığımızı, kullandığımızı, paylaştığımızı ve koruduğumuzu açıklar.';

  @override
  String get privacyPolicySection2Title => '2. Topladığımız Bilgiler';

  @override
  String get privacyPolicySection21Title => '2.1 Kişisel Bilgiler';

  @override
  String get privacyPolicySection21Item1 => '- E-posta adresi';

  @override
  String get privacyPolicySection21Item2 => '- Kullanıcı adı';

  @override
  String get privacyPolicySection21Item3 => '- Profil bilgileri (isteğe bağlı)';

  @override
  String get privacyPolicySection22Title =>
      '2.2 Kullanıcı Tarafından Üretilen İçerik';

  @override
  String get privacyPolicySection22Item1 => '- Kitap incelemeleri';

  @override
  String get privacyPolicySection22Item2 => '- Puanlamalar';

  @override
  String get privacyPolicySection22Item3 => '- Alintilar';

  @override
  String get privacyPolicySection22Item4 => '- Oluşturduğunuz listeler';

  @override
  String get privacyPolicySection22Item5 => '- Yorumlar';

  @override
  String get privacyPolicySection23Title => '2.3 Kullanım Verileri';

  @override
  String get privacyPolicySection23Item1 => '- Uygulama kullanım etkileşimleri';

  @override
  String get privacyPolicySection23Item2 =>
      '- Özellik kullanımı (örneğin listeler, istatistikler, arama)';

  @override
  String get privacyPolicySection23Item3 =>
      '- Cihaz bilgileri (işletim sistemi sürümü, cihaz tipi)';

  @override
  String get privacyPolicySection24Title => '2.4 Kimlik Doğrulama Verileri';

  @override
  String get privacyPolicySection24Item1 => '- Temel profil bilgileri';

  @override
  String get privacyPolicySection24Item2 => '- E-posta adresi';

  @override
  String get privacyPolicySection3Title =>
      '3. Bilgilerinizi Nasıl Kullanıyoruz';

  @override
  String get privacyPolicySection3Item1 => '- Uygulamayı sunmak ve sürdürmek';

  @override
  String get privacyPolicySection3Item2 =>
      '- Sosyal özellikleri etkinleştirmek (listeler, yorumlar, beğeniler)';

  @override
  String get privacyPolicySection3Item3 =>
      '- İçeriği ve önerileri kişiselleştirmek';

  @override
  String get privacyPolicySection3Item4 =>
      '- Uygulama performansını ve özellikleri iyileştirmek';

  @override
  String get privacyPolicySection3Item5 => '- Önemli güncellemeleri iletmek';

  @override
  String get privacyPolicySection4Title => '4. Veri Saklama ve Güvenlik';

  @override
  String get privacyPolicySection4Body =>
      'Verileriniz, Supabase gibi üçüncü taraf altyapılar kullanılarak güvenli şekilde saklanır.';

  @override
  String get privacyPolicySection4Item1 => '- Güvenli kimlik doğrulama';

  @override
  String get privacyPolicySection4Item2 => '- Şifreli bağlantılar (HTTPS)';

  @override
  String get privacyPolicySection4Item3 => '- Erişim kontrol mekanizmaları';

  @override
  String get privacyPolicySection5Title => '5. Veri Paylaşımı';

  @override
  String get privacyPolicySection5Body => 'Kişisel verilerinizi SATMAYIZ.';

  @override
  String get privacyPolicySection5Item1 =>
      '- Hizmet sağlayıcılarla (örneğin backend barındırma)';

  @override
  String get privacyPolicySection5Item2 => '- Yasal yükümlülüklere uymak için';

  @override
  String get privacyPolicySection5Item3 =>
      '- Kullanıcı güvenliğini ve haklarını korumak için';

  @override
  String get privacyPolicySection6Title => '6. Herkese Açık İçerik';

  @override
  String get privacyPolicySection6Item1 => '- Herkese açık listeler';

  @override
  String get privacyPolicySection6Item2 => '- Incelemeler';

  @override
  String get privacyPolicySection6Item3 => '- Yorumlar';

  @override
  String get privacyPolicySection6Body =>
      'Herkese açık paylaştığınız içerikler diğer kullanıcılar tarafından görülebilir.';

  @override
  String get privacyPolicySection7Title => '7. Veri Saklama Süresi';

  @override
  String get privacyPolicySection7Item1 => '- Hesabınız aktif olduğu sürece';

  @override
  String get privacyPolicySection7Item2 =>
      '- Veya hizmetleri sunmak için gerektiği sürece';

  @override
  String get privacyPolicySection7Body =>
      'Verilerinizin silinmesini istediğiniz zaman talep edebilirsiniz.';

  @override
  String get privacyPolicySection8Title => '8. Haklarınız';

  @override
  String get privacyPolicySection8Item1 => '- Verilerinize erişme';

  @override
  String get privacyPolicySection8Item2 => '- Bilgilerinizi güncelleme';

  @override
  String get privacyPolicySection8Item3 =>
      '- Hesabınızın silinmesini talep etme';

  @override
  String get privacyPolicySection8Item4 => '- Onayı geri çekme';

  @override
  String get privacyPolicySection8Body =>
      'Bu hakları kullanmak için bize ulaşın:';

  @override
  String get privacyPolicySection8Email => 'E-posta: [YOUR EMAIL]';

  @override
  String get privacyPolicySection9Title => '9. Çocukların Gizliliği';

  @override
  String get privacyPolicySection9Body1 =>
      'Rubricator, 13 yaş altındaki kullanıcılar için tasarlanmamıştır.';

  @override
  String get privacyPolicySection9Body2 =>
      'Çocuklardan bilerek veri toplamayız.';

  @override
  String get privacyPolicySection10Title => '10. Üçüncü Taraf Hizmetler';

  @override
  String get privacyPolicySection10Item1 =>
      '- Google (kimlik doğrulama, analiz)';

  @override
  String get privacyPolicySection10Item2 => '- Supabase (veri depolama)';

  @override
  String get privacyPolicySection10Body =>
      'Bu hizmetlerin kendi gizlilik politikaları vardır.';

  @override
  String get privacyPolicySection11Title => '11. Uluslararası Veri Aktarımları';

  @override
  String get privacyPolicySection11Body =>
      'Bilgileriniz, hizmet sağlayıcılarımızın faaliyet gösterdiği farklı ülkelerde işlenebilir.';

  @override
  String get privacyPolicySection12Title =>
      '12. Bu Gizlilik Politikasındaki Değişiklikler';

  @override
  String get privacyPolicySection12Body =>
      'Bu politikayı zaman zaman güncelleyebiliriz. Değişiklikler \"Son güncelleme\" tarihi güncellenerek yansıtılır.';

  @override
  String get privacyPolicySection13Title => '13. Bize Ulaşın';

  @override
  String get privacyPolicySection13Body =>
      'Bu Gizlilik Politikası hakkında sorunuz varsa bize ulaşın:';

  @override
  String get privacyPolicySection13Email =>
      'E-posta: ismailyucelolmez514@gmail.com';

  @override
  String get privacyPolicyFooter =>
      'Rubricator\'u kullanarak bu Gizlilik Politikası\'nı kabul etmiş olursunuz.';
}
