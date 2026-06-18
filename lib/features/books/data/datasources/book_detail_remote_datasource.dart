import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_service.dart';
import '../services/api_service.dart';
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
            userRating: ratingsByUser[review.userId],
            isFavorite: favoritesByUser[review.userId] ?? false,
          ),
        )
        .toList();
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

  Future<void> likeQuote(String quoteId) async {
    _requiredUserId();
    await _client.rpc<void>(
      'increment_quote_likes',
      params: <String, dynamic>{'quote_id': quoteId},
    );
  }

  Future<void> likeReview(String reviewId) async {
    _requiredUserId();
    await _client.rpc<void>(
      'increment_review_likes',
      params: <String, dynamic>{'review_id': reviewId},
    );
  }

  Future<List<QuoteModel>> getQuotes(String bookId) async {
    final rows = await _client
        .from('quotes')
        .select()
        .eq('book_id', bookId)
        .order('likes', ascending: false)
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(QuoteModel.fromJson)
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
