import '../entities/book_detail_entities.dart';
import '../repositories/book_detail_repository.dart';

class GetBookDetailUseCase {
  const GetBookDetailUseCase(this._repository);
  final BookDetailRepository _repository;
  Future<BookEntity> call(String id) => _repository.getBookDetail(id);
}

class AddReviewUseCase {
  const AddReviewUseCase(this._repository);
  final BookDetailRepository _repository;
  Future<void> call(ReviewEntity review) => _repository.addReview(review);
}

class GetReviewsUseCase {
  const GetReviewsUseCase(this._repository);
  final BookDetailRepository _repository;
  Future<List<ReviewEntity>> call(String bookId) =>
      _repository.getReviews(bookId);
}

class AddExternalReviewUseCase {
  const AddExternalReviewUseCase(this._repository);
  final BookDetailRepository _repository;
  Future<void> call(ExternalReviewEntity review) =>
      _repository.addExternalReview(review);
}

class DeleteExternalReviewUseCase {
  const DeleteExternalReviewUseCase(this._repository);
  final BookDetailRepository _repository;
  Future<void> call(String reviewId) =>
      _repository.deleteExternalReview(reviewId);
}

class GetExternalReviewsUseCase {
  const GetExternalReviewsUseCase(this._repository);
  final BookDetailRepository _repository;
  Future<List<ExternalReviewEntity>> call(String bookId) =>
      _repository.getExternalReviews(bookId);
}

class AddQuoteUseCase {
  const AddQuoteUseCase(this._repository);
  final BookDetailRepository _repository;
  Future<void> call(QuoteEntity quote) => _repository.addQuote(quote);
}

class GetQuotesUseCase {
  const GetQuotesUseCase(this._repository);
  final BookDetailRepository _repository;
  Future<List<QuoteEntity>> call(String bookId) =>
      _repository.getQuotes(bookId);
}

class RateBookUseCase {
  const RateBookUseCase(this._repository);
  final BookDetailRepository _repository;
  Future<void> call(RatingEntity rating) => _repository.rateBook(rating);
}

class GetRatingSummaryUseCase {
  const GetRatingSummaryUseCase(this._repository);
  final BookDetailRepository _repository;
  Future<RatingSummary> call(String bookId) =>
      _repository.getRatingSummary(bookId);
}
