import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_service.dart';
import '../services/api_service.dart';
import '../../domain/entities/book_detail_entities.dart';
import '../models/book_detail_models.dart';
import '../models/book_model.dart';
import 'google_books_remote_datasource.dart';

class BookDetailRemoteDataSource {
  BookDetailRemoteDataSource(ApiService api)
    : _googleBooks = GoogleBooksRemoteDataSource(api);

  final GoogleBooksRemoteDataSource _googleBooks;

  SupabaseClient get _client => SupabaseService.client;

  Future<BookModel> fetchBookDetail(String workId) =>
      _googleBooks.fetchVolume(workId);

  Future<List<BookModel>> fetchSimilarBooks({
    required String workId,
    required List<String> subjects,
    required String author,
  }) async {
    if (subjects.isNotEmpty) {
      final subjectRelated = await _googleBooks.fetchRelatedBySubject(
        subject: subjects.first,
        excludeVolumeId: workId,
      );
      if (subjectRelated.isNotEmpty) return subjectRelated;
    }
    return _googleBooks.fetchRelatedByAuthor(
      author: author,
      excludeVolumeId: workId,
    );
  }

  String _requiredUserId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Sign in required.');
    }
    return userId;
  }

  Future<void> addReview(ReviewModel review) async {
    final userId = _requiredUserId();
    await _client.from('reviews').insert(<String, dynamic>{
      'book_id': review.bookId,
      'user_id': userId,
      'content': review.content,
    });
  }

  Future<void> updateReview(ReviewModel review) async {
    final userId = _requiredUserId();
    await _client
        .from('reviews')
        .update(<String, dynamic>{'content': review.content})
        .eq('id', review.id)
        .eq('user_id', userId);
  }

  Future<void> deleteReview(String reviewId) async {
    final userId = _requiredUserId();
    await _client
        .from('reviews')
        .delete()
        .eq('id', reviewId)
        .eq('user_id', userId);
  }

  Future<List<ReviewModel>> getReviews(String bookId) async {
    final rows = await _client
        .from('reviews')
        .select()
        .eq('book_id', bookId)
        .order('created_at', ascending: false);
    final reviews = (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(ReviewModel.fromJson)
        .toList();
    if (reviews.isEmpty) return reviews;

    final userId = _client.auth.currentUser?.id;
    final reviewIds = reviews.map((r) => r.id).toList();
    final likedReviewIds = await _likedReviewIds(reviewIds, userId);

    final userIds = reviews.map((r) => r.userId).toSet().toList();
    final ratingRows = await _client
        .from('ratings')
        .select('user_id, rating')
        .eq('book_id', bookId)
        .inFilter('user_id', userIds);
    final favoriteRows = await _client
        .from('user_books')
        .select('user_id, is_favorite')
        .eq('book_id', bookId)
        .inFilter('user_id', userIds);

    final ratingsByUser = <String, int>{};
    for (final row in ratingRows as List<dynamic>) {
      if (row is! Map<String, dynamic>) continue;
      final userId = (row['user_id'] ?? '').toString();
      final rating = (row['rating'] as num?)?.toInt();
      if (userId.isNotEmpty && rating != null) {
        ratingsByUser[userId] = rating;
      }
    }

    final favoritesByUser = <String, bool>{};
    for (final row in favoriteRows as List<dynamic>) {
      if (row is! Map<String, dynamic>) continue;
      final userId = (row['user_id'] ?? '').toString();
      if (userId.isEmpty) continue;
      favoritesByUser[userId] = row['is_favorite'] as bool? ?? false;
    }

    return reviews
        .map(
          (review) => ReviewModel(
            id: review.id,
            bookId: review.bookId,
            userId: review.userId,
            content: review.content,
            createdAt: review.createdAt,
            likes: review.likes,
            likedByCurrentUser: likedReviewIds.contains(review.id),
            userRating: ratingsByUser[review.userId],
            isFavorite: favoritesByUser[review.userId] ?? false,
            userName: review.userName,
          ),
        )
        .toList();
  }

  Future<Set<String>> _likedReviewIds(
    List<String> reviewIds,
    String? userId,
  ) async {
    if (userId == null || reviewIds.isEmpty) return const {};
    final rows = await _client
        .from('review_likes')
        .select('review_id')
        .eq('user_id', userId)
        .inFilter('review_id', reviewIds);
    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map((row) => (row['review_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<Set<String>> _likedQuoteIds(
    List<String> quoteIds,
    String? userId,
  ) async {
    if (userId == null || quoteIds.isEmpty) return const {};
    final rows = await _client
        .from('quote_likes')
        .select('quote_id')
        .eq('user_id', userId)
        .inFilter('quote_id', quoteIds);
    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map((row) => (row['quote_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  LikeToggleResult _parseLikeToggleResult(dynamic row) {
    if (row is! Map<String, dynamic>) {
      throw Exception('Invalid like toggle response.');
    }
    return LikeToggleResult(
      liked: row['liked'] as bool? ?? false,
      likes: (row['likes_count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> addExternalReview(ExternalReviewModel review) async {
    final userId = _requiredUserId();
    await _client.from('external_reviews').insert(<String, dynamic>{
      'book_id': review.bookId,
      'user_id': userId,
      'title': review.title,
      'url': review.url,
    });
  }

  Future<List<ExternalReviewModel>> getExternalReviews(String bookId) async {
    final rows = await _client
        .from('external_reviews')
        .select()
        .eq('book_id', bookId)
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(ExternalReviewModel.fromJson)
        .toList();
  }

  Future<void> addQuote(QuoteModel quote) async {
    final userId = _requiredUserId();
    await _client.from('quotes').insert(<String, dynamic>{
      'book_id': quote.bookId,
      'user_id': userId,
      'content': quote.content,
    });
  }

  Future<LikeToggleResult> toggleQuoteLike(String quoteId) async {
    _requiredUserId();
    final row = await _client.rpc<dynamic>(
      'toggle_quote_like',
      params: <String, dynamic>{'p_quote_id': quoteId},
    );
    if (row is List && row.isNotEmpty) {
      return _parseLikeToggleResult(row.first);
    }
    return _parseLikeToggleResult(row);
  }

  Future<LikeToggleResult> toggleReviewLike(String reviewId) async {
    _requiredUserId();
    final row = await _client.rpc<dynamic>(
      'toggle_review_like',
      params: <String, dynamic>{'p_review_id': reviewId},
    );
    if (row is List && row.isNotEmpty) {
      return _parseLikeToggleResult(row.first);
    }
    return _parseLikeToggleResult(row);
  }

  Future<List<QuoteModel>> getQuotes(String bookId) async {
    final rows = await _client
        .from('quotes')
        .select()
        .eq('book_id', bookId)
        .order('likes', ascending: false)
        .order('created_at', ascending: false);
    final quotes = (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(QuoteModel.fromJson)
        .toList();
    if (quotes.isEmpty) return quotes;

    final userId = _client.auth.currentUser?.id;
    final likedQuoteIds = await _likedQuoteIds(
      quotes.map((q) => q.id).toList(),
      userId,
    );

    return quotes
        .map(
          (quote) => QuoteModel(
            id: quote.id,
            bookId: quote.bookId,
            userId: quote.userId,
            content: quote.content,
            likes: quote.likes,
            createdAt: quote.createdAt,
            likedByCurrentUser: likedQuoteIds.contains(quote.id),
            userName: quote.userName,
          ),
        )
        .toList();
  }

  Future<void> rateBook({required String bookId, required int rating}) async {
    final userId = _requiredUserId();
    await _client.from('ratings').upsert(<String, dynamic>{
      'book_id': bookId,
      'user_id': userId,
      'rating': rating,
    }, onConflict: 'user_id,book_id');
  }

  Future<double> getAverageRating(String bookId) async {
    final rows = await _client
        .from('ratings')
        .select('rating')
        .eq('book_id', bookId);
    final list = rows as List<dynamic>;
    if (list.isEmpty) return 0;
    final values = list
        .whereType<Map<String, dynamic>>()
        .map((e) => (e['rating'] as num?)?.toDouble() ?? 0)
        .toList();
    if (values.isEmpty) return 0;
    final total = values.fold<double>(0, (a, b) => a + b);
    return total / values.length;
  }

  Future<int?> getUserRating(String bookId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await _client
        .from('ratings')
        .select('rating')
        .eq('book_id', bookId)
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return null;
    return (row['rating'] as num?)?.toInt();
  }
}
