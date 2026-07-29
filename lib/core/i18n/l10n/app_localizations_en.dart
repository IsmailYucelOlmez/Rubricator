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
  String get navVirgil => 'Virgil';

  @override
  String get navLists => 'Lists';

  @override
  String get virgilTagline => 'Virgil will guide your reading journey';

  @override
  String get virgilRecommendationHint =>
      'Find your next favorite read with recommendations.';

  @override
  String get virgilRecommendationTitle => 'Recommendation';

  @override
  String get virgilAboutBookTitle => 'About Book';

  @override
  String get virgilAboutBookHint => 'Upload a book and ask questions about';

  @override
  String get virgilBetaBadge => 'BETA';

  @override
  String get virgilRecommendationEmptyBody =>
      'Discover new authors, different genres, and works that might interest you. Virgil makes it easy for you to explore by providing recommendations.';

  @override
  String get virgilRecommendationInputHint => 'Type something...';

  @override
  String get virgilQaInputHint => 'ask question';

  @override
  String get virgilQaUploadTitle => 'Upload PDF or Epub';

  @override
  String get virgilQaSizeLimit => '20 MB Limit';

  @override
  String get virgilQaPagesLimit => '500 Pages Limit';

  @override
  String get virgilQaPrivacyNotice =>
      'The files you upload and your conversations are not recorded.';

  @override
  String get virgilQaProcessingTitle => 'File processing...';

  @override
  String get virgilQaProcessingSubtitle => 'Please wait';

  @override
  String virgilQaFileMeta(String filename, String format, int pages) {
    return '$filename | $format | $pages pages';
  }

  @override
  String virgilQaFileMetaChapters(
    String filename,
    String format,
    int chapters,
  ) {
    return '$filename | $format | $chapters chapters';
  }

  @override
  String get virgilGenreLabel => 'Genre';

  @override
  String get virgilGenreAll => 'All';

  @override
  String get virgilGenreFiction => 'Fiction';

  @override
  String get virgilGenreNonfiction => 'Nonfiction';

  @override
  String get virgilGenreChildrensFiction => 'Children\'s Fiction';

  @override
  String get virgilGenreChildrensNonfiction => 'Children\'s Nonfiction';

  @override
  String get signInForVirgil =>
      'Sign in to use Virgil recommendations and book Q&A.';

  @override
  String get virgilDailyRecommendationLimit =>
      'You can request recommendations up to 3 times per day. Try again tomorrow.';

  @override
  String get virgilDailyUploadLimit =>
      'You can upload up to 3 books per day. Try again tomorrow.';

  @override
  String virgilQuestionsRemaining(int count) {
    return '$count questions left for this book';
  }

  @override
  String get listsFeedHeading => 'Listbox';

  @override
  String get profileZoneTitle => 'Zone';

  @override
  String get readingStatsListsTitle => 'Your reading lists by status';

  @override
  String get homeShowAll => 'Show all';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get pickPhotoFromGallery => 'Choose photo from gallery';

  @override
  String get pickProfilePhotoFromGallery => 'Choose photo';

  @override
  String get changeProfilePhoto => 'Change photo';

  @override
  String get removeProfilePhotoTooltip => 'Remove photo';

  @override
  String get privacyPolicyCheckbox =>
      'I have read and accept the privacy policy.';

  @override
  String get displayNameLabel => 'Display name';

  @override
  String get profilePhotoUrlOptional => 'Profile photo URL (optional)';

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
  String get notifications => 'Notifications';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get english => 'English';

  @override
  String get turkish => 'Turkish';

  @override
  String get signInPrompt =>
      'Sign in to sync your library, lists, and reading progress across devices.';

  @override
  String get signIn => 'Sign in';

  @override
  String get createAccount => 'Create account';

  @override
  String get signedInFallback => 'You\'re signed in';

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
  String get passwordMin6 =>
      'Password (At least 6 characters with upper, lower, and punctuation)';

  @override
  String get cancel => 'Cancel';

  @override
  String get signUp => 'Sign up';

  @override
  String get confirmAccountEmailNotice =>
      'If prompted, check your email to verify your account.';

  @override
  String get readingHabit => 'Reading habit';

  @override
  String get readingLoggedToday => 'You\'ve logged reading today—nice work!';

  @override
  String get didYouReadToday => 'Did you read today?';

  @override
  String todayStatusError(Object error) {
    return 'Couldn\'t load today\'s status. $error';
  }

  @override
  String get quickLog => 'Log reading';

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
  String get searchBooksTitle => 'Search books';

  @override
  String get searchByTitleOrAuthorHint => 'Search by title or author…';

  @override
  String noBooksFoundFor(Object query) {
    return 'No results for \"$query\". Try a different title or author.';
  }

  @override
  String get recentSearches => 'Recent Searches';

  @override
  String get loadRecentSearchesError => 'Could not load recent searches.';

  @override
  String get noRecentSearchesYet => 'Your recent searches will appear here.';

  @override
  String get recentSearchedBooks => 'Recently viewed books';

  @override
  String get loadRecentSearchedBooksError =>
      'Couldn\'t load recently viewed books.';

  @override
  String get noRecentSearchedBooksYet =>
      'Books you\'ve searched for will show up here.';

  @override
  String get searchBooksMin2Hint => 'Type at least 2 characters to search';

  @override
  String get searchTabKeyword => 'Keyword';

  @override
  String get searchTabSemantic => 'Semantic';

  @override
  String get searchTabDocumentChat => 'Ask my book';

  @override
  String get documentChatPickFile => 'Choose PDF or EPUB';

  @override
  String get documentChatUploading => 'Uploading…';

  @override
  String get documentChatProcessing => 'Processing your book…';

  @override
  String documentChatEmbedProgress(int done, int total) {
    return 'Embedding $done of $total';
  }

  @override
  String get documentChatExtracting => 'Extracting text…';

  @override
  String get documentChatEmptyHint =>
      'Upload a book to ask questions about its content.';

  @override
  String get documentChatSessionExpired =>
      'Your session has expired. Upload the book again.';

  @override
  String get documentChatProcessingFailed => 'Could not process this book.';

  @override
  String get documentChatStillProcessing => 'Still processing — please wait.';

  @override
  String documentChatQuestionsRemaining(int count) {
    return '$count questions left';
  }

  @override
  String get documentChatTruncatedWarning =>
      'Only part of the book was processed. Answers may be incomplete.';

  @override
  String get documentChatUnsupportedFormat =>
      'Only PDF and EPUB files are supported.';

  @override
  String documentChatFileTooLarge(int mb) {
    return 'File exceeds the $mb MB limit.';
  }

  @override
  String get documentChatAskPlaceholder => 'Ask about this book…';

  @override
  String documentChatSourcePage(int page) {
    return 'Page $page';
  }

  @override
  String get documentChatEphemeralNotice =>
      'Chats are temporary and not saved to your account.';

  @override
  String get documentChatSupportedFormats =>
      'Supported: .pdf, .epub (max 20 MB / ~500 PDF pages)';

  @override
  String get documentChatNewFile => 'New file';

  @override
  String get documentChatPages => 'pages';

  @override
  String get documentChatChapters => 'chapters';

  @override
  String documentChatExpiresIn(int minutes) {
    return '$minutes min left';
  }

  @override
  String get semanticSearchHint =>
      'Describe the kind of book you\'re looking for…';

  @override
  String get semanticSearchMinHint =>
      'Describe what you\'re looking for and tap Search';

  @override
  String get semanticFiltersTitle => 'Filters';

  @override
  String get semanticCategoryLabel => 'Category';

  @override
  String get semanticToneLabel => 'Tone';

  @override
  String get semanticApiNotConfigured =>
      'Semantic discovery is not configured.';

  @override
  String get apply => 'Apply';

  @override
  String get semanticModeSimple => 'Quick';

  @override
  String get semanticModeAdvanced => 'Deep';

  @override
  String get semanticModeAdvancedHint =>
      'Rewrites your query and may add new books from Google Books';

  @override
  String get discover => 'Discover';

  @override
  String get noBooksFound => 'No books found';

  @override
  String get searchCouldNotComplete =>
      'Search didn\'t complete. Please try again.';

  @override
  String get continueReading => 'Currently Reading';

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
  String homeGenreEmptySoft(Object genre) {
    return 'Nothing in $genre yet. Pull down to refresh or check back soon.';
  }

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
  String get signInToSeeLists =>
      'Sign in to view and manage your reading lists.';

  @override
  String noBooksInStatus(Object status) {
    return 'No books marked as $status yet.';
  }

  @override
  String get noFavoritesYet =>
      'Save books to your favorites and they\'ll show up here.';

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
  String get noDescriptionAvailable => 'No description yet.';

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
      'We couldn\'t find similar books for this title.';

  @override
  String get couldNotLoadRelatedBooks => 'Couldn\'t load related books.';

  @override
  String get aiSummary => 'AI Summary';

  @override
  String get aiSummaryFailed =>
      'Summary couldn\'t be generated. Try again later.';

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
  String get userReviews => 'App Reviews';

  @override
  String get externalReviews => 'External Reviews';

  @override
  String get writeReviewHint => 'Share your thoughts (at least 10 characters)';

  @override
  String get addReview => 'Add review';

  @override
  String get noUserReviewsYet =>
      'Be the first to share your thoughts on this book.';

  @override
  String reviewUserRating(int rating) {
    return 'Rating: $rating/10';
  }

  @override
  String get reviewInFavorites => 'In favorites';

  @override
  String get relativeTimeJustNow => 'just now';

  @override
  String relativeTimeMinutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String relativeTimeHoursAgo(int count) {
    return '$count hr ago';
  }

  @override
  String relativeTimeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String relativeTimeWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks ago',
      one: '1 week ago',
    );
    return '$_temp0';
  }

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
  String get addMemorableQuote => 'Add a quote you want to remember';

  @override
  String get addQuote => 'Add quote';

  @override
  String get noQuotesYet => 'Saved quotes from this book will appear here.';

  @override
  String get couldNotLoadQuotes => 'Could not load quotes.';

  @override
  String get notes => 'Notes';

  @override
  String get myNotes => 'My Notes';

  @override
  String get myNotesDescription =>
      'Search, filter, and manage your reading notes.';

  @override
  String get signInToSeeNotes => 'Sign in to view and manage your notes.';

  @override
  String get addNote => 'Add note';

  @override
  String get editNote => 'Edit note';

  @override
  String get noteTitleHint => 'Note title';

  @override
  String get noteContentHint => 'Write your note…';

  @override
  String get notePageHint => 'Page (optional)';

  @override
  String get noteChapterHint => 'Chapter (optional)';

  @override
  String get noteTagsHint => 'Tags (comma separated)';

  @override
  String get publicNote => 'Public note';

  @override
  String get publicNoteDescription =>
      'Public notes appear on the book\'s Notes tab for everyone.';

  @override
  String get privateNote => 'Private';

  @override
  String get searchNotesHint => 'Search notes…';

  @override
  String get noPublicNotesYet => 'No public notes yet.';

  @override
  String get noMyNotesYet => 'You haven\'t added any notes yet.';

  @override
  String get noteAdded => 'Note added.';

  @override
  String get noteUpdated => 'Note updated.';

  @override
  String get noteDeleted => 'Note deleted.';

  @override
  String get deleteNoteTitle => 'Delete note?';

  @override
  String get deleteNoteMessage => 'This note will be permanently deleted.';

  @override
  String get allTags => 'All';

  @override
  String notePageLabel(int page) {
    return 'Page $page';
  }

  @override
  String get editReview => 'Edit review';

  @override
  String get save => 'Save';

  @override
  String get log => 'Record';

  @override
  String get signInForHabit =>
      'Sign in to track reading, build streaks, and see your activity calendar.';

  @override
  String get readingLogged => 'Reading logged!';

  @override
  String get readingLoggedOffline =>
      'Saved offline—it\'ll sync when you\'re back online.';

  @override
  String get readingLogsSynced => 'Pending reading logs synced';

  @override
  String couldNotSave(Object error) {
    return 'Couldn\'t save. $error';
  }

  @override
  String get addMinutesOrPagesPrompt =>
      'Enter minutes read or pages finished today.';

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
      'Tip: add books to your Reading list to link them here.';

  @override
  String get bookOptional => 'Book (optional)';

  @override
  String get book => 'Book';

  @override
  String get none => 'None';

  @override
  String booksError(Object error) {
    return 'Couldn\'t load books. $error';
  }

  @override
  String get saveLog => 'Save entry';

  @override
  String get selectReadingBook => 'Choose a book from your Reading list';

  @override
  String get noReadingBooksForLog =>
      'Add books to your Reading list to log progress for a specific title.';

  @override
  String get selectBooksToLog =>
      'Select what you read today and add minutes and/or pages for each.';

  @override
  String get currentlyReadingBooks => 'Currently reading';

  @override
  String get generalReadingLog => 'General reading';

  @override
  String get generalReadingLogHint =>
      'Track reading time without linking to a specific book.';

  @override
  String readingLoggedCount(int count) {
    return '$count reading logs saved';
  }

  @override
  String calendarError(Object error) {
    return 'Couldn\'t load calendar. $error';
  }

  @override
  String get activity => 'Activity';

  @override
  String lastWeeksMoreReading(int weeks) {
    return 'Last $weeks weeks (darker = more reading)';
  }

  @override
  String get noLogsYetTapQuickLog =>
      'No entries yet. Tap Log reading to get started.';

  @override
  String get recentLogs => 'Recent entries';

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
    return 'Couldn\'t load entries. $error';
  }

  @override
  String chartError(Object error) {
    return 'Couldn\'t load chart. $error';
  }

  @override
  String get dailyMinutes14Days => 'Daily minutes (14 days)';

  @override
  String get weeklyMinutes => 'Weekly minutes';

  @override
  String get thisWeekShort => 'This week';

  @override
  String weeksAgoShort(int weeks) {
    return '-${weeks}w';
  }

  @override
  String get totals => 'Totals';

  @override
  String statsError(Object error) {
    return 'Couldn\'t load stats. $error';
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
  String get readingReminderTitle => 'Reading reminder';

  @override
  String get readingReminderBodyNoStreak =>
      'You haven\'t logged reading today. Add a quick entry to build your habit.';

  @override
  String readingReminderBodyWithStreak(int streak) {
    return 'Don\'t lose your $streak-day streak—log your reading before midnight.';
  }

  @override
  String get readingReminderChannelName => 'Reading reminders';

  @override
  String get readingReminderChannelDescription => 'Daily reading reminders';

  @override
  String get signInToSeeStats =>
      'Sign in to explore your reading stats and discover your reading identity.';

  @override
  String get contentYouAdded => 'Content you\'ve added';

  @override
  String get reviewsAndQuotes => 'Reviews and quotes';

  @override
  String get noDataYet => 'Start reading and adding content to see stats here.';

  @override
  String couldNotLoadContentStats(Object error) {
    return 'Could not load content stats: $error';
  }

  @override
  String get yourRatings => 'Your ratings';

  @override
  String get starsGivenToBooks => 'Your star ratings';

  @override
  String couldNotLoadRatings(Object error) {
    return 'Could not load ratings: $error';
  }

  @override
  String get library => 'Library';

  @override
  String get countsFromShelves => 'Books on your shelves';

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
  String get topGenres => 'Favorite genres';

  @override
  String couldNotLoadGenres(Object error) {
    return 'Could not load genres: $error';
  }

  @override
  String get topAuthors => 'Favorite authors';

  @override
  String couldNotLoadAuthors(Object error) {
    return 'Could not load authors: $error';
  }

  @override
  String get author => 'Author';

  @override
  String get noBiographyAvailable => 'No biography available for this author.';

  @override
  String couldNotLoadAuthor(Object error) {
    return 'Could not load author. $error';
  }

  @override
  String get listsForYou => 'For you';

  @override
  String get listsTopTwenty => 'Timeless';

  @override
  String get listsFollowing => 'Following';

  @override
  String get myLists => 'My Lists';

  @override
  String get savedLists => 'Saved Lists';

  @override
  String get createList => 'Create a list';

  @override
  String get editList => 'Edit list';

  @override
  String get title => 'Title';

  @override
  String get description => 'Description';

  @override
  String get public => 'Public';

  @override
  String get bookSelector => 'Add books';

  @override
  String get searchViaGoogleBooks => 'Search via Google Books';

  @override
  String get search => 'Search';

  @override
  String get selectedBooks => 'Selected books';

  @override
  String get noBooksSelectedYet => 'Search and add books to your list.';

  @override
  String get noListsYet =>
      'You haven\'t created any lists yet. Start your first one!';

  @override
  String couldNotLoadLists(Object error) {
    return 'Could not load lists: $error';
  }

  @override
  String byUser(Object userName) {
    return 'by $userName';
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
  String get addCommentHint => 'Write a comment…';

  @override
  String get send => 'Send';

  @override
  String get deleteListTitle => 'Delete list?';

  @override
  String get deleteListConfirm => 'This list will be permanently deleted.';

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

  @override
  String get uxErrorNetwork => 'Check your internet connection.';

  @override
  String get uxErrorTimeout => 'The request timed out.';

  @override
  String get uxErrorUnknown => 'Something went wrong. Please try again.';

  @override
  String get uxErrorBoundaryTitle => 'Unexpected error';

  @override
  String get uxRetry => 'Try again';

  @override
  String get uxOfflineBanner => 'No internet connection';

  @override
  String get uxEmailRequired => 'Email is required';

  @override
  String get uxEmailInvalid => 'Enter a valid email address';

  @override
  String get uxPasswordRequired => 'Password is required';

  @override
  String get uxUserNameRequired => 'Display name is required';

  @override
  String get uxTitleRequired => 'Title is required';

  @override
  String get uxAcceptPrivacyRequired =>
      'Please accept the privacy policy to continue';

  @override
  String get uxListCreatedSuccess => 'List created';

  @override
  String get uxListUpdatedSuccess => 'List saved';

  @override
  String get uxRemoveBookFromListTitle => 'Remove this book?';

  @override
  String get uxRemoveBookFromListMessage =>
      'It will be removed from this list only.';

  @override
  String get uxRemove => 'Remove';

  @override
  String get uxDeleteReviewTitle => 'Delete review?';

  @override
  String get uxDeleteReviewMessage =>
      'This review will be permanently deleted.';

  @override
  String get uxGalleryPluginError =>
      'Gallery could not be opened. Close the app completely and try again.';

  @override
  String get uxProfilePhotoStorageNotReady =>
      'Profile photos aren\'t available yet. Please try again later.';

  @override
  String get uxProfilePhotoPermissionDenied =>
      'Profile photo upload is temporarily unavailable. Please try again later.';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get forgotPasswordTitle => 'Forgot password';

  @override
  String get forgotPasswordPrompt =>
      'Enter your email and we\'ll send an 8-digit code to reset your password.';

  @override
  String get sendResetCode => 'Send code';

  @override
  String get resetCodeSent => 'Check your email for your 8-digit code.';

  @override
  String get resetPasswordTitle => 'Reset password';

  @override
  String resetPasswordPrompt(String email) {
    return 'Enter the code sent to $email.';
  }

  @override
  String get otpCodeLabel => '8-digit verification code';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get updatePassword => 'Update password';

  @override
  String get resendCode => 'Resend code';

  @override
  String get uxOtpIncomplete => 'Please enter the full 8-digit code.';

  @override
  String get uxPasswordMismatch => 'Passwords do not match.';

  @override
  String get passwordResetSuccess => 'Your password was updated successfully.';

  @override
  String get invalidOrExpiredOtp => 'Invalid or expired verification code.';

  @override
  String get uxPasswordTooShort => 'Password must be at least 6 characters.';

  @override
  String get uxPasswordMissingUppercase =>
      'Password must include an uppercase letter.';

  @override
  String get uxPasswordMissingLowercase =>
      'Password must include a lowercase letter.';

  @override
  String get uxPasswordMissingPunctuation =>
      'Password must include a punctuation character.';

  @override
  String get uxMustSignIn => 'Please sign in to continue.';

  @override
  String get uxReviewMinLength => 'Reviews must be at least 10 characters.';

  @override
  String get privacyPolicyAppBar => 'Privacy Policy';

  @override
  String get privacyPolicyTitle => 'Rubricator Privacy Policy';

  @override
  String get privacyPolicyLastUpdated => 'Last updated: 28.07.2026';

  @override
  String get privacyPolicyMeta =>
      'App: Rubricator (Flutter-based, iOS/Android/Web/Desktop)\nDeveloper / Data Controller: İsmail Yücel Ölmez\nContact: support@rubricator.app';

  @override
  String get privacyPolicySection1Title => '1. Introduction';

  @override
  String get privacyPolicySection1Body1 =>
      'Rubricator (\"the app\", \"we\", \"our\") is a mobile/desktop application that offers book discovery, personal reading tracking, book notes/reviews, reading lists, and AI-assisted book features.';

  @override
  String get privacyPolicySection1Body2 =>
      'This Privacy Policy explains which data is collected when you use Rubricator, how that data is used, with whom and why it is shared, how long it is retained, and your rights over your data. The policy was prepared by reviewing the app’s actual technical architecture (including Supabase, a custom API server, and Google Gemini–based AI features).';

  @override
  String get privacyPolicySection1Body3 =>
      'By using the app, you accept the data processing activities described in this policy. If you do not accept the policy, please do not use the app.';

  @override
  String get privacyPolicySection2Title => '2. What Data We Collect';

  @override
  String get privacyPolicySection21Title =>
      '2.1 Information You Provide When Creating an Account';

  @override
  String get privacyPolicySection21Body =>
      'Accounts in Rubricator are created with an email address and password (one-tap third-party sign-in — Google/Apple Sign-In — is not used). Data we collect during registration and authentication:';

  @override
  String get privacyPolicySection21Item1 => '- Your email address';

  @override
  String get privacyPolicySection21Item2 =>
      '- Your password (passwords are not stored on our servers; they are stored securely (hashed) by our authentication provider, Supabase Auth, and are never kept in plain text)';

  @override
  String get privacyPolicySection21Item3 => '- Username / display name';

  @override
  String get privacyPolicySection21Item4 =>
      '- (If applicable) one-time codes (OTP) created during email verification / password reset';

  @override
  String get privacyPolicySection22Title => '2.2 Profile Information';

  @override
  String get privacyPolicySection22Item1 =>
      '- Profile photo (optional; you may upload an image from your gallery; gallery access is requested only when you start an upload)';

  @override
  String get privacyPolicySection22Item2 =>
      '- Other information you choose to show on your profile';

  @override
  String get privacyPolicySection23Title => '2.3 Content You Create in the App';

  @override
  String get privacyPolicySection23Body =>
      'The following content you create while using the app is stored and associated with your account:';

  @override
  String get privacyPolicySection23Item1 =>
      '- Book reviews and ratings (out-of-10 rating system)';

  @override
  String get privacyPolicySection23Item2 => '- Book notes and quotes';

  @override
  String get privacyPolicySection23Item3 =>
      '- Reading lists (social lists) you create and books you add to them';

  @override
  String get privacyPolicySection23Item4 => '- Favorite books';

  @override
  String get privacyPolicySection23Item5 =>
      '- \"Read / reading\" statuses, reading logs, and completed-book records';

  @override
  String get privacyPolicySection23Item6 =>
      '- Likes on reviews, lists, and content';

  @override
  String get privacyPolicySection23Item7 =>
      '- Habit tracker data — e.g. reading goal/streak records';

  @override
  String get privacyPolicySection23Item8 =>
      '- In-app search history (may be kept to improve recommendation quality)';

  @override
  String get privacyPolicySection24Title =>
      '2.4 Data Processed for AI Features';

  @override
  String get privacyPolicySection24Body =>
      'Rubricator offers the following AI-assisted features. Inputs for these features are sent to Google Gemini models (embedding and gemini-2.5-flash):';

  @override
  String get privacyPolicySection24Item1 =>
      '- Semantic Book Discovery (Virgil): Natural-language search queries are sent via our own server (FastAPI) to the Google Gemini API.';

  @override
  String get privacyPolicySection24Item2 =>
      '- Document Chat (PDF/EPUB): Uploaded PDF or EPUB files are temporarily transferred to our server, chunked, vectorized, and sent to Google Gemini. Documents and session data are not stored permanently; they are deleted when the session ends or times out.';

  @override
  String get privacyPolicySection24Item3 =>
      '- Book Chat / Recommendations (Virgil): Questions and recommendations about books are likewise sent to the AI provider. Anonymous usage counters (e.g. daily request counts) may be kept.';

  @override
  String get privacyPolicySection24Note =>
      'Important: Data sent to the AI provider (Google Gemini) is subject to that provider’s own privacy policy and data-processing terms. We advise against uploading documents that contain sensitive personal data to Document Chat.';

  @override
  String get privacyPolicySection25Title =>
      '2.5 Book Catalog Data (Third-Party Sources)';

  @override
  String get privacyPolicySection25Body =>
      'Book search, cover images, descriptions, and author information are fetched from the Google Books API via a proxy on our server. This data belongs to books and does not contain personal data about you.';

  @override
  String get privacyPolicySection26Title =>
      '2.6 Automatically Collected Technical Data';

  @override
  String get privacyPolicySection26Item1 =>
      '- Crash/error reports: We use Sentry to monitor stability. Device/OS info, app version, stack trace, and context are sent; direct identifiers such as name/email are not included by default.';

  @override
  String get privacyPolicySection26Item2 =>
      '- Connectivity status: Checked only on-device; not sent to our servers.';

  @override
  String get privacyPolicySection26Item3 =>
      '- Local notification data: Reading reminders are scheduled entirely on your device; not sent to our servers.';

  @override
  String get privacyPolicySection27Title => '2.7 Device Permissions';

  @override
  String get privacyPolicySection27Body =>
      'Location, camera, contacts, microphone, and similar permissions are not requested. Permissions that may be requested:';

  @override
  String get privacyPolicySection27Item1 =>
      '- Internet access: Communicate with our servers and third-party services';

  @override
  String get privacyPolicySection27Item2 =>
      '- Send notifications: Reading reminders and in-app notifications';

  @override
  String get privacyPolicySection27Item3 =>
      '- Exact alarm / timer: Show reading reminders at the time you set';

  @override
  String get privacyPolicySection27Item4 =>
      '- Gallery / file access: Upload a profile photo; select PDF/EPUB for Document Chat';

  @override
  String get privacyPolicySection3Title => '3. Why We Process Your Data';

  @override
  String get privacyPolicySection3Item1 =>
      '- Create your account, verify your identity, and manage your session securely';

  @override
  String get privacyPolicySection3Item2 =>
      '- Provide core features such as book discovery, search, favorites, lists, notes, and reviews';

  @override
  String get privacyPolicySection3Item3 =>
      '- Run AI-assisted semantic search, book recommendations, and Document Chat';

  @override
  String get privacyPolicySection3Item4 =>
      '- Offer personalized book recommendations';

  @override
  String get privacyPolicySection3Item5 =>
      '- Send reading reminders and habit-tracker notifications';

  @override
  String get privacyPolicySection3Item6 =>
      '- Monitor app performance and detect/fix bugs';

  @override
  String get privacyPolicySection3Item7 =>
      '- Prevent abuse and enforce service quotas';

  @override
  String get privacyPolicySection3Item8 =>
      '- Comply with legal obligations and protect user safety';

  @override
  String get privacyPolicySection3Body =>
      'Your data is processed on the legal bases of consent (e.g. choosing to use AI features), performance of a contract (providing your account and the service), and legitimate interest (security, bug fixing, service improvement).';

  @override
  String get privacyPolicySection4Title =>
      '4. Where Data Is Stored and Security';

  @override
  String get privacyPolicySection4Body =>
      'Your data is hosted on: Supabase (database, authentication, file storage); our API server (FastAPI — semantic search and Document Chat; document sessions are temporary); Google Gemini API; Sentry (error reports).';

  @override
  String get privacyPolicySection4Item1 =>
      '- All communication uses encrypted connections (HTTPS/TLS)';

  @override
  String get privacyPolicySection4Item2 =>
      '- Passwords are never stored in plain text';

  @override
  String get privacyPolicySection4Item3 =>
      '- Database access is scoped to the account owner via Row Level Security (RLS)';

  @override
  String get privacyPolicySection4Item4 =>
      '- Server-side authorization and access control are applied';

  @override
  String get privacyPolicySection4Body2 =>
      'No internet-based system can be guaranteed 100% secure; however, we take reasonable technical and organizational measures to protect your data.';

  @override
  String get privacyPolicySection5Title => '5. Data Sharing';

  @override
  String get privacyPolicySection5Body =>
      'We do not sell your personal data. Your data is shared only in the following cases and with the following parties:';

  @override
  String get privacyPolicySection5Item1 =>
      '- Supabase: Account, profile, user content — hosting, authentication, file storage';

  @override
  String get privacyPolicySection5Item2 =>
      '- Google Gemini: Your search queries, document contents, chat messages — AI features';

  @override
  String get privacyPolicySection5Item3 =>
      '- Google Books API: Book search terms — catalog data (does not contain personal data)';

  @override
  String get privacyPolicySection5Item4 =>
      '- Sentry: Device/app technical info, error traces — stability monitoring';

  @override
  String get privacyPolicySection5Body2 =>
      'Data may also be shared to comply with legal obligations, court orders, or official requests; to protect user/app safety; or in a merger, acquisition, or asset sale (you will be notified in advance).';

  @override
  String get privacyPolicySection6Title => '6. Public Content';

  @override
  String get privacyPolicySection6Body =>
      'Some content may be visible to other users (and in some cases to visitors who are not signed in), by default or according to your preference:';

  @override
  String get privacyPolicySection6Item1 => '- Reading lists you share publicly';

  @override
  String get privacyPolicySection6Item2 =>
      '- Your book reviews, ratings, notes, and quotes (shown with your username)';

  @override
  String get privacyPolicySection6Item3 => '- Likes you give or receive';

  @override
  String get privacyPolicySection6Body2 =>
      'Even if you delete public content, it may already have been viewed, copied, or shared by others; we have no control over such secondary sharing.';

  @override
  String get privacyPolicySection7Title => '7. Data Retention Periods';

  @override
  String get privacyPolicySection7Item1 =>
      '- Account and content data are retained while your account is active.';

  @override
  String get privacyPolicySection7Item2 =>
      '- Document Chat files and session data are automatically deleted when processing/session ends; not stored permanently.';

  @override
  String get privacyPolicySection7Item3 =>
      '- After an account deletion request is verified, data is deleted within 7 days; some data may be retained up to 30 more days for legal obligations.';

  @override
  String get privacyPolicySection7Item4 =>
      '- Crash/error reports are subject to Sentry’s retention policy.';

  @override
  String get privacyPolicySection8Title => '8. Your Rights';

  @override
  String get privacyPolicySection8Body =>
      'Under KVKK and/or GDPR, to the extent applicable, you have the right to:';

  @override
  String get privacyPolicySection8Item1 =>
      '- Learn whether your personal data is being processed';

  @override
  String get privacyPolicySection8Item2 =>
      '- Request information about your processed data';

  @override
  String get privacyPolicySection8Item3 =>
      '- Access your data and obtain a copy (in a portable format)';

  @override
  String get privacyPolicySection8Item4 =>
      '- Request correction of inaccurate or incomplete data';

  @override
  String get privacyPolicySection8Item5 =>
      '- Request deletion or destruction of your data';

  @override
  String get privacyPolicySection8Item6 =>
      '- Object to processing or withdraw consent';

  @override
  String get privacyPolicySection8Item7 =>
      '- Object to adverse outcomes produced solely by automated systems';

  @override
  String get privacyPolicySection8Item8 =>
      '- Seek redress if you suffer damage due to unlawful processing';

  @override
  String get privacyPolicySection8Body2 =>
      'To exercise these rights, contact us at support@rubricator.app.';

  @override
  String get privacyPolicySection9Title => '9. Account and Data Deletion';

  @override
  String get privacyPolicySection9Body1 =>
      'To delete your account and associated data:';

  @override
  String get privacyPolicySection9Item1 => '1. Email support@rubricator.app.';

  @override
  String get privacyPolicySection9Item2 =>
      '2. Use the subject line \"Account Deletion Request\".';

  @override
  String get privacyPolicySection9Item3 =>
      '3. Include the email address registered with Rubricator in the message body.';

  @override
  String get privacyPolicySection9Body2 =>
      'After your request is verified, your account profile and personal data are deleted within 7 days; limited data required for legal retention may be kept for up to 30 additional days.';

  @override
  String get privacyPolicySection10Title => '10. Children’s Privacy';

  @override
  String get privacyPolicySection10Body =>
      'Rubricator is not directed at children under 13 and does not knowingly collect data from that age group. If we learn that a child under 13 has provided us personal data, we will delete it within a reasonable time. If you are a parent or guardian and believe your child has provided us data, please contact us at support@rubricator.app.';

  @override
  String get privacyPolicySection11Title =>
      '11. Local Storage (Data Stored on Device)';

  @override
  String get privacyPolicySection11Body =>
      'The app stores some preferences and cache data (e.g. session info, theme preference, temporary content cache) locally on your device. This data is removed when you uninstall the app and is not automatically sent to our servers.';

  @override
  String get privacyPolicySection12Title => '12. International Data Transfers';

  @override
  String get privacyPolicySection12Body =>
      'Our infrastructure providers (Supabase, Google, Sentry) may process your data on servers outside Türkiye (e.g. the European Union or the United States). For such transfers, we rely on the security and compliance mechanisms offered by those providers (standard contractual clauses, data processing agreements, etc.).';

  @override
  String get privacyPolicySection13Title =>
      '13. Third-Party Services and Links';

  @override
  String get privacyPolicySection13Body =>
      'The app may contain links to third-party websites or resources. Those third-party sites have their own privacy policies; this policy covers only Rubricator’s own data processing.';

  @override
  String get privacyPolicySection13Item1 =>
      '- Supabase Privacy Policy: https://supabase.com/privacy';

  @override
  String get privacyPolicySection13Item2 =>
      '- Google Privacy Policy: https://policies.google.com/privacy (Gemini API and Google Books API)';

  @override
  String get privacyPolicySection13Item3 =>
      '- Sentry Privacy Policy: https://sentry.io/privacy/';

  @override
  String get privacyPolicySection14Title => '14. Changes to This Policy';

  @override
  String get privacyPolicySection14Body =>
      'We may update this Privacy Policy from time to time. For material changes, we may notify you via an in-app notice or email. The current policy is always published with the \"Last updated\" date at the top of this page. We recommend reviewing the policy regularly.';

  @override
  String get privacyPolicySection15Title => '15. Contact';

  @override
  String get privacyPolicySection15Body =>
      'For questions, requests, or complaints about this Privacy Policy or the processing of your personal data:';

  @override
  String get privacyPolicySection15Contact =>
      'Rubricator\nEmail: support@rubricator.app\nDeveloper: İsmail Yücel Ölmez';

  @override
  String get privacyPolicyFooter =>
      'By using Rubricator, you agree to this Privacy Policy.';
}
