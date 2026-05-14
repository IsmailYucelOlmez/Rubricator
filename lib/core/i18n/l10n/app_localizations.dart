import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Rubricator'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navLists.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get navLists;

  /// No description provided for @listsFeedHeading.
  ///
  /// In en, this message translates to:
  /// **'Listbox'**
  String get listsFeedHeading;

  /// No description provided for @profileZoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Zone'**
  String get profileZoneTitle;

  /// No description provided for @readingStatsListsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your reading lists by status'**
  String get readingStatsListsTitle;

  /// No description provided for @homeShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get homeShowAll;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @pickPhotoFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose photo from gallery'**
  String get pickPhotoFromGallery;

  /// No description provided for @pickProfilePhotoFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose profile photo from gallery'**
  String get pickProfilePhotoFromGallery;

  /// No description provided for @changeProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get changeProfilePhoto;

  /// No description provided for @removeProfilePhotoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removeProfilePhotoTooltip;

  /// No description provided for @privacyPolicyCheckbox.
  ///
  /// In en, this message translates to:
  /// **'I have read and accept the privacy policy.'**
  String get privacyPolicyCheckbox;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayNameLabel;

  /// No description provided for @profilePhotoUrlOptional.
  ///
  /// In en, this message translates to:
  /// **'Profile photo URL (optional)'**
  String get profilePhotoUrlOptional;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @themeAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get themeAppearance;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @turkish.
  ///
  /// In en, this message translates to:
  /// **'Turkish'**
  String get turkish;

  /// No description provided for @signInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync favorites across devices.'**
  String get signInPrompt;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @signedInFallback.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get signedInFallback;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @loadSessionError.
  ///
  /// In en, this message translates to:
  /// **'Could not load session: {error}'**
  String loadSessionError(Object error);

  /// No description provided for @invalidEmailOrPassword.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get invalidEmailOrPassword;

  /// No description provided for @accountAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists.'**
  String get accountAlreadyExists;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordMin6.
  ///
  /// In en, this message translates to:
  /// **'Password (min 6 characters)'**
  String get passwordMin6;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @confirmAccountEmailNotice.
  ///
  /// In en, this message translates to:
  /// **'Check your email to confirm your account if required.'**
  String get confirmAccountEmailNotice;

  /// No description provided for @readingHabit.
  ///
  /// In en, this message translates to:
  /// **'Reading habit'**
  String get readingHabit;

  /// No description provided for @readingLoggedToday.
  ///
  /// In en, this message translates to:
  /// **'You logged reading today. Nice work.'**
  String get readingLoggedToday;

  /// No description provided for @didYouReadToday.
  ///
  /// In en, this message translates to:
  /// **'Did you read today?'**
  String get didYouReadToday;

  /// No description provided for @todayStatusError.
  ///
  /// In en, this message translates to:
  /// **'Today status: {error}'**
  String todayStatusError(Object error);

  /// No description provided for @quickLog.
  ///
  /// In en, this message translates to:
  /// **'Quick log'**
  String get quickLog;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @readingStats.
  ///
  /// In en, this message translates to:
  /// **'Reading stats'**
  String get readingStats;

  /// No description provided for @booksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} books'**
  String booksCount(Object count);

  /// No description provided for @averageShort.
  ///
  /// In en, this message translates to:
  /// **'{avg} avg'**
  String averageShort(Object avg);

  /// No description provided for @noRatingsYet.
  ///
  /// In en, this message translates to:
  /// **'No ratings yet'**
  String get noRatingsYet;

  /// No description provided for @topGenre.
  ///
  /// In en, this message translates to:
  /// **'Top: {genre}'**
  String topGenre(Object genre);

  /// No description provided for @viewAllStats.
  ///
  /// In en, this message translates to:
  /// **'View all stats'**
  String get viewAllStats;

  /// No description provided for @loadStatsError.
  ///
  /// In en, this message translates to:
  /// **'Could not load stats: {error}'**
  String loadStatsError(Object error);

  /// No description provided for @searchBooksTitle.
  ///
  /// In en, this message translates to:
  /// **'Search Books'**
  String get searchBooksTitle;

  /// No description provided for @searchByTitleOrAuthorHint.
  ///
  /// In en, this message translates to:
  /// **'Search by title or author (min. 2 characters)'**
  String get searchByTitleOrAuthorHint;

  /// No description provided for @noBooksFoundFor.
  ///
  /// In en, this message translates to:
  /// **'No books found for \"{query}\".'**
  String noBooksFoundFor(Object query);

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get recentSearches;

  /// No description provided for @loadRecentSearchesError.
  ///
  /// In en, this message translates to:
  /// **'Could not load recent searches.'**
  String get loadRecentSearchesError;

  /// No description provided for @noRecentSearchesYet.
  ///
  /// In en, this message translates to:
  /// **'No recent searches yet.'**
  String get noRecentSearchesYet;

  /// No description provided for @recentSearchedBooks.
  ///
  /// In en, this message translates to:
  /// **'Recent Searched Books'**
  String get recentSearchedBooks;

  /// No description provided for @loadRecentSearchedBooksError.
  ///
  /// In en, this message translates to:
  /// **'Could not load recent searched books.'**
  String get loadRecentSearchedBooksError;

  /// No description provided for @noRecentSearchedBooksYet.
  ///
  /// In en, this message translates to:
  /// **'No recent searched books yet.'**
  String get noRecentSearchedBooksYet;

  /// No description provided for @searchBooksMin2Hint.
  ///
  /// In en, this message translates to:
  /// **'Search books (min. 2 characters)'**
  String get searchBooksMin2Hint;

  /// No description provided for @discover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discover;

  /// No description provided for @noBooksFound.
  ///
  /// In en, this message translates to:
  /// **'No books found'**
  String get noBooksFound;

  /// No description provided for @searchCouldNotComplete.
  ///
  /// In en, this message translates to:
  /// **'Could not complete the search. Please try again.'**
  String get searchCouldNotComplete;

  /// No description provided for @popular.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// No description provided for @loadPopularBooksError.
  ///
  /// In en, this message translates to:
  /// **'Could not load popular books.'**
  String get loadPopularBooksError;

  /// No description provided for @loadGenreBooksError.
  ///
  /// In en, this message translates to:
  /// **'Could not load {genre} books.'**
  String loadGenreBooksError(Object genre);

  /// No description provided for @genreFantasy.
  ///
  /// In en, this message translates to:
  /// **'Fantasy'**
  String get genreFantasy;

  /// No description provided for @genreScienceFiction.
  ///
  /// In en, this message translates to:
  /// **'Science Fiction'**
  String get genreScienceFiction;

  /// No description provided for @genreRomance.
  ///
  /// In en, this message translates to:
  /// **'Romance'**
  String get genreRomance;

  /// No description provided for @genreMystery.
  ///
  /// In en, this message translates to:
  /// **'Mystery'**
  String get genreMystery;

  /// No description provided for @genreThriller.
  ///
  /// In en, this message translates to:
  /// **'Thriller'**
  String get genreThriller;

  /// No description provided for @genreHorror.
  ///
  /// In en, this message translates to:
  /// **'Horror'**
  String get genreHorror;

  /// No description provided for @loadHomeGenresError.
  ///
  /// In en, this message translates to:
  /// **'Could not load genre sections. Please try again.'**
  String get loadHomeGenresError;

  /// No description provided for @homeGenreEmptySoft.
  ///
  /// In en, this message translates to:
  /// **'No picks for {genre} yet. Pull to refresh or try later.'**
  String homeGenreEmptySoft(Object genre);

  /// No description provided for @toRead.
  ///
  /// In en, this message translates to:
  /// **'To Read'**
  String get toRead;

  /// No description provided for @reading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get reading;

  /// No description provided for @reReading.
  ///
  /// In en, this message translates to:
  /// **'Re-reading'**
  String get reReading;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @dropped.
  ///
  /// In en, this message translates to:
  /// **'Dropped'**
  String get dropped;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavorites;

  /// No description provided for @removeFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get removeFromFavorites;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @signInToSeeLists.
  ///
  /// In en, this message translates to:
  /// **'Sign in from Profile to see your lists.'**
  String get signInToSeeLists;

  /// No description provided for @noBooksInStatus.
  ///
  /// In en, this message translates to:
  /// **'No books in {status}.'**
  String noBooksInStatus(Object status);

  /// No description provided for @noFavoritesYet.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet.'**
  String get noFavoritesYet;

  /// No description provided for @couldNotLoadList.
  ///
  /// In en, this message translates to:
  /// **'Could not load list: {error}'**
  String couldNotLoadList(Object error);

  /// No description provided for @bookDetails.
  ///
  /// In en, this message translates to:
  /// **'Book Details'**
  String get bookDetails;

  /// No description provided for @authorProfile.
  ///
  /// In en, this message translates to:
  /// **'Author profile'**
  String get authorProfile;

  /// No description provided for @ratingSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Rating submitted.'**
  String get ratingSubmitted;

  /// No description provided for @noDescriptionAvailable.
  ///
  /// In en, this message translates to:
  /// **'No description available.'**
  String get noDescriptionAvailable;

  /// No description provided for @reviewAdded.
  ///
  /// In en, this message translates to:
  /// **'Review added.'**
  String get reviewAdded;

  /// No description provided for @reviewUpdated.
  ///
  /// In en, this message translates to:
  /// **'Review updated.'**
  String get reviewUpdated;

  /// No description provided for @reviewDeleted.
  ///
  /// In en, this message translates to:
  /// **'Review deleted.'**
  String get reviewDeleted;

  /// No description provided for @externalReviewAdded.
  ///
  /// In en, this message translates to:
  /// **'External review added.'**
  String get externalReviewAdded;

  /// No description provided for @invalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL'**
  String get invalidUrl;

  /// No description provided for @couldNotOpenBrowser.
  ///
  /// In en, this message translates to:
  /// **'Could not open browser.'**
  String get couldNotOpenBrowser;

  /// No description provided for @quoteAdded.
  ///
  /// In en, this message translates to:
  /// **'Quote added.'**
  String get quoteAdded;

  /// No description provided for @relatedBooks.
  ///
  /// In en, this message translates to:
  /// **'Related books'**
  String get relatedBooks;

  /// No description provided for @noRelatedTitlesFound.
  ///
  /// In en, this message translates to:
  /// **'No related titles found (subjects missing or empty results).'**
  String get noRelatedTitlesFound;

  /// No description provided for @couldNotLoadRelatedBooks.
  ///
  /// In en, this message translates to:
  /// **'Could not load related books.'**
  String get couldNotLoadRelatedBooks;

  /// No description provided for @aiSummary.
  ///
  /// In en, this message translates to:
  /// **'AI Summary'**
  String get aiSummary;

  /// No description provided for @aiSummaryFailed.
  ///
  /// In en, this message translates to:
  /// **'AI summary failed'**
  String get aiSummaryFailed;

  /// No description provided for @couldNotLoadThisBook.
  ///
  /// In en, this message translates to:
  /// **'Could not load this book. {error}'**
  String couldNotLoadThisBook(Object error);

  /// No description provided for @addToList.
  ///
  /// In en, this message translates to:
  /// **'Add to List'**
  String get addToList;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @progressPercent.
  ///
  /// In en, this message translates to:
  /// **'Progress: {progress}%'**
  String progressPercent(Object progress);

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @averageOutOfFive.
  ///
  /// In en, this message translates to:
  /// **'Average: {avg} / 5'**
  String averageOutOfFive(Object avg);

  /// No description provided for @couldNotLoadRating.
  ///
  /// In en, this message translates to:
  /// **'Could not load rating.'**
  String get couldNotLoadRating;

  /// No description provided for @submitRating.
  ///
  /// In en, this message translates to:
  /// **'Submit rating'**
  String get submitRating;

  /// No description provided for @reviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get reviews;

  /// No description provided for @userReviews.
  ///
  /// In en, this message translates to:
  /// **'User Reviews'**
  String get userReviews;

  /// No description provided for @externalReviews.
  ///
  /// In en, this message translates to:
  /// **'External Reviews'**
  String get externalReviews;

  /// No description provided for @writeReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Write your review (min 10 chars)'**
  String get writeReviewHint;

  /// No description provided for @addReview.
  ///
  /// In en, this message translates to:
  /// **'Add review'**
  String get addReview;

  /// No description provided for @noUserReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No user reviews yet.'**
  String get noUserReviewsYet;

  /// No description provided for @couldNotLoadReviews.
  ///
  /// In en, this message translates to:
  /// **'Could not load reviews.'**
  String get couldNotLoadReviews;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review title'**
  String get reviewTitle;

  /// No description provided for @reviewUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://example.com/review'**
  String get reviewUrlHint;

  /// No description provided for @addExternalReview.
  ///
  /// In en, this message translates to:
  /// **'Add external review'**
  String get addExternalReview;

  /// No description provided for @noExternalReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No external reviews yet.'**
  String get noExternalReviewsYet;

  /// No description provided for @couldNotLoadExternalReviews.
  ///
  /// In en, this message translates to:
  /// **'Could not load external reviews.'**
  String get couldNotLoadExternalReviews;

  /// No description provided for @quotes.
  ///
  /// In en, this message translates to:
  /// **'Quotes'**
  String get quotes;

  /// No description provided for @addMemorableQuote.
  ///
  /// In en, this message translates to:
  /// **'Add a memorable quote'**
  String get addMemorableQuote;

  /// No description provided for @addQuote.
  ///
  /// In en, this message translates to:
  /// **'Add quote'**
  String get addQuote;

  /// No description provided for @noQuotesYet.
  ///
  /// In en, this message translates to:
  /// **'No quotes yet.'**
  String get noQuotesYet;

  /// No description provided for @couldNotLoadQuotes.
  ///
  /// In en, this message translates to:
  /// **'Could not load quotes.'**
  String get couldNotLoadQuotes;

  /// No description provided for @editReview.
  ///
  /// In en, this message translates to:
  /// **'Edit review'**
  String get editReview;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @log.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get log;

  /// No description provided for @signInForHabit.
  ///
  /// In en, this message translates to:
  /// **'Sign in to log reading, see streaks, and view your activity calendar.'**
  String get signInForHabit;

  /// No description provided for @readingLogged.
  ///
  /// In en, this message translates to:
  /// **'Reading logged'**
  String get readingLogged;

  /// No description provided for @couldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {error}'**
  String couldNotSave(Object error);

  /// No description provided for @addMinutesOrPagesPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add at least minutes or pages from today.'**
  String get addMinutesOrPagesPrompt;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutes;

  /// No description provided for @plusTenMin.
  ///
  /// In en, this message translates to:
  /// **'+10 min'**
  String get plusTenMin;

  /// No description provided for @pages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get pages;

  /// No description provided for @plusFivePages.
  ///
  /// In en, this message translates to:
  /// **'+5 pages'**
  String get plusFivePages;

  /// No description provided for @optionalAddBooksPrompt.
  ///
  /// In en, this message translates to:
  /// **'Optional: add books to your reading list to pick one here.'**
  String get optionalAddBooksPrompt;

  /// No description provided for @bookOptional.
  ///
  /// In en, this message translates to:
  /// **'Book (optional)'**
  String get bookOptional;

  /// No description provided for @book.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get book;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @booksError.
  ///
  /// In en, this message translates to:
  /// **'Books: {error}'**
  String booksError(Object error);

  /// No description provided for @saveLog.
  ///
  /// In en, this message translates to:
  /// **'Save log'**
  String get saveLog;

  /// No description provided for @calendarError.
  ///
  /// In en, this message translates to:
  /// **'Calendar error: {error}'**
  String calendarError(Object error);

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @lastWeeksMoreReading.
  ///
  /// In en, this message translates to:
  /// **'Last {weeks} weeks (darker = more reading)'**
  String lastWeeksMoreReading(int weeks);

  /// No description provided for @noLogsYetTapQuickLog.
  ///
  /// In en, this message translates to:
  /// **'No logs yet - tap Quick log to start.'**
  String get noLogsYetTapQuickLog;

  /// No description provided for @recentLogs.
  ///
  /// In en, this message translates to:
  /// **'Recent logs'**
  String get recentLogs;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutesShort(int count);

  /// No description provided for @pagesShort.
  ///
  /// In en, this message translates to:
  /// **'{count} pages'**
  String pagesShort(int count);

  /// No description provided for @bookIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Book: {bookId}'**
  String bookIdLabel(Object bookId);

  /// No description provided for @logsError.
  ///
  /// In en, this message translates to:
  /// **'Logs error: {error}'**
  String logsError(Object error);

  /// No description provided for @chartError.
  ///
  /// In en, this message translates to:
  /// **'Chart error: {error}'**
  String chartError(Object error);

  /// No description provided for @dailyMinutes14Days.
  ///
  /// In en, this message translates to:
  /// **'Daily minutes (14 days)'**
  String get dailyMinutes14Days;

  /// No description provided for @weeklyMinutes.
  ///
  /// In en, this message translates to:
  /// **'Weekly minutes'**
  String get weeklyMinutes;

  /// No description provided for @thisWeekShort.
  ///
  /// In en, this message translates to:
  /// **'This wk'**
  String get thisWeekShort;

  /// No description provided for @weeksAgoShort.
  ///
  /// In en, this message translates to:
  /// **'-{weeks}w'**
  String weeksAgoShort(int weeks);

  /// No description provided for @totals.
  ///
  /// In en, this message translates to:
  /// **'Totals'**
  String get totals;

  /// No description provided for @statsError.
  ///
  /// In en, this message translates to:
  /// **'Stats error: {error}'**
  String statsError(Object error);

  /// No description provided for @dayStreak.
  ///
  /// In en, this message translates to:
  /// **'{days} day streak'**
  String dayStreak(int days);

  /// No description provided for @currentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get currentStreak;

  /// No description provided for @daysCount.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String daysCount(int days);

  /// No description provided for @longestDays.
  ///
  /// In en, this message translates to:
  /// **'Longest: {days} days'**
  String longestDays(int days);

  /// No description provided for @couldNotLoadStreak.
  ///
  /// In en, this message translates to:
  /// **'Could not load streak: {error}'**
  String couldNotLoadStreak(Object error);

  /// No description provided for @signInToSeeStats.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your library analytics and reading identity.'**
  String get signInToSeeStats;

  /// No description provided for @contentYouAdded.
  ///
  /// In en, this message translates to:
  /// **'Content you added'**
  String get contentYouAdded;

  /// No description provided for @reviewsAndQuotes.
  ///
  /// In en, this message translates to:
  /// **'Reviews and quotes'**
  String get reviewsAndQuotes;

  /// No description provided for @noDataYet.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get noDataYet;

  /// No description provided for @couldNotLoadContentStats.
  ///
  /// In en, this message translates to:
  /// **'Could not load content stats: {error}'**
  String couldNotLoadContentStats(Object error);

  /// No description provided for @yourRatings.
  ///
  /// In en, this message translates to:
  /// **'Your ratings'**
  String get yourRatings;

  /// No description provided for @starsGivenToBooks.
  ///
  /// In en, this message translates to:
  /// **'Stars you gave to books'**
  String get starsGivenToBooks;

  /// No description provided for @couldNotLoadRatings.
  ///
  /// In en, this message translates to:
  /// **'Could not load ratings: {error}'**
  String couldNotLoadRatings(Object error);

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @countsFromShelves.
  ///
  /// In en, this message translates to:
  /// **'Counts from your shelves'**
  String get countsFromShelves;

  /// No description provided for @couldNotLoadLibraryStats.
  ///
  /// In en, this message translates to:
  /// **'Could not load library stats: {error}'**
  String couldNotLoadLibraryStats(Object error);

  /// No description provided for @readingIdentity.
  ///
  /// In en, this message translates to:
  /// **'Reading identity'**
  String get readingIdentity;

  /// No description provided for @genresAndAuthorsFromCompleted.
  ///
  /// In en, this message translates to:
  /// **'Genres and authors from completed books'**
  String get genresAndAuthorsFromCompleted;

  /// No description provided for @topGenres.
  ///
  /// In en, this message translates to:
  /// **'Top genres'**
  String get topGenres;

  /// No description provided for @couldNotLoadGenres.
  ///
  /// In en, this message translates to:
  /// **'Could not load genres: {error}'**
  String couldNotLoadGenres(Object error);

  /// No description provided for @topAuthors.
  ///
  /// In en, this message translates to:
  /// **'Top authors'**
  String get topAuthors;

  /// No description provided for @couldNotLoadAuthors.
  ///
  /// In en, this message translates to:
  /// **'Could not load authors: {error}'**
  String couldNotLoadAuthors(Object error);

  /// No description provided for @author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get author;

  /// No description provided for @noBiographyAvailable.
  ///
  /// In en, this message translates to:
  /// **'No biography available.'**
  String get noBiographyAvailable;

  /// No description provided for @couldNotLoadAuthor.
  ///
  /// In en, this message translates to:
  /// **'Could not load author. {error}'**
  String couldNotLoadAuthor(Object error);

  /// No description provided for @listsForYou.
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get listsForYou;

  /// No description provided for @listsTopTwenty.
  ///
  /// In en, this message translates to:
  /// **'Timeless'**
  String get listsTopTwenty;

  /// No description provided for @listsFollowing.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get listsFollowing;

  /// No description provided for @myLists.
  ///
  /// In en, this message translates to:
  /// **'My Lists'**
  String get myLists;

  /// No description provided for @savedLists.
  ///
  /// In en, this message translates to:
  /// **'Saved Lists'**
  String get savedLists;

  /// No description provided for @createList.
  ///
  /// In en, this message translates to:
  /// **'Create list'**
  String get createList;

  /// No description provided for @editList.
  ///
  /// In en, this message translates to:
  /// **'Edit list'**
  String get editList;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @public.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get public;

  /// No description provided for @bookSelector.
  ///
  /// In en, this message translates to:
  /// **'Book selector'**
  String get bookSelector;

  /// No description provided for @searchViaGoogleBooks.
  ///
  /// In en, this message translates to:
  /// **'Search via Google Books'**
  String get searchViaGoogleBooks;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @selectedBooks.
  ///
  /// In en, this message translates to:
  /// **'Selected books'**
  String get selectedBooks;

  /// No description provided for @noBooksSelectedYet.
  ///
  /// In en, this message translates to:
  /// **'No books selected yet.'**
  String get noBooksSelectedYet;

  /// No description provided for @noListsYet.
  ///
  /// In en, this message translates to:
  /// **'No lists yet.'**
  String get noListsYet;

  /// No description provided for @couldNotLoadLists.
  ///
  /// In en, this message translates to:
  /// **'Could not load lists: {error}'**
  String couldNotLoadLists(Object error);

  /// No description provided for @byUser.
  ///
  /// In en, this message translates to:
  /// **'by {userName}'**
  String byUser(Object userName);

  /// No description provided for @books.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get books;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @couldNotLoadListItems.
  ///
  /// In en, this message translates to:
  /// **'Could not load list items: {error}'**
  String couldNotLoadListItems(Object error);

  /// No description provided for @couldNotLoadComments.
  ///
  /// In en, this message translates to:
  /// **'Could not load comments: {error}'**
  String couldNotLoadComments(Object error);

  /// No description provided for @addCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get addCommentHint;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @deleteListTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete list?'**
  String get deleteListTitle;

  /// No description provided for @deleteListConfirm.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteListConfirm;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @couldNotSaveList.
  ///
  /// In en, this message translates to:
  /// **'Could not save list: {error}'**
  String couldNotSaveList(Object error);

  /// No description provided for @commentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} comments'**
  String commentsCount(int count);

  /// No description provided for @stats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get stats;

  /// No description provided for @myListsTooltip.
  ///
  /// In en, this message translates to:
  /// **'My lists'**
  String get myListsTooltip;

  /// No description provided for @editListTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit list'**
  String get editListTooltip;

  /// No description provided for @deleteListTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete list'**
  String get deleteListTooltip;

  /// No description provided for @uxErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection.'**
  String get uxErrorNetwork;

  /// No description provided for @uxErrorTimeout.
  ///
  /// In en, this message translates to:
  /// **'The request timed out.'**
  String get uxErrorTimeout;

  /// No description provided for @uxErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get uxErrorUnknown;

  /// No description provided for @uxRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get uxRetry;

  /// No description provided for @uxOfflineBanner.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get uxOfflineBanner;

  /// No description provided for @uxEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get uxEmailRequired;

  /// No description provided for @uxEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get uxEmailInvalid;

  /// No description provided for @uxPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get uxPasswordRequired;

  /// No description provided for @uxUserNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Display name is required'**
  String get uxUserNameRequired;

  /// No description provided for @uxTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get uxTitleRequired;

  /// No description provided for @uxAcceptPrivacyRequired.
  ///
  /// In en, this message translates to:
  /// **'Please accept the privacy policy to continue'**
  String get uxAcceptPrivacyRequired;

  /// No description provided for @uxListCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'List created successfully'**
  String get uxListCreatedSuccess;

  /// No description provided for @uxListUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'List updated successfully'**
  String get uxListUpdatedSuccess;

  /// No description provided for @uxRemoveBookFromListTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this book?'**
  String get uxRemoveBookFromListTitle;

  /// No description provided for @uxRemoveBookFromListMessage.
  ///
  /// In en, this message translates to:
  /// **'It will be removed from this list.'**
  String get uxRemoveBookFromListMessage;

  /// No description provided for @uxRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get uxRemove;

  /// No description provided for @uxDeleteReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete review?'**
  String get uxDeleteReviewTitle;

  /// No description provided for @uxDeleteReviewMessage.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get uxDeleteReviewMessage;

  /// No description provided for @uxGalleryPluginError.
  ///
  /// In en, this message translates to:
  /// **'Gallery could not be opened. Close the app completely and try again.'**
  String get uxGalleryPluginError;

  /// No description provided for @uxProfilePhotoStorageNotReady.
  ///
  /// In en, this message translates to:
  /// **'Profile photo storage is not ready yet. Ask the admin to run database migrations.'**
  String get uxProfilePhotoStorageNotReady;

  /// No description provided for @uxProfilePhotoPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Profile photo upload is blocked by permissions. Apply the Supabase storage policy migration.'**
  String get uxProfilePhotoPermissionDenied;

  /// No description provided for @uxMustSignIn.
  ///
  /// In en, this message translates to:
  /// **'Please sign in to continue.'**
  String get uxMustSignIn;

  /// No description provided for @uxReviewMinLength.
  ///
  /// In en, this message translates to:
  /// **'Reviews must be at least 10 characters.'**
  String get uxReviewMinLength;

  /// No description provided for @privacyPolicyAppBar.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyAppBar;

  /// No description provided for @privacyPolicyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy for Rubricator'**
  String get privacyPolicyTitle;

  /// No description provided for @privacyPolicyLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: 19.04.2026'**
  String get privacyPolicyLastUpdated;

  /// No description provided for @privacyPolicySection1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Introduction'**
  String get privacyPolicySection1Title;

  /// No description provided for @privacyPolicySection1Body1.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Rubricator (\"we\", \"our\", or \"us\"). Rubricator is a social reading platform where users can discover books, create lists, track reading habits, and share content.'**
  String get privacyPolicySection1Body1;

  /// No description provided for @privacyPolicySection1Body2.
  ///
  /// In en, this message translates to:
  /// **'This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.'**
  String get privacyPolicySection1Body2;

  /// No description provided for @privacyPolicySection2Title.
  ///
  /// In en, this message translates to:
  /// **'2. Information We Collect'**
  String get privacyPolicySection2Title;

  /// No description provided for @privacyPolicySection21Title.
  ///
  /// In en, this message translates to:
  /// **'2.1 Personal Information'**
  String get privacyPolicySection21Title;

  /// No description provided for @privacyPolicySection21Item1.
  ///
  /// In en, this message translates to:
  /// **'- Email address'**
  String get privacyPolicySection21Item1;

  /// No description provided for @privacyPolicySection21Item2.
  ///
  /// In en, this message translates to:
  /// **'- Username'**
  String get privacyPolicySection21Item2;

  /// No description provided for @privacyPolicySection21Item3.
  ///
  /// In en, this message translates to:
  /// **'- Profile information (optional)'**
  String get privacyPolicySection21Item3;

  /// No description provided for @privacyPolicySection22Title.
  ///
  /// In en, this message translates to:
  /// **'2.2 User-Generated Content'**
  String get privacyPolicySection22Title;

  /// No description provided for @privacyPolicySection22Item1.
  ///
  /// In en, this message translates to:
  /// **'- Book reviews'**
  String get privacyPolicySection22Item1;

  /// No description provided for @privacyPolicySection22Item2.
  ///
  /// In en, this message translates to:
  /// **'- Ratings'**
  String get privacyPolicySection22Item2;

  /// No description provided for @privacyPolicySection22Item3.
  ///
  /// In en, this message translates to:
  /// **'- Quotes'**
  String get privacyPolicySection22Item3;

  /// No description provided for @privacyPolicySection22Item4.
  ///
  /// In en, this message translates to:
  /// **'- Lists you create'**
  String get privacyPolicySection22Item4;

  /// No description provided for @privacyPolicySection22Item5.
  ///
  /// In en, this message translates to:
  /// **'- Comments'**
  String get privacyPolicySection22Item5;

  /// No description provided for @privacyPolicySection23Title.
  ///
  /// In en, this message translates to:
  /// **'2.3 Usage Data'**
  String get privacyPolicySection23Title;

  /// No description provided for @privacyPolicySection23Item1.
  ///
  /// In en, this message translates to:
  /// **'- App usage interactions'**
  String get privacyPolicySection23Item1;

  /// No description provided for @privacyPolicySection23Item2.
  ///
  /// In en, this message translates to:
  /// **'- Feature usage (e.g., lists, stats, search)'**
  String get privacyPolicySection23Item2;

  /// No description provided for @privacyPolicySection23Item3.
  ///
  /// In en, this message translates to:
  /// **'- Device information (OS version, device type)'**
  String get privacyPolicySection23Item3;

  /// No description provided for @privacyPolicySection24Title.
  ///
  /// In en, this message translates to:
  /// **'2.4 Authentication Data'**
  String get privacyPolicySection24Title;

  /// No description provided for @privacyPolicySection24Item1.
  ///
  /// In en, this message translates to:
  /// **'- Basic profile information'**
  String get privacyPolicySection24Item1;

  /// No description provided for @privacyPolicySection24Item2.
  ///
  /// In en, this message translates to:
  /// **'- Email address'**
  String get privacyPolicySection24Item2;

  /// No description provided for @privacyPolicySection3Title.
  ///
  /// In en, this message translates to:
  /// **'3. How We Use Your Information'**
  String get privacyPolicySection3Title;

  /// No description provided for @privacyPolicySection3Item1.
  ///
  /// In en, this message translates to:
  /// **'- Provide and maintain the app'**
  String get privacyPolicySection3Item1;

  /// No description provided for @privacyPolicySection3Item2.
  ///
  /// In en, this message translates to:
  /// **'- Enable social features (lists, comments, likes)'**
  String get privacyPolicySection3Item2;

  /// No description provided for @privacyPolicySection3Item3.
  ///
  /// In en, this message translates to:
  /// **'- Personalize content and recommendations'**
  String get privacyPolicySection3Item3;

  /// No description provided for @privacyPolicySection3Item4.
  ///
  /// In en, this message translates to:
  /// **'- Improve app performance and features'**
  String get privacyPolicySection3Item4;

  /// No description provided for @privacyPolicySection3Item5.
  ///
  /// In en, this message translates to:
  /// **'- Communicate important updates'**
  String get privacyPolicySection3Item5;

  /// No description provided for @privacyPolicySection4Title.
  ///
  /// In en, this message translates to:
  /// **'4. Data Storage and Security'**
  String get privacyPolicySection4Title;

  /// No description provided for @privacyPolicySection4Body.
  ///
  /// In en, this message translates to:
  /// **'Your data is stored securely using third-party infrastructure such as Supabase.'**
  String get privacyPolicySection4Body;

  /// No description provided for @privacyPolicySection4Item1.
  ///
  /// In en, this message translates to:
  /// **'- Secure authentication'**
  String get privacyPolicySection4Item1;

  /// No description provided for @privacyPolicySection4Item2.
  ///
  /// In en, this message translates to:
  /// **'- Encrypted connections (HTTPS)'**
  String get privacyPolicySection4Item2;

  /// No description provided for @privacyPolicySection4Item3.
  ///
  /// In en, this message translates to:
  /// **'- Access control mechanisms'**
  String get privacyPolicySection4Item3;

  /// No description provided for @privacyPolicySection5Title.
  ///
  /// In en, this message translates to:
  /// **'5. Data Sharing'**
  String get privacyPolicySection5Title;

  /// No description provided for @privacyPolicySection5Body.
  ///
  /// In en, this message translates to:
  /// **'We do NOT sell your personal data.'**
  String get privacyPolicySection5Body;

  /// No description provided for @privacyPolicySection5Item1.
  ///
  /// In en, this message translates to:
  /// **'- With service providers (e.g., backend hosting)'**
  String get privacyPolicySection5Item1;

  /// No description provided for @privacyPolicySection5Item2.
  ///
  /// In en, this message translates to:
  /// **'- To comply with legal obligations'**
  String get privacyPolicySection5Item2;

  /// No description provided for @privacyPolicySection5Item3.
  ///
  /// In en, this message translates to:
  /// **'- To protect user safety and rights'**
  String get privacyPolicySection5Item3;

  /// No description provided for @privacyPolicySection6Title.
  ///
  /// In en, this message translates to:
  /// **'6. Public Content'**
  String get privacyPolicySection6Title;

  /// No description provided for @privacyPolicySection6Item1.
  ///
  /// In en, this message translates to:
  /// **'- Public lists'**
  String get privacyPolicySection6Item1;

  /// No description provided for @privacyPolicySection6Item2.
  ///
  /// In en, this message translates to:
  /// **'- Reviews'**
  String get privacyPolicySection6Item2;

  /// No description provided for @privacyPolicySection6Item3.
  ///
  /// In en, this message translates to:
  /// **'- Comments'**
  String get privacyPolicySection6Item3;

  /// No description provided for @privacyPolicySection6Body.
  ///
  /// In en, this message translates to:
  /// **'Content you share publicly may be visible to other users.'**
  String get privacyPolicySection6Body;

  /// No description provided for @privacyPolicySection7Title.
  ///
  /// In en, this message translates to:
  /// **'7. Data Retention'**
  String get privacyPolicySection7Title;

  /// No description provided for @privacyPolicySection7Item1.
  ///
  /// In en, this message translates to:
  /// **'- As long as your account is active'**
  String get privacyPolicySection7Item1;

  /// No description provided for @privacyPolicySection7Item2.
  ///
  /// In en, this message translates to:
  /// **'- Or as needed to provide services'**
  String get privacyPolicySection7Item2;

  /// No description provided for @privacyPolicySection7Body.
  ///
  /// In en, this message translates to:
  /// **'You may request deletion of your data at any time.'**
  String get privacyPolicySection7Body;

  /// No description provided for @privacyPolicySection8Title.
  ///
  /// In en, this message translates to:
  /// **'8. Your Rights'**
  String get privacyPolicySection8Title;

  /// No description provided for @privacyPolicySection8Item1.
  ///
  /// In en, this message translates to:
  /// **'- Access your data'**
  String get privacyPolicySection8Item1;

  /// No description provided for @privacyPolicySection8Item2.
  ///
  /// In en, this message translates to:
  /// **'- Update your information'**
  String get privacyPolicySection8Item2;

  /// No description provided for @privacyPolicySection8Item3.
  ///
  /// In en, this message translates to:
  /// **'- Request deletion of your account'**
  String get privacyPolicySection8Item3;

  /// No description provided for @privacyPolicySection8Item4.
  ///
  /// In en, this message translates to:
  /// **'- Withdraw consent'**
  String get privacyPolicySection8Item4;

  /// No description provided for @privacyPolicySection8Body.
  ///
  /// In en, this message translates to:
  /// **'To exercise these rights, contact us at:'**
  String get privacyPolicySection8Body;

  /// No description provided for @privacyPolicySection8Email.
  ///
  /// In en, this message translates to:
  /// **'Email: [YOUR EMAIL]'**
  String get privacyPolicySection8Email;

  /// No description provided for @privacyPolicySection9Title.
  ///
  /// In en, this message translates to:
  /// **'9. Children\'s Privacy'**
  String get privacyPolicySection9Title;

  /// No description provided for @privacyPolicySection9Body1.
  ///
  /// In en, this message translates to:
  /// **'Rubricator is not intended for users under the age of 13.'**
  String get privacyPolicySection9Body1;

  /// No description provided for @privacyPolicySection9Body2.
  ///
  /// In en, this message translates to:
  /// **'We do not knowingly collect data from children.'**
  String get privacyPolicySection9Body2;

  /// No description provided for @privacyPolicySection10Title.
  ///
  /// In en, this message translates to:
  /// **'10. Third-Party Services'**
  String get privacyPolicySection10Title;

  /// No description provided for @privacyPolicySection10Item1.
  ///
  /// In en, this message translates to:
  /// **'- Google (authentication, analytics)'**
  String get privacyPolicySection10Item1;

  /// No description provided for @privacyPolicySection10Item2.
  ///
  /// In en, this message translates to:
  /// **'- Supabase (data storage)'**
  String get privacyPolicySection10Item2;

  /// No description provided for @privacyPolicySection10Body.
  ///
  /// In en, this message translates to:
  /// **'These services have their own privacy policies.'**
  String get privacyPolicySection10Body;

  /// No description provided for @privacyPolicySection11Title.
  ///
  /// In en, this message translates to:
  /// **'11. International Data Transfers'**
  String get privacyPolicySection11Title;

  /// No description provided for @privacyPolicySection11Body.
  ///
  /// In en, this message translates to:
  /// **'Your information may be processed in different countries where our service providers operate.'**
  String get privacyPolicySection11Body;

  /// No description provided for @privacyPolicySection12Title.
  ///
  /// In en, this message translates to:
  /// **'12. Changes to This Privacy Policy'**
  String get privacyPolicySection12Title;

  /// No description provided for @privacyPolicySection12Body.
  ///
  /// In en, this message translates to:
  /// **'We may update this policy from time to time. Changes will be reflected by updating the \"Last updated\" date.'**
  String get privacyPolicySection12Body;

  /// No description provided for @privacyPolicySection13Title.
  ///
  /// In en, this message translates to:
  /// **'13. Contact Us'**
  String get privacyPolicySection13Title;

  /// No description provided for @privacyPolicySection13Body.
  ///
  /// In en, this message translates to:
  /// **'If you have any questions about this Privacy Policy, contact us:'**
  String get privacyPolicySection13Body;

  /// No description provided for @privacyPolicySection13Email.
  ///
  /// In en, this message translates to:
  /// **'Email: ismailyucelolmez514@gmail.com'**
  String get privacyPolicySection13Email;

  /// No description provided for @privacyPolicyFooter.
  ///
  /// In en, this message translates to:
  /// **'By using Rubricator, you agree to this Privacy Policy.'**
  String get privacyPolicyFooter;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
