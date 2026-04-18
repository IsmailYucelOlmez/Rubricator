// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Rubricator';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navLists => 'Lists';

  @override
  String get profile => 'Profile';

  @override
  String get language => 'Language';

  @override
  String get themeAppearance => 'Appearance';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get english => 'English';

  @override
  String get turkish => 'Turkish';

  @override
  String get signInPrompt => 'Sign in to sync favorites across devices.';

  @override
  String get signIn => 'Sign in';

  @override
  String get createAccount => 'Create account';

  @override
  String get signedInFallback => 'Signed in';

  @override
  String get signOut => 'Sign out';

  @override
  String loadSessionError(Object error) {
    return 'Could not load session: $error';
  }

  @override
  String get invalidEmailOrPassword => 'Invalid email or password.';

  @override
  String get accountAlreadyExists =>
      'An account with this email already exists.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get passwordMin6 => 'Password (min 6 characters)';

  @override
  String get cancel => 'Cancel';

  @override
  String get signUp => 'Sign up';

  @override
  String get confirmAccountEmailNotice =>
      'Check your email to confirm your account if required.';

  @override
  String get readingHabit => 'Reading habit';

  @override
  String get readingLoggedToday => 'You logged reading today. Nice work.';

  @override
  String get didYouReadToday => 'Did you read today?';

  @override
  String todayStatusError(Object error) {
    return 'Today status: $error';
  }

  @override
  String get quickLog => 'Quick log';

  @override
  String get details => 'Details';

  @override
  String get readingStats => 'Reading stats';

  @override
  String booksCount(Object count) {
    return '$count books';
  }

  @override
  String averageShort(Object avg) {
    return '$avg avg';
  }

  @override
  String get noRatingsYet => 'No ratings yet';

  @override
  String topGenre(Object genre) {
    return 'Top: $genre';
  }

  @override
  String get viewAllStats => 'View all stats';

  @override
  String loadStatsError(Object error) {
    return 'Could not load stats: $error';
  }

  @override
  String get searchBooksTitle => 'Search Books';

  @override
  String get searchByTitleOrAuthorHint =>
      'Search by title or author (min. 2 characters)';

  @override
  String noBooksFoundFor(Object query) {
    return 'No books found for \"$query\".';
  }

  @override
  String get recentSearches => 'Recent Searches';

  @override
  String get loadRecentSearchesError => 'Could not load recent searches.';

  @override
  String get noRecentSearchesYet => 'No recent searches yet.';

  @override
  String get recentSearchedBooks => 'Recent Searched Books';

  @override
  String get loadRecentSearchedBooksError =>
      'Could not load recent searched books.';

  @override
  String get noRecentSearchedBooksYet => 'No recent searched books yet.';

  @override
  String get searchBooksMin2Hint => 'Search books (min. 2 characters)';

  @override
  String get discover => 'Discover';

  @override
  String get noBooksFound => 'No books found';

  @override
  String get searchCouldNotComplete =>
      'Could not complete the search. Please try again.';

  @override
  String get popular => 'Popular';

  @override
  String get loadPopularBooksError => 'Could not load popular books.';

  @override
  String loadGenreBooksError(Object genre) {
    return 'Could not load $genre books.';
  }

  @override
  String get genreFantasy => 'Fantasy';

  @override
  String get genreScienceFiction => 'Science Fiction';

  @override
  String get genreRomance => 'Romance';

  @override
  String get genreMystery => 'Mystery';

  @override
  String get genreThriller => 'Thriller';

  @override
  String get genreHorror => 'Horror';

  @override
  String get loadHomeGenresError =>
      'Could not load genre sections. Please try again.';

  @override
  String get toRead => 'To Read';

  @override
  String get reading => 'Reading';

  @override
  String get reReading => 'Re-reading';

  @override
  String get completed => 'Completed';

  @override
  String get dropped => 'Dropped';

  @override
  String get addToFavorites => 'Add to favorites';

  @override
  String get removeFromFavorites => 'Remove from favorites';

  @override
  String get favorites => 'Favorites';

  @override
  String get signInToSeeLists => 'Sign in from Profile to see your lists.';

  @override
  String noBooksInStatus(Object status) {
    return 'No books in $status.';
  }

  @override
  String get noFavoritesYet => 'No favorites yet.';

  @override
  String couldNotLoadList(Object error) {
    return 'Could not load list: $error';
  }

  @override
  String get bookDetails => 'Book Details';

  @override
  String get authorProfile => 'Author profile';

  @override
  String get ratingSubmitted => 'Rating submitted.';

  @override
  String get noDescriptionAvailable => 'No description available.';

  @override
  String get reviewAdded => 'Review added.';

  @override
  String get reviewUpdated => 'Review updated.';

  @override
  String get reviewDeleted => 'Review deleted.';

  @override
  String get externalReviewAdded => 'External review added.';

  @override
  String get invalidUrl => 'Invalid URL';

  @override
  String get couldNotOpenBrowser => 'Could not open browser.';

  @override
  String get quoteAdded => 'Quote added.';

  @override
  String get relatedBooks => 'Related books';

  @override
  String get noRelatedTitlesFound =>
      'No related titles found (subjects missing or empty results).';

  @override
  String get couldNotLoadRelatedBooks => 'Could not load related books.';

  @override
  String get aiSummary => 'AI Summary';

  @override
  String get aiSummaryFailed => 'AI summary failed';

  @override
  String couldNotLoadThisBook(Object error) {
    return 'Could not load this book. $error';
  }

  @override
  String get addToList => 'Add to List';

  @override
  String get change => 'Change';

  @override
  String progressPercent(Object progress) {
    return 'Progress: $progress%';
  }

  @override
  String get rating => 'Rating';

  @override
  String averageOutOfFive(Object avg) {
    return 'Average: $avg / 5';
  }

  @override
  String get couldNotLoadRating => 'Could not load rating.';

  @override
  String get submitRating => 'Submit rating';

  @override
  String get reviews => 'Reviews';

  @override
  String get userReviews => 'User Reviews';

  @override
  String get externalReviews => 'External Reviews';

  @override
  String get writeReviewHint => 'Write your review (min 10 chars)';

  @override
  String get addReview => 'Add review';

  @override
  String get noUserReviewsYet => 'No user reviews yet.';

  @override
  String get couldNotLoadReviews => 'Could not load reviews.';

  @override
  String get reviewTitle => 'Review title';

  @override
  String get reviewUrlHint => 'https://example.com/review';

  @override
  String get addExternalReview => 'Add external review';

  @override
  String get noExternalReviewsYet => 'No external reviews yet.';

  @override
  String get couldNotLoadExternalReviews => 'Could not load external reviews.';

  @override
  String get quotes => 'Quotes';

  @override
  String get addMemorableQuote => 'Add a memorable quote';

  @override
  String get addQuote => 'Add quote';

  @override
  String get noQuotesYet => 'No quotes yet.';

  @override
  String get couldNotLoadQuotes => 'Could not load quotes.';

  @override
  String get editReview => 'Edit review';

  @override
  String get save => 'Save';

  @override
  String get log => 'Log';

  @override
  String get signInForHabit =>
      'Sign in to log reading, see streaks, and view your activity calendar.';

  @override
  String get readingLogged => 'Reading logged';

  @override
  String couldNotSave(Object error) {
    return 'Could not save: $error';
  }

  @override
  String get addMinutesOrPagesPrompt =>
      'Add at least minutes or pages from today.';

  @override
  String get minutes => 'Minutes';

  @override
  String get plusTenMin => '+10 min';

  @override
  String get pages => 'Pages';

  @override
  String get plusFivePages => '+5 pages';

  @override
  String get optionalAddBooksPrompt =>
      'Optional: add books to your reading list to pick one here.';

  @override
  String get bookOptional => 'Book (optional)';

  @override
  String get book => 'Book';

  @override
  String get none => 'None';

  @override
  String booksError(Object error) {
    return 'Books: $error';
  }

  @override
  String get saveLog => 'Save log';

  @override
  String calendarError(Object error) {
    return 'Calendar error: $error';
  }

  @override
  String get activity => 'Activity';

  @override
  String lastWeeksMoreReading(int weeks) {
    return 'Last $weeks weeks (darker = more reading)';
  }

  @override
  String get noLogsYetTapQuickLog => 'No logs yet - tap Quick log to start.';

  @override
  String get recentLogs => 'Recent logs';

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String pagesShort(int count) {
    return '$count pages';
  }

  @override
  String bookIdLabel(Object bookId) {
    return 'Book: $bookId';
  }

  @override
  String logsError(Object error) {
    return 'Logs error: $error';
  }

  @override
  String chartError(Object error) {
    return 'Chart error: $error';
  }

  @override
  String get dailyMinutes14Days => 'Daily minutes (14 days)';

  @override
  String get weeklyMinutes => 'Weekly minutes';

  @override
  String get thisWeekShort => 'This wk';

  @override
  String weeksAgoShort(int weeks) {
    return '-${weeks}w';
  }

  @override
  String get totals => 'Totals';

  @override
  String statsError(Object error) {
    return 'Stats error: $error';
  }

  @override
  String dayStreak(int days) {
    return '$days day streak';
  }

  @override
  String get currentStreak => 'Current streak';

  @override
  String daysCount(int days) {
    return '$days days';
  }

  @override
  String longestDays(int days) {
    return 'Longest: $days days';
  }

  @override
  String couldNotLoadStreak(Object error) {
    return 'Could not load streak: $error';
  }

  @override
  String get signInToSeeStats =>
      'Sign in to see your library analytics and reading identity.';

  @override
  String get contentYouAdded => 'Content you added';

  @override
  String get reviewsAndQuotes => 'Reviews and quotes';

  @override
  String get noDataYet => 'No data yet';

  @override
  String couldNotLoadContentStats(Object error) {
    return 'Could not load content stats: $error';
  }

  @override
  String get yourRatings => 'Your ratings';

  @override
  String get starsGivenToBooks => 'Stars you gave to books';

  @override
  String couldNotLoadRatings(Object error) {
    return 'Could not load ratings: $error';
  }

  @override
  String get library => 'Library';

  @override
  String get countsFromShelves => 'Counts from your shelves';

  @override
  String couldNotLoadLibraryStats(Object error) {
    return 'Could not load library stats: $error';
  }

  @override
  String get readingIdentity => 'Reading identity';

  @override
  String get genresAndAuthorsFromCompleted =>
      'Genres and authors from completed books';

  @override
  String get topGenres => 'Top genres';

  @override
  String couldNotLoadGenres(Object error) {
    return 'Could not load genres: $error';
  }

  @override
  String get topAuthors => 'Top authors';

  @override
  String couldNotLoadAuthors(Object error) {
    return 'Could not load authors: $error';
  }

  @override
  String get author => 'Author';

  @override
  String get noBiographyAvailable => 'No biography available.';

  @override
  String couldNotLoadAuthor(Object error) {
    return 'Could not load author. $error';
  }

  @override
  String get listsForYou => 'For You';

  @override
  String get listsTopTwenty => 'Timeless';

  @override
  String get listsFollowing => 'Following';

  @override
  String get myLists => 'My Lists';

  @override
  String get savedLists => 'Saved Lists';

  @override
  String get createList => 'Create list';

  @override
  String get editList => 'Edit list';

  @override
  String get title => 'Title';

  @override
  String get description => 'Description';

  @override
  String get public => 'Public';

  @override
  String get bookSelector => 'Book selector';

  @override
  String get searchViaGoogleBooks => 'Search via Google Books';

  @override
  String get search => 'Search';

  @override
  String get selectedBooks => 'Selected books';

  @override
  String get noBooksSelectedYet => 'No books selected yet.';

  @override
  String get noListsYet => 'No lists yet.';

  @override
  String couldNotLoadLists(Object error) {
    return 'Could not load lists: $error';
  }

  @override
  String byUser(Object userName) {
    return 'by @$userName';
  }

  @override
  String get books => 'Books';

  @override
  String get comments => 'Comments';

  @override
  String couldNotLoadListItems(Object error) {
    return 'Could not load list items: $error';
  }

  @override
  String couldNotLoadComments(Object error) {
    return 'Could not load comments: $error';
  }

  @override
  String get addCommentHint => 'Add a comment...';

  @override
  String get send => 'Send';

  @override
  String get deleteListTitle => 'Delete list?';

  @override
  String get deleteListConfirm => 'This action cannot be undone.';

  @override
  String get delete => 'Delete';

  @override
  String couldNotSaveList(Object error) {
    return 'Could not save list: $error';
  }

  @override
  String commentsCount(int count) {
    return '$count comments';
  }

  @override
  String get stats => 'Stats';

  @override
  String get myListsTooltip => 'My lists';

  @override
  String get editListTooltip => 'Edit list';

  @override
  String get deleteListTooltip => 'Delete list';
}
