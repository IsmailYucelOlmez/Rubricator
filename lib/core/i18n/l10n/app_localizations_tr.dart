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
  String get profile => 'Profil';

  @override
  String get language => 'Dil';

  @override
  String get themeAppearance => 'Gorunum';

  @override
  String get themeLight => 'Acik';

  @override
  String get themeDark => 'Koyu';

  @override
  String get selectLanguage => 'Dil Sec';

  @override
  String get english => 'Ingilizce';

  @override
  String get turkish => 'Turkce';

  @override
  String get signInPrompt =>
      'Favorileri cihazlar arasinda esitlemek icin giris yapin.';

  @override
  String get signIn => 'Giris yap';

  @override
  String get createAccount => 'Hesap olustur';

  @override
  String get signedInFallback => 'Giris yapildi';

  @override
  String get signOut => 'Cikis yap';

  @override
  String loadSessionError(Object error) {
    return 'Oturum yuklenemedi: $error';
  }

  @override
  String get invalidEmailOrPassword => 'E-posta veya sifre hatali.';

  @override
  String get accountAlreadyExists => 'Bu e-posta ile bir hesap zaten var.';

  @override
  String get email => 'E-posta';

  @override
  String get password => 'Sifre';

  @override
  String get passwordMin6 => 'Sifre (en az 6 karakter)';

  @override
  String get cancel => 'Iptal';

  @override
  String get signUp => 'Kayit ol';

  @override
  String get confirmAccountEmailNotice =>
      'Gerekliyse hesabinizi onaylamak icin e-postanizi kontrol edin.';

  @override
  String get readingHabit => 'Okuma aliskanligi';

  @override
  String get readingLoggedToday => 'Bugun okuma kaydi girdiniz. Harika.';

  @override
  String get didYouReadToday => 'Bugun okudunuz mu?';

  @override
  String todayStatusError(Object error) {
    return 'Bugun durumu: $error';
  }

  @override
  String get quickLog => 'Hizli kayit';

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
  String get noRatingsYet => 'Henuz puan yok';

  @override
  String topGenre(Object genre) {
    return 'En iyi: $genre';
  }

  @override
  String get viewAllStats => 'Tum istatistikleri gor';

  @override
  String loadStatsError(Object error) {
    return 'Istatistikler yuklenemedi: $error';
  }

  @override
  String get searchBooksTitle => 'Kitap Ara';

  @override
  String get searchByTitleOrAuthorHint =>
      'Baslik veya yazara gore ara (en az 2 karakter)';

  @override
  String searchFailed(Object error) {
    return 'Arama basarisiz: $error';
  }

  @override
  String noBooksFoundFor(Object query) {
    return '\"$query\" icin kitap bulunamadi.';
  }

  @override
  String get recentSearches => 'Son Aramalar';

  @override
  String get loadRecentSearchesError => 'Son aramalar yuklenemedi.';

  @override
  String get noRecentSearchesYet => 'Henuz son arama yok.';

  @override
  String get recentSearchedBooks => 'Son Aranan Kitaplar';

  @override
  String get loadRecentSearchedBooksError => 'Son aranan kitaplar yuklenemedi.';

  @override
  String get noRecentSearchedBooksYet => 'Henuz son aranan kitap yok.';

  @override
  String get searchBooksMin2Hint => 'Kitap ara (en az 2 karakter)';

  @override
  String get discover => 'Kesfet';

  @override
  String get noBooksFound => 'Kitap bulunamadi';

  @override
  String get searchCouldNotComplete =>
      'Arama tamamlanamadi. Lutfen tekrar deneyin.';

  @override
  String get popular => 'Populer';

  @override
  String get loadPopularBooksError => 'Populer kitaplar yuklenemedi.';

  @override
  String loadGenreBooksError(Object genre) {
    return '$genre kitaplari yuklenemedi.';
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
  String get toRead => 'Okunacak';

  @override
  String get reading => 'Okunuyor';

  @override
  String get reReading => 'Tekrar Okunuyor';

  @override
  String get completed => 'Tamamlandi';

  @override
  String get dropped => 'Birakildi';

  @override
  String get favorites => 'Favoriler';

  @override
  String get signInToSeeLists => 'Listeleri gormek icin Profilden giris yapin.';

  @override
  String noBooksInStatus(Object status) {
    return '$status durumunda kitap yok.';
  }

  @override
  String get noFavoritesYet => 'Henuz favori yok.';

  @override
  String couldNotLoadList(Object error) {
    return 'Liste yuklenemedi: $error';
  }

  @override
  String get bookDetails => 'Kitap Detayi';

  @override
  String get authorProfile => 'Yazar profili';

  @override
  String get ratingSubmitted => 'Puan gonderildi.';

  @override
  String get noDescriptionAvailable => 'Aciklama bulunamadi.';

  @override
  String get reviewAdded => 'Yorum eklendi.';

  @override
  String get reviewUpdated => 'Yorum guncellendi.';

  @override
  String get reviewDeleted => 'Yorum silindi.';

  @override
  String get externalReviewAdded => 'Harici yorum eklendi.';

  @override
  String get invalidUrl => 'Gecersiz URL';

  @override
  String get couldNotOpenBrowser => 'Tarayici acilamadi.';

  @override
  String get quoteAdded => 'Alinti eklendi.';

  @override
  String get relatedBooks => 'Benzer kitaplar';

  @override
  String get noRelatedTitlesFound =>
      'Benzer baslik bulunamadi (konular eksik veya sonuc yok).';

  @override
  String get couldNotLoadRelatedBooks => 'Benzer kitaplar yuklenemedi.';

  @override
  String get aiSummary => 'YZ Ozeti';

  @override
  String get aiSummaryFailed => 'YZ ozeti basarisiz';

  @override
  String couldNotLoadThisBook(Object error) {
    return 'Bu kitap yuklenemedi. $error';
  }

  @override
  String get addToList => 'Listeye Ekle';

  @override
  String get change => 'Degistir';

  @override
  String progressPercent(Object progress) {
    return 'Ilerleme: %$progress';
  }

  @override
  String get rating => 'Puan';

  @override
  String averageOutOfFive(Object avg) {
    return 'Ortalama: $avg / 5';
  }

  @override
  String get couldNotLoadRating => 'Puan yuklenemedi.';

  @override
  String get submitRating => 'Puani gonder';

  @override
  String get reviews => 'Yorumlar';

  @override
  String get userReviews => 'Kullanici Yorumlari';

  @override
  String get externalReviews => 'Harici Yorumlar';

  @override
  String get writeReviewHint => 'Yorumunuzu yazin (en az 10 karakter)';

  @override
  String get addReview => 'Yorum ekle';

  @override
  String get noUserReviewsYet => 'Henuz kullanici yorumu yok.';

  @override
  String get couldNotLoadReviews => 'Yorumlar yuklenemedi.';

  @override
  String get reviewTitle => 'Yorum basligi';

  @override
  String get reviewUrlHint => 'https://example.com/review';

  @override
  String get addExternalReview => 'Harici yorum ekle';

  @override
  String get noExternalReviewsYet => 'Henuz harici yorum yok.';

  @override
  String get couldNotLoadExternalReviews => 'Harici yorumlar yuklenemedi.';

  @override
  String get quotes => 'Alintilar';

  @override
  String get addMemorableQuote => 'Akliniza kalan bir alinti ekleyin';

  @override
  String get addQuote => 'Alinti ekle';

  @override
  String get noQuotesYet => 'Henuz alinti yok.';

  @override
  String get couldNotLoadQuotes => 'Alintilar yuklenemedi.';

  @override
  String get editReview => 'Yorumu duzenle';

  @override
  String get save => 'Kaydet';

  @override
  String get log => 'Kayit';

  @override
  String get signInForHabit =>
      'Okumayi kaydetmek, serileri gormek ve aktivite takvimi icin giris yapin.';

  @override
  String get readingLogged => 'Okuma kaydedildi';

  @override
  String couldNotSave(Object error) {
    return 'Kaydedilemedi: $error';
  }

  @override
  String get addMinutesOrPagesPrompt =>
      'Bugunden en az dakika veya sayfa ekleyin.';

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
      'Istege bagli: Buradan secmek icin okuma listenize kitap ekleyin.';

  @override
  String get bookOptional => 'Kitap (istege bagli)';

  @override
  String get book => 'Kitap';

  @override
  String get none => 'Yok';

  @override
  String booksError(Object error) {
    return 'Kitaplar: $error';
  }

  @override
  String get saveLog => 'Kaydi kaydet';

  @override
  String calendarError(Object error) {
    return 'Takvim hatasi: $error';
  }

  @override
  String get activity => 'Aktivite';

  @override
  String lastWeeksMoreReading(int weeks) {
    return 'Son $weeks hafta (daha koyu = daha fazla okuma)';
  }

  @override
  String get noLogsYetTapQuickLog =>
      'Henuz kayit yok - baslamak icin Hizli kayit\'a dokunun.';

  @override
  String get recentLogs => 'Son kayitlar';

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
    return 'Kayit hatasi: $error';
  }

  @override
  String chartError(Object error) {
    return 'Grafik hatasi: $error';
  }

  @override
  String get dailyMinutes14Days => 'Gunluk dakika (14 gun)';

  @override
  String get weeklyMinutes => 'Haftalik dakika';

  @override
  String get thisWeekShort => 'Bu hf';

  @override
  String weeksAgoShort(int weeks) {
    return '-${weeks}h';
  }

  @override
  String get totals => 'Toplamlar';

  @override
  String statsError(Object error) {
    return 'Istatistik hatasi: $error';
  }

  @override
  String dayStreak(int days) {
    return '$days gun seri';
  }

  @override
  String get currentStreak => 'Mevcut seri';

  @override
  String daysCount(int days) {
    return '$days gun';
  }

  @override
  String longestDays(int days) {
    return 'En uzun: $days gun';
  }

  @override
  String couldNotLoadStreak(Object error) {
    return 'Seri yuklenemedi: $error';
  }

  @override
  String get signInToSeeStats =>
      'Kutuphane analizlerini ve okuma kimliginizi gormek icin giris yapin.';

  @override
  String get contentYouAdded => 'Eklediginiz icerik';

  @override
  String get reviewsAndQuotes => 'Yorumlar ve alintilar';

  @override
  String get noDataYet => 'Henuz veri yok';

  @override
  String couldNotLoadContentStats(Object error) {
    return 'Icerik istatistikleri yuklenemedi: $error';
  }

  @override
  String get yourRatings => 'Puanlariniz';

  @override
  String get starsGivenToBooks => 'Kitaplara verdiginiz yildizlar';

  @override
  String couldNotLoadRatings(Object error) {
    return 'Puanlar yuklenemedi: $error';
  }

  @override
  String get library => 'Kutuphane';

  @override
  String get countsFromShelves => 'Raf sayilari';

  @override
  String couldNotLoadLibraryStats(Object error) {
    return 'Kutuphane istatistikleri yuklenemedi: $error';
  }

  @override
  String get readingIdentity => 'Okuma kimligi';

  @override
  String get genresAndAuthorsFromCompleted =>
      'Tamamlanan kitaplardan turler ve yazarlar';

  @override
  String get topGenres => 'En iyi turler';

  @override
  String couldNotLoadGenres(Object error) {
    return 'Turler yuklenemedi: $error';
  }

  @override
  String get topAuthors => 'En iyi yazarlar';

  @override
  String couldNotLoadAuthors(Object error) {
    return 'Yazarlar yuklenemedi: $error';
  }

  @override
  String get author => 'Yazar';

  @override
  String get noBiographyAvailable => 'Biyografi yok.';

  @override
  String couldNotLoadAuthor(Object error) {
    return 'Yazar yuklenemedi. $error';
  }

  @override
  String get listsForYou => 'Sana Ozel';

  @override
  String get listsFollowing => 'Takip Edilenler';

  @override
  String get myLists => 'Listelerim';

  @override
  String get savedLists => 'Kaydedilen Listeler';

  @override
  String get createList => 'Liste olustur';

  @override
  String get editList => 'Listeyi duzenle';

  @override
  String get title => 'Baslik';

  @override
  String get description => 'Aciklama';

  @override
  String get public => 'Herkese acik';

  @override
  String get bookSelector => 'Kitap secici';

  @override
  String get searchViaOpenLibrary => 'Open Library ile ara';

  @override
  String get search => 'Ara';

  @override
  String get selectedBooks => 'Secilen kitaplar';

  @override
  String get noBooksSelectedYet => 'Henuz kitap secilmedi.';

  @override
  String get noListsYet => 'Henuz liste yok.';

  @override
  String couldNotLoadLists(Object error) {
    return 'Listeler yuklenemedi: $error';
  }

  @override
  String byUser(Object userName) {
    return '@$userName tarafindan';
  }

  @override
  String get books => 'Kitaplar';

  @override
  String get comments => 'Yorumlar';

  @override
  String couldNotLoadListItems(Object error) {
    return 'Liste ogeleri yuklenemedi: $error';
  }

  @override
  String couldNotLoadComments(Object error) {
    return 'Yorumlar yuklenemedi: $error';
  }

  @override
  String get addCommentHint => 'Yorum ekle...';

  @override
  String get send => 'Gonder';

  @override
  String get deleteListTitle => 'Liste silinsin mi?';

  @override
  String get deleteListConfirm => 'Bu islem geri alinamaz.';

  @override
  String get delete => 'Sil';

  @override
  String couldNotSaveList(Object error) {
    return 'Liste kaydedilemedi: $error';
  }

  @override
  String commentsCount(int count) {
    return '$count yorum';
  }

  @override
  String get stats => 'Istatistikler';

  @override
  String get myListsTooltip => 'Listelerim';

  @override
  String get editListTooltip => 'Listeyi duzenle';

  @override
  String get deleteListTooltip => 'Listeyi sil';
}
