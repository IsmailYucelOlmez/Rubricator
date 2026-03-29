import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../services/ai_service.dart';
import '../../../../services/api_service.dart';
import '../../data/repositories/book_detail_repository_impl.dart';
import '../../data/repositories/book_repository.dart';
import '../../domain/entities/author.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/book_detail_entities.dart';
import '../../domain/repositories/book_detail_repository.dart';

final _apiProvider = Provider<ApiService>((ref) => ApiService());

final bookRepositoryProvider = Provider<BookRepository>(
  (ref) => BookRepository(ref.watch(_apiProvider)),
);

final _aiServiceProvider = Provider<AiService>((ref) => AiService());
final _supabaseProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final trendingBooksProvider = FutureProvider<List<Book>>((ref) {
  return ref.watch(bookRepositoryProvider).trendingBooks();
});

final bookDetailRepositoryProvider = Provider<BookDetailRepository>(
  (ref) => BookDetailRepositoryImpl(ref.watch(_apiProvider)),
);

final currentUserIdProvider = Provider<String?>(
  (ref) => ref.watch(_supabaseProvider).auth.currentUser?.id,
);

final bookDetailProvider = FutureProvider.family<BookEntity, String>((
  ref,
  workId,
) {
  return ref.watch(bookDetailRepositoryProvider).getBookDetail(workId);
});

final aiSummaryProvider = FutureProvider.family<String, BookEntity>((
  ref,
  book,
) {
  final source = Book(
    id: book.id,
    title: book.title,
    author: book.author,
    coverId: book.coverId,
    description: book.description,
    authorIds: book.authorIds,
    subjectKeys: book.subjectKeys,
  );
  return ref.watch(_aiServiceProvider).summarize(source);
});

final authorDetailProvider = FutureProvider.family<Author, String>((
  ref,
  authorId,
) {
  return ref.watch(bookRepositoryProvider).getAuthor(authorId);
});

/// Subjects come from the work payload; use the enriched [Book] from [bookDetailProvider].
final relatedBooksProvider =
    FutureProvider.family<List<Book>, ({String workId, List<String> subjects})>(
      (ref, arg) async {
        if (arg.subjects.isEmpty) return <Book>[];
        final book = Book(
          id: arg.workId,
          title: '',
          author: '',
          coverId: null,
          description: '',
          subjectKeys: arg.subjects,
        );
        return ref.watch(bookRepositoryProvider).getRelatedBooks(book);
      },
    );

class ReviewListNotifier
    extends FamilyAsyncNotifier<List<ReviewEntity>, String> {
  late final String _bookId;

  @override
  Future<List<ReviewEntity>> build(String arg) {
    _bookId = arg;
    return ref.watch(bookDetailRepositoryProvider).getReviews(arg);
  }

  Future<void> add(String content) async {
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
            ),
          );
      return ref.read(bookDetailRepositoryProvider).getReviews(_bookId);
    });
  }

  Future<void> editReview(ReviewEntity review, String content) async {
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
            ),
          );
      return ref.read(bookDetailRepositoryProvider).getReviews(_bookId);
    });
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

  Future<void> add({required String title, required String url}) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw Exception('Sign in required.');
    final parsed = Uri.tryParse(url.trim());
    if (title.trim().isEmpty) throw Exception('Title is required.');
    if (parsed == null || !parsed.hasAbsolutePath || parsed.scheme.isEmpty) {
      throw Exception('Enter a valid URL.');
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(bookDetailRepositoryProvider)
          .addExternalReview(
            ExternalReviewEntity(
              id: '',
              bookId: _bookId,
              userId: userId,
              title: title.trim(),
              url: url.trim(),
              createdAt: DateTime.now(),
            ),
          );
      return ref.read(bookDetailRepositoryProvider).getExternalReviews(_bookId);
    });
  }
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

  Future<void> like(String quoteId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(bookDetailRepositoryProvider).likeQuote(quoteId);
      return ref.read(bookDetailRepositoryProvider).getQuotes(_bookId);
    });
  }
}

final quoteProvider =
    AsyncNotifierProviderFamily<QuoteNotifier, List<QuoteEntity>, String>(
      QuoteNotifier.new,
    );

class RatingState {
  const RatingState({required this.average, required this.submitting});

  final double average;
  final bool submitting;
}

class RatingNotifier extends FamilyAsyncNotifier<RatingState, String> {
  late final String _bookId;

  @override
  Future<RatingState> build(String arg) async {
    _bookId = arg;
    final avg = await ref
        .watch(bookDetailRepositoryProvider)
        .getAverageRating(arg);
    return RatingState(average: avg, submitting: false);
  }

  Future<void> submit(int value) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) throw Exception('Sign in required.');
    if (value < 1 || value > 5) {
      throw Exception('Rating must be between 1 and 5.');
    }
    final current = state.valueOrNull;
    state = AsyncData(
      RatingState(average: current?.average ?? 0, submitting: true),
    );
    state = await AsyncValue.guard(() async {
      await ref
          .read(bookDetailRepositoryProvider)
          .rateBook(
            RatingEntity(bookId: _bookId, userId: userId, rating: value),
          );
      final avg = await ref
          .read(bookDetailRepositoryProvider)
          .getAverageRating(_bookId);
      return RatingState(average: avg, submitting: false);
    });
  }
}

final ratingProvider =
    AsyncNotifierProviderFamily<RatingNotifier, RatingState, String>(
      RatingNotifier.new,
    );
