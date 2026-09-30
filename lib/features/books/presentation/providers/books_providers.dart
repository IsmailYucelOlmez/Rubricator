import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/auth_provider.dart';
import '../../../lists/presentation/providers/lists_providers.dart';
import '../../../profile_stats/presentation/providers/profile_stats_revision.dart';
import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/network/supabase_service.dart';
import '../../../trbooks/domain/usecases/trbooks_usecases.dart';
import '../../../trbooks/presentation/providers/trbooks_providers.dart';
import '../../data/datasources/google_books_cache_datasource.dart';
import '../../data/services/ai_service.dart';
import '../../data/services/api_service.dart';
import '../../data/repositories/book_detail_repository_impl.dart';
import '../../data/repositories/book_repository.dart';
import '../../domain/entities/author.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/book_content_exception.dart';
import '../../domain/entities/book_detail_entities.dart';
import '../../domain/repositories/book_detail_repository.dart';

final _apiProvider = Provider<ApiService>((ref) => ApiService());

final _googleBooksCacheProvider = Provider<GoogleBooksCacheDataSource>(
  (ref) => GoogleBooksCacheDataSource(SupabaseService.client),
);

final bookRepositoryProvider = Provider<BookRepository>(
  (ref) => BookRepository(
    ref.watch(_apiProvider),
    cache: ref.watch(_googleBooksCacheProvider),
    preferredLanguageCode: ref.watch(localeProvider).languageCode,
  ),
);

final _aiServiceProvider = Provider<AiService>((ref) => AiService());

final trendingBooksProvider = FutureProvider<List<Book>>((ref) async {
  final localeCode = ref.watch(localeProvider).languageCode;
  if (localeCode == 'tr') {
    final trbooks = await ref.watch(popularTrbooksUseCaseProvider).call();
    if (trbooks.isNotEmpty) return trbooks;
  }
  return ref.watch(bookRepositoryProvider).trendingBooks();
});

final bookDetailRepositoryProvider = Provider<BookDetailRepository>(
  (ref) => BookDetailRepositoryImpl(ref.watch(_apiProvider)),
);

/// Resolves a stored book id (Google volume id or `trbooks:`-prefixed) to a
/// [Book]. Shared by favorites/notes/habits/profile-stats so they don't each
/// need to know about the two catalogs.
final resolveBookByIdUseCaseProvider = Provider<ResolveBookByIdUseCase>(
  (ref) => ResolveBookByIdUseCase(
    ref.watch(trbooksRepositoryProvider),
    ref.watch(bookRepositoryProvider),
  ),
);

final currentUserIdProvider = Provider<String?>((ref) {
  ref.watch(authStateProvider);
  final sessionUserId = ref.watch(authServiceProvider).currentUser?.id;
  if (sessionUserId != null) return sessionUserId;
  return ref.watch(authStateProvider).valueOrNull?.id;
});

final bookDetailProvider = FutureProvider.family<BookEntity, Book>((
  ref,
  book,
) async {
  // trbooks entries carry all the detail the catalog has already;
  // there's no Google volume id to enrich them further with.
  final b = book.id.startsWith('trbooks:')
      ? book
      : await ref.watch(bookRepositoryProvider).getBookDetail(book);
  return BookEntity(
    id: b.id,
    title: b.title,
    author: b.author,
    coverImageUrl: b.coverImageUrl,
    description: b.description,
    authorIds: b.authorIds,
    subjectKeys: b.subjectKeys,
    sourceUrl: b.sourceUrl,
    isUserSubmitted: b.isUserSubmitted,
  );
});

final aiSummaryProvider = FutureProvider.family<String, BookEntity>((
  ref,
  book,
) {
  final source = Book(
    id: book.id,
    title: book.title,
    author: book.author,
    coverImageUrl: book.coverImageUrl,
    description: book.description,
    authorIds: book.authorIds,
    subjectKeys: book.subjectKeys,
  );
  return ref.watch(_aiServiceProvider).summarize(source);
});

/// trbooks has no author entity (no bio/dates) — author ids for
/// trbooks-sourced books use a `tr:`-prefixed encoded name instead of a
/// Google author id, so the page still opens with just a name and book list.
final authorDetailProvider = FutureProvider.family<Author, String>((
  ref,
  authorId,
) {
  if (authorId.startsWith('tr:')) {
    final name = Uri.decodeComponent(authorId.substring(3));
    return Future.value(Author(id: authorId, name: name, bio: ''));
  }
  return ref.watch(bookRepositoryProvider).getAuthor(authorId);
});

final authorBooksProvider = FutureProvider.family<List<Book>, String>((
  ref,
  authorId,
) async {
  if (authorId.startsWith('tr:')) {
    final name = Uri.decodeComponent(authorId.substring(3));
    final trbooks = await ref.watch(trbooksRepositoryProvider).byAuthor(name);
    if (trbooks.isNotEmpty) return trbooks;
    return ref.watch(bookRepositoryProvider).getBooksByAuthorName(name);
  }
  final repository = ref.watch(bookRepositoryProvider);
  final author = await ref.watch(authorDetailProvider(authorId).future);
  final booksFromName = await repository.getBooksByAuthorName(author.name);
  if (booksFromName.isNotEmpty) return booksFromName;
  return repository.getBooksByAuthorId(authorId);
});

/// Related titles are looked up by the first subject (or the author when the
/// book has none). The key only holds strings so a re-created [BookEntity]
/// with an equal-but-new subjects list doesn't spawn a second fetch.
typedef RelatedBooksKey = ({String workId, String? subject, String author});

RelatedBooksKey relatedBooksKeyFor(BookEntity book) => (
  workId: book.id,
  subject: book.subjectKeys.isEmpty ? null : book.subjectKeys.first,
  author: book.author,
);

final relatedBooksProvider = FutureProvider.family<List<Book>, RelatedBooksKey>(
  (ref, arg) async {
    if (arg.workId.startsWith('trbooks:')) {
      final trbooks = await ref
          .watch(trbooksRepositoryProvider)
          .related(
            excludeId: arg.workId,
            category: arg.subject,
            author: arg.author,
          );
      if (trbooks.isNotEmpty) return trbooks;
    }
    final book = Book(
      id: arg.workId,
      title: '',
      author: arg.author,
      description: '',
      subjectKeys: [?arg.subject],
    );
    return ref.watch(bookRepositoryProvider).getRelatedBooks(book);
  },
);

String _requireUserId(Ref ref) {
  final userId = ref.read(currentUserIdProvider);
  if (userId == null) {
    throw const BookContentException(BookContentError.signInRequired);
  }
  return userId;
}

/// Optimistic like toggling shared by reviews and quotes: the tap shows up
/// immediately, the server result is merged into whatever the list looks like
/// by then, and only the toggled item is rolled back on failure. Taps on an
/// item whose previous toggle is still in flight are ignored so the
/// server-side toggle can't drift from what the UI shows.
mixin _OptimisticLikes<T> on FamilyAsyncNotifier<List<T>, String> {
  final _pendingLikes = <String>{};

  String likeIdOf(T item);
  bool likedOf(T item);
  int likesOf(T item);
  T withLike(T item, {required bool liked, required int likes});
  Future<LikeToggleResult> sendToggle(String id);

  void _replace(String id, T Function(T item) update) {
    final list = state.valueOrNull;
    if (list == null) return;
    state = AsyncData([
      for (final item in list) likeIdOf(item) == id ? update(item) : item,
    ]);
  }

  Future<void> toggleLike(String id) async {
    _requireUserId(ref);
    if (!_pendingLikes.add(id)) return;
    T? original;
    for (final item in state.valueOrNull ?? <T>[]) {
      if (likeIdOf(item) == id) original = item;
    }
    if (original != null) {
      final liked = !likedOf(original);
      _replace(
        id,
        (item) => withLike(
          item,
          liked: liked,
          likes: likesOf(item) + (liked ? 1 : -1) < 0
              ? 0
              : likesOf(item) + (liked ? 1 : -1),
        ),
      );
    }
    try {
      final result = await sendToggle(id);
      _replace(
        id,
        (item) => withLike(item, liked: result.liked, likes: result.likes),
      );
    } catch (_) {
      final restore = original;
      if (restore != null) {
        _replace(
          id,
          (item) =>
              withLike(item, liked: likedOf(restore), likes: likesOf(restore)),
        );
      }
      rethrow;
    } finally {
      _pendingLikes.remove(id);
    }
  }
}

class ReviewListNotifier extends FamilyAsyncNotifier<List<ReviewEntity>, String>
    with _OptimisticLikes<ReviewEntity> {
  BookDetailRepository get _repo => ref.read(bookDetailRepositoryProvider);

  @override
  Future<List<ReviewEntity>> build(String arg) {
    ref.watch(authStateProvider);
    return ref.watch(bookDetailRepositoryProvider).getReviews(arg);
  }

  @override
  String likeIdOf(ReviewEntity item) => item.id;

  @override
  bool likedOf(ReviewEntity item) => item.likedByCurrentUser;

  @override
  int likesOf(ReviewEntity item) => item.likes;

  @override
  ReviewEntity withLike(
    ReviewEntity item, {
    required bool liked,
    required int likes,
  }) => item.copyWith(likedByCurrentUser: liked, likes: likes);

  @override
  Future<LikeToggleResult> sendToggle(String id) => _repo.toggleReviewLike(id);

  static String _validated(String content) {
    final trimmed = content.trim();
    if (trimmed.length < 10) {
      throw const BookContentException(BookContentError.reviewTooShort);
    }
    return trimmed;
  }

  /// Runs a write and reloads the list. A failed write throws and leaves the
  /// current list on screen instead of replacing it with an error view.
  Future<void> _mutate(Future<void> Function() action) async {
    await action();
    state = AsyncData(await _repo.getReviews(arg));
  }

  Future<void> add(String content, {bool isSpoiler = false}) async {
    final userId = _requireUserId(ref);
    final trimmed = _validated(content);
    await _mutate(
      () => _repo.addReview(
        ReviewEntity(
          id: '',
          bookId: arg,
          userId: userId,
          content: trimmed,
          createdAt: DateTime.now(),
          isSpoiler: isSpoiler,
        ),
      ),
    );
  }

  Future<void> editReview(
    ReviewEntity review,
    String content, {
    bool? isSpoiler,
  }) async {
    final trimmed = _validated(content);
    await _mutate(
      () => _repo.updateReview(
        review.copyWith(content: trimmed, isSpoiler: isSpoiler),
      ),
    );
  }

  Future<void> remove(ReviewEntity review) =>
      _mutate(() => _repo.deleteReview(review.id, review.userId));
}

final reviewListProvider =
    AsyncNotifierProviderFamily<ReviewListNotifier, List<ReviewEntity>, String>(
      ReviewListNotifier.new,
    );

class ExternalReviewNotifier
    extends FamilyAsyncNotifier<List<ExternalReviewEntity>, String> {
  BookDetailRepository get _repo => ref.read(bookDetailRepositoryProvider);

  @override
  Future<List<ExternalReviewEntity>> build(String arg) {
    return ref.watch(bookDetailRepositoryProvider).getExternalReviews(arg);
  }

  Future<void> add({
    required String title,
    required String url,
    String description = '',
  }) async {
    final userId = _requireUserId(ref);
    if (title.trim().isEmpty) {
      throw const BookContentException(BookContentError.titleRequired);
    }
    final normalizedUrl = _normalizeExternalReviewUrl(url);
    final parsed = Uri.tryParse(normalizedUrl);
    final scheme = parsed?.scheme.toLowerCase() ?? '';
    if (parsed == null ||
        parsed.host.isEmpty ||
        (scheme != 'http' && scheme != 'https')) {
      throw const BookContentException(BookContentError.invalidUrl);
    }
    final displayName = ref.read(currentUserDisplayNameProvider).trim();
    await _repo.addExternalReview(
      ExternalReviewEntity(
        id: '',
        bookId: arg,
        userId: userId,
        title: title.trim(),
        url: normalizedUrl,
        createdAt: DateTime.now(),
        description: description.trim(),
        userName: displayName.isEmpty ? null : displayName,
      ),
    );
    state = AsyncData(await _repo.getExternalReviews(arg));
  }

  Future<void> remove(ExternalReviewEntity review) async {
    await _repo.deleteExternalReview(review.id);
    state = AsyncData(await _repo.getExternalReviews(arg));
  }
}

String _normalizeExternalReviewUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return trimmed;
  final parsed = Uri.tryParse(trimmed);
  if (parsed != null && parsed.hasScheme && parsed.host.isNotEmpty) {
    return trimmed;
  }
  return 'https://$trimmed';
}

final externalReviewProvider =
    AsyncNotifierProviderFamily<
      ExternalReviewNotifier,
      List<ExternalReviewEntity>,
      String
    >(ExternalReviewNotifier.new);

class QuoteNotifier extends FamilyAsyncNotifier<List<QuoteEntity>, String>
    with _OptimisticLikes<QuoteEntity> {
  BookDetailRepository get _repo => ref.read(bookDetailRepositoryProvider);

  @override
  Future<List<QuoteEntity>> build(String arg) {
    ref.watch(authStateProvider);
    return ref.watch(bookDetailRepositoryProvider).getQuotes(arg);
  }

  @override
  String likeIdOf(QuoteEntity item) => item.id;

  @override
  bool likedOf(QuoteEntity item) => item.likedByCurrentUser;

  @override
  int likesOf(QuoteEntity item) => item.likes;

  @override
  QuoteEntity withLike(
    QuoteEntity item, {
    required bool liked,
    required int likes,
  }) => item.copyWith(likedByCurrentUser: liked, likes: likes);

  @override
  Future<LikeToggleResult> sendToggle(String id) => _repo.toggleQuoteLike(id);

  static String _validated(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw const BookContentException(BookContentError.quoteRequired);
    }
    return trimmed;
  }

  Future<void> _mutate(Future<void> Function() action) async {
    await action();
    state = AsyncData(await _repo.getQuotes(arg));
  }

  Future<void> add(String content) async {
    final userId = _requireUserId(ref);
    final trimmed = _validated(content);
    await _mutate(
      () => _repo.addQuote(
        QuoteEntity(
          id: '',
          bookId: arg,
          userId: userId,
          content: trimmed,
          likes: 0,
          createdAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> edit(QuoteEntity quote, String content) async {
    final trimmed = _validated(content);
    await _mutate(() => _repo.updateQuote(quote.copyWith(content: trimmed)));
  }

  Future<void> remove(QuoteEntity quote) =>
      _mutate(() => _repo.deleteQuote(quote.id));
}

final quoteProvider =
    AsyncNotifierProviderFamily<QuoteNotifier, List<QuoteEntity>, String>(
      QuoteNotifier.new,
    );

class RatingState {
  const RatingState({
    required this.summary,
    required this.submitting,
    required this.userRating,
  });

  final RatingSummary summary;
  final bool submitting;
  final int? userRating;
}

class RatingNotifier extends FamilyAsyncNotifier<RatingState, String> {
  @override
  Future<RatingState> build(String arg) async {
    ref.watch(authStateProvider);
    final repository = ref.watch(bookDetailRepositoryProvider);
    final (summary, userRating) = await (
      repository.getRatingSummary(arg),
      repository.getUserRating(arg),
    ).wait;
    return RatingState(
      summary: summary,
      submitting: false,
      userRating: userRating,
    );
  }

  /// Throws on failure and restores the previous state, so the caller can
  /// report the error without the rating card flipping into an error view.
  Future<void> submit(int value) async {
    final userId =
        ref.read(authServiceProvider).currentUser?.id ??
        ref.read(currentUserIdProvider);
    if (userId == null) {
      throw const BookContentException(BookContentError.signInRequired);
    }
    if (value < 1 || value > 10) {
      throw const BookContentException(BookContentError.ratingOutOfRange);
    }
    final current = state.valueOrNull;
    if (current == null || current.submitting) return;
    state = AsyncData(
      RatingState(
        summary: current.summary,
        submitting: true,
        userRating: current.userRating,
      ),
    );
    try {
      final repository = ref.read(bookDetailRepositoryProvider);
      await repository.rateBook(
        RatingEntity(bookId: arg, userId: userId, rating: value),
      );
      ref.read(userRatingsRevisionProvider.notifier).state++;
      ref.invalidate(forYouListsProvider);
      final summary = await repository.getRatingSummary(arg);
      state = AsyncData(
        RatingState(summary: summary, submitting: false, userRating: value),
      );
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
  }
}

final ratingProvider =
    AsyncNotifierProviderFamily<RatingNotifier, RatingState, String>(
      RatingNotifier.new,
    );
