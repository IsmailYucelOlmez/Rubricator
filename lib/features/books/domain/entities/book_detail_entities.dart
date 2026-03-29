class BookEntity {
  const BookEntity({
    required this.id,
    required this.title,
    required this.author,
    required this.coverId,
    required this.description,
    this.authorIds = const [],
    this.subjectKeys = const [],
  });

  final String id;
  final String title;
  final String author;
  final int? coverId;
  final String description;
  final List<String> authorIds;
  final List<String> subjectKeys;
}

class ReviewEntity {
  const ReviewEntity({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String bookId;
  final String userId;
  final String content;
  final DateTime createdAt;
}

class ExternalReviewEntity {
  const ExternalReviewEntity({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.title,
    required this.url,
    required this.createdAt,
  });

  final String id;
  final String bookId;
  final String userId;
  final String title;
  final String url;
  final DateTime createdAt;
}

class QuoteEntity {
  const QuoteEntity({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.content,
    required this.likes,
    required this.createdAt,
  });

  final String id;
  final String bookId;
  final String userId;
  final String content;
  final int likes;
  final DateTime createdAt;
}

class RatingEntity {
  const RatingEntity({
    required this.bookId,
    required this.userId,
    required this.rating,
  });

  final String bookId;
  final String userId;
  final int rating;
}
