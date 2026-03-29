import '../../../../services/api_service.dart';
import '../../domain/entities/book_detail_entities.dart';
import '../../domain/repositories/book_detail_repository.dart';
import '../datasources/book_detail_remote_datasource.dart';
import '../models/book_detail_models.dart';

class BookDetailRepositoryImpl implements BookDetailRepository {
  BookDetailRepositoryImpl(ApiService api)
    : _remote = BookDetailRemoteDataSource(api);

  final BookDetailRemoteDataSource _remote;

  @override
  Future<BookEntity> getBookDetail(String id) async {
    final model = await _remote.fetchBookDetail(id);
    final entity = model.toEntity();
    return BookEntity(
      id: entity.id,
      title: entity.title,
      author: entity.author,
      coverId: entity.coverId,
      description: entity.description,
      authorIds: entity.authorIds,
      subjectKeys: entity.subjectKeys,
    );
  }

  @override
  Future<void> addReview(ReviewEntity review) {
    return _remote.addReview(ReviewModel.fromEntity(review));
  }

  @override
  Future<void> updateReview(ReviewEntity review) {
    return _remote.updateReview(ReviewModel.fromEntity(review));
  }

  @override
  Future<void> deleteReview(String reviewId, String userId) {
    return _remote.deleteReview(reviewId);
  }

  @override
  Future<List<ReviewEntity>> getReviews(String bookId) async {
    final list = await _remote.getReviews(bookId);
    return list.map((e) => e.toEntity()).toList();
  }

  @override
  Future<void> addExternalReview(ExternalReviewEntity review) {
    return _remote.addExternalReview(ExternalReviewModel.fromEntity(review));
  }

  @override
  Future<List<ExternalReviewEntity>> getExternalReviews(String bookId) async {
    final list = await _remote.getExternalReviews(bookId);
    return list.map((e) => e.toEntity()).toList();
  }

  @override
  Future<void> addQuote(QuoteEntity quote) {
    return _remote.addQuote(QuoteModel.fromEntity(quote));
  }

  @override
  Future<void> likeQuote(String quoteId) => _remote.likeQuote(quoteId);

  @override
  Future<List<QuoteEntity>> getQuotes(String bookId) async {
    final list = await _remote.getQuotes(bookId);
    return list.map((e) => e.toEntity()).toList();
  }

  @override
  Future<void> rateBook(RatingEntity rating) {
    return _remote.rateBook(bookId: rating.bookId, rating: rating.rating);
  }

  @override
  Future<double> getAverageRating(String bookId) {
    return _remote.getAverageRating(bookId);
  }
}
