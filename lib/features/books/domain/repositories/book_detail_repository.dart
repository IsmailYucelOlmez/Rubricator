import '../entities/book_detail_entities.dart';

abstract class BookDetailRepository {
  Future<BookEntity> getBookDetail(String id);

  Future<void> addReview(ReviewEntity review);
  Future<void> updateReview(ReviewEntity review);
  Future<void> deleteReview(String reviewId, String userId);
  Future<List<ReviewEntity>> getReviews(String bookId);

  Future<void> addExternalReview(ExternalReviewEntity review);
  Future<List<ExternalReviewEntity>> getExternalReviews(String bookId);

  Future<void> addQuote(QuoteEntity quote);
  Future<void> likeQuote(String quoteId);
  Future<List<QuoteEntity>> getQuotes(String bookId);

  Future<void> rateBook(RatingEntity rating);
  Future<double> getAverageRating(String bookId);
  Future<int?> getUserRating(String bookId);
}
