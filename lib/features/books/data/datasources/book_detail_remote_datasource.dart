import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../services/api_service.dart';
import '../../../../services/supabase_service.dart';
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
    return (rows as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(ReviewModel.fromJson)
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
    final row = await _client
        .from('quotes')
        .select('likes')
        .eq('id', quoteId)
        .single();
    final currentLikes = ((row['likes'] as num?)?.toInt() ?? 0) + 1;
    await _client
        .from('quotes')
        .update(<String, dynamic>{'likes': currentLikes})
        .eq('id', quoteId);
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
}
