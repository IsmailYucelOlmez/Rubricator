class BookEntity {
  const BookEntity({
    required this.id,
    required this.title,
    required this.author,
    this.coverImageUrl,
    required this.description,
    this.authorIds = const [],
    this.subjectKeys = const [],
  });

  final String id;
  final String title;
  final String author;
  final String? coverImageUrl;
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
    this.likes = 0,
    this.likedByCurrentUser = false,
    this.userRating,
    this.isFavorite = false,
  });

  final String id;
  final String bookId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final int likes;
  final bool likedByCurrentUser;
  final int? userRating;
  final bool isFavorite;
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
    this.likedByCurrentUser = false,
  });

  final String id;
  final String bookId;
  final String userId;
  final String content;
  final int likes;
  final DateTime createdAt;
  final bool likedByCurrentUser;
}

class LikeToggleResult {
  const LikeToggleResult({required this.liked, required this.likes});

  final bool liked;
  final int likes;
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
