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

final bookDetailProvider =
    FutureProvider.family<BookEntity, Book>((ref, book) async {
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

/// Subjects come from the work payload; use the enriched [Book] from [bookDetailProvider].
final relatedBooksProvider =
    FutureProvider.family<
      List<Book>,
      ({String workId, List<String> subjects, String author})
    >((ref, arg) async {
      if (arg.workId.startsWith('trbooks:')) {
        final trbooks = await ref.watch(trbooksRepositoryProvider).related(
          excludeId: arg.workId,
          category: arg.subjects.isNotEmpty ? arg.subjects.first : null,
          author: arg.author,
        );
        if (trbooks.isNotEmpty) return trbooks;
      }
      final book = Book(
        id: arg.workId,
        title: '',
        author: arg.author,
        description: '',
        subjectKeys: arg.subjects,
      );
      return ref.watch(bookRepositoryProvider).getRelatedBooks(book);
    });

class ReviewListNotifier
    extends FamilyAsyncNotifier<List<ReviewEntity>, String> {
  late final String _bookId;

  @override
  Future<List<ReviewEntity>> build(String arg) {
    _bookId = arg;
    return ref.watch(bookDetailRepositoryProvider).getReviews(arg);
  }

  Future<void> add(String content, {bool isSpoiler = false}) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw Exception('Sign in required.');
    if (content.trim().length < 10) {
      throw Exception('Review must be at least 10 characters.');
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(bookDetailRepositoryProvider)
          .addReview(
            ReviewEntity(
              id: '',
              bookId: _bookId,
              userId: userId,
              content: content.trim(),
              createdAt: DateTime.now(),
              isSpoiler: isSpoiler,
            ),
          );
      return ref.read(bookDetailRepositoryProvider).getReviews(_bookId);
    });
  }

  Future<void> editReview(
    ReviewEntity review,
    String content, {
    bool? isSpoiler,
  }) async {
    if (content.trim().length < 10) {
      throw Exception('Review must be at least 10 characters.');
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(bookDetailRepositoryProvider)
          .updateReview(
            ReviewEntity(
              id: review.id,
              bookId: review.bookId,
              userId: review.userId,
              content: content.trim(),
              createdAt: review.createdAt,
              likes: review.likes,
              likedByCurrentUser: review.likedByCurrentUser,
              userRating: review.userRating,
              isFavorite: review.isFavorite,
              userName: review.userName,
              isSpoiler: isSpoiler ?? review.isSpoiler,
            ),
          );
      return ref.read(bookDetailRepositoryProvider).getReviews(_bookId);
    });
  }

  Future<void> toggleLike(String reviewId) async {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(
        current
            .map(
              (review) {
                if (review.id != reviewId) return review;
                final liked = !review.likedByCurrentUser;
                return ReviewEntity(
                  id: review.id,
                  bookId: review.bookId,
                  userId: review.userId,
                  content: review.content,
                  createdAt: review.createdAt,
                  likes: review.likes + (liked ? 1 : -1),
                  likedByCurrentUser: liked,
                  userRating: review.userRating,
                  isFavorite: review.isFavorite,
                  userName: review.userName,
                  isSpoiler: review.isSpoiler,
                );
              },
            )
            .toList(),
      );
    }
    try {
      final result = await ref
          .read(bookDetailRepositoryProvider)
          .toggleReviewLike(reviewId);
      if (current != null) {
        state = AsyncData(
          current
              .map(
                (review) => review.id == reviewId
                    ? ReviewEntity(
                        id: review.id,
                        bookId: review.bookId,
                        userId: review.userId,
                        content: review.content,
                        createdAt: review.createdAt,
                        likes: result.likes,
                        likedByCurrentUser: result.liked,
                        userRating: review.userRating,
                        isFavorite: review.isFavorite,
                        userName: review.userName,
                        isSpoiler: review.isSpoiler,
                      )
                    : review,
              )
              .toList(),
        );
      } else {
        state = AsyncData(
          await ref.read(bookDetailRepositoryProvider).getReviews(_bookId),
        );
      }
    } catch (e) {
      if (current != null) state = AsyncData(current);
      rethrow;
    }
  }

  Future<void> remove(ReviewEntity review) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(bookDetailRepositoryProvider)
          .deleteReview(review.id, review.userId);
      return ref.read(bookDetailRepositoryProvider).getReviews(_bookId);
    });
  }
}

final reviewListProvider =
    AsyncNotifierProviderFamily<ReviewListNotifier, List<ReviewEntity>, String>(
      ReviewListNotifier.new,
    );

class ExternalReviewNotifier
    extends FamilyAsyncNotifier<List<ExternalReviewEntity>, String> {
  late final String _bookId;

  @override
  Future<List<ExternalReviewEntity>> build(String arg) {
    _bookId = arg;
    return ref.watch(bookDetailRepositoryProvider).getExternalReviews(arg);
  }

  Future<void> add({
    required String title,
    required String url,
    String description = '',
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw Exception('Sign in required.');
    final normalizedUrl = _normalizeExternalReviewUrl(url);
    final parsed = Uri.tryParse(normalizedUrl);
    if (title.trim().isEmpty) throw Exception('Title is required.');
    final scheme = parsed?.scheme.toLowerCase() ?? '';
    if (parsed == null ||
        parsed.host.isEmpty ||
        (scheme != 'http' && scheme != 'https')) {
      throw Exception('Enter a valid URL.');
    }
    final displayName = ref.read(currentUserDisplayNameProvider).trim();
    state = const AsyncLoading();
    try {
      await ref
          .read(bookDetailRepositoryProvider)
          .addExternalReview(
            ExternalReviewEntity(
              id: '',
              bookId: _bookId,
              userId: userId,
              title: title.trim(),
              url: normalizedUrl,
              createdAt: DateTime.now(),
              description: description.trim(),
              userName: displayName.isEmpty ? null : displayName,
            ),
          );
      final list = await ref
          .read(bookDetailRepositoryProvider)
          .getExternalReviews(_bookId);
      state = AsyncData(list);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> remove(ExternalReviewEntity review) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(bookDetailRepositoryProvider)
          .deleteExternalReview(review.id);
      final list = await ref
          .read(bookDetailRepositoryProvider)
          .getExternalReviews(_bookId);
      state = AsyncData(list);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

String _normalizeExternalReviewUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return trimmed;
  final parsed = Uri.tryParse(trimmed);
  if (parsed != null &&
      parsed.hasScheme &&
      parsed.host.isNotEmpty) {
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

class QuoteNotifier extends FamilyAsyncNotifier<List<QuoteEntity>, String> {
  late final String _bookId;

  @override
  Future<List<QuoteEntity>> build(String arg) {
    _bookId = arg;
    return ref.watch(bookDetailRepositoryProvider).getQuotes(arg);
  }

  Future<void> add(String content) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw Exception('Sign in required.');
    if (content.trim().isEmpty) throw Exception('Quote content is required.');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(bookDetailRepositoryProvider)
          .addQuote(
            QuoteEntity(
              id: '',
              bookId: _bookId,
              userId: userId,
              content: content.trim(),
              likes: 0,
              createdAt: DateTime.now(),
            ),
          );
      return ref.read(bookDetailRepositoryProvider).getQuotes(_bookId);
    });
  }

  Future<void> toggleLike(String quoteId) async {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(
        current
            .map(
              (quote) {
                if (quote.id != quoteId) return quote;
                final liked = !quote.likedByCurrentUser;
                return QuoteEntity(
                  id: quote.id,
                  bookId: quote.bookId,
                  userId: quote.userId,
                  content: quote.content,
                  likes: quote.likes + (liked ? 1 : -1),
                  createdAt: quote.createdAt,
                  likedByCurrentUser: liked,
                  userName: quote.userName,
                );
              },
            )
            .toList(),
      );
    }
    try {
      final result = await ref
          .read(bookDetailRepositoryProvider)
          .toggleQuoteLike(quoteId);
      if (current != null) {
        state = AsyncData(
          current
              .map(
                (quote) => quote.id == quoteId
                    ? QuoteEntity(
                        id: quote.id,
                        bookId: quote.bookId,
                        userId: quote.userId,
                        content: quote.content,
                        likes: result.likes,
                        createdAt: quote.createdAt,
                        likedByCurrentUser: result.liked,
                        userName: quote.userName,
                      )
                    : quote,
              )
              .toList(),
        );
      } else {
        state = AsyncData(
          await ref.read(bookDetailRepositoryProvider).getQuotes(_bookId),
        );
      }
    } catch (e) {
      if (current != null) state = AsyncData(current);
      rethrow;
    }
  }
}

final quoteProvider =
    AsyncNotifierProviderFamily<QuoteNotifier, List<QuoteEntity>, String>(
      QuoteNotifier.new,
    );

class RatingState {
  const RatingState({
    required this.average,
    required this.submitting,
    required this.userRating,
  });

  final double average;
  final bool submitting;
  final int? userRating;
}

class RatingNotifier extends FamilyAsyncNotifier<RatingState, String> {
  late final String _bookId;

  @override
  Future<RatingState> build(String arg) async {
    _bookId = arg;
    ref.watch(authStateProvider);
    final repository = ref.watch(bookDetailRepositoryProvider);
    final avg = await repository.getAverageRating(arg);
    final userRating = await repository.getUserRating(arg);
    return RatingState(average: avg, submitting: false, userRating: userRating);
  }

  Future<void> submit(int value) async {
    final userId =
        ref.read(authServiceProvider).currentUser?.id ??
        ref.read(currentUserIdProvider);
    if (userId == null) throw Exception('Sign in required.');
    if (value < 1 || value > 10) {
      throw Exception('Rating must be between 1 and 10.');
    }
    final current = state.valueOrNull;
    state = AsyncData(
      RatingState(
        average: current?.average ?? 0,
        submitting: true,
        userRating: current?.userRating,
      ),
    );
    state = await AsyncValue.guard(() async {
      await ref
          .read(bookDetailRepositoryProvider)
          .rateBook(
            RatingEntity(bookId: _bookId, userId: userId, rating: value),
          );
      ref.read(userRatingsRevisionProvider.notifier).state++;
      ref.invalidate(forYouListsProvider);
      final avg = await ref
          .read(bookDetailRepositoryProvider)
          .getAverageRating(_bookId);
      return RatingState(average: avg, submitting: false, userRating: value);
    });
  }
}

final ratingProvider =
    AsyncNotifierProviderFamily<RatingNotifier, RatingState, String>(
      RatingNotifier.new,
    );
