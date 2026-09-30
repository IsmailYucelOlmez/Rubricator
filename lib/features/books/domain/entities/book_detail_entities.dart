class BookEntity {
  const BookEntity({
    required this.id,
    required this.title,
    required this.author,
    this.coverImageUrl,
    required this.description,
    this.authorIds = const [],
    this.subjectKeys = const [],
    this.sourceUrl,
    this.isUserSubmitted = false,
  });

  final String id;
  final String title;
  final String author;
  final String? coverImageUrl;
  final String description;
  final List<String> authorIds;
  final List<String> subjectKeys;

  /// Retailer product page this book was scraped from (trbooks only);
  /// `null` for Google Books-origin books.
  final String? sourceUrl;

  /// True for trbooks rows with `source = 'user_submitted'`.
  final bool isUserSubmitted;

  /// Retailer behind [sourceUrl]; trbooks only scrapes these two stores.
  BookStore? get store => bookStoreFromUrl(sourceUrl);
}

enum BookStore { kitapyurdu, dr }

BookStore? bookStoreFromUrl(String? url) {
  if (url == null) return null;
  final host = (Uri.tryParse(url)?.host ?? '').toLowerCase();
  if (host.isEmpty) return null;
  if (host.contains('dr.com')) return BookStore.dr;
  if (host.contains('kitapyurdu')) return BookStore.kitapyurdu;
  return null;
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
    this.userName,
    this.isSpoiler = false,
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
  final String? userName;
  final bool isSpoiler;

  ReviewEntity copyWith({
    String? content,
    int? likes,
    bool? likedByCurrentUser,
    bool? isSpoiler,
  }) {
    return ReviewEntity(
      id: id,
      bookId: bookId,
      userId: userId,
      content: content ?? this.content,
      createdAt: createdAt,
      likes: likes ?? this.likes,
      likedByCurrentUser: likedByCurrentUser ?? this.likedByCurrentUser,
      userRating: userRating,
      isFavorite: isFavorite,
      userName: userName,
      isSpoiler: isSpoiler ?? this.isSpoiler,
    );
  }
}

class ExternalReviewEntity {
  const ExternalReviewEntity({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.title,
    required this.url,
    required this.createdAt,
    this.description = '',
    this.userName,
  });

  final String id;
  final String bookId;
  final String userId;
  final String title;
  final String url;
  final DateTime createdAt;
  final String description;
  final String? userName;
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
    this.userName,
  });

  final String id;
  final String bookId;
  final String userId;
  final String content;
  final int likes;
  final DateTime createdAt;
  final bool likedByCurrentUser;
  final String? userName;

  QuoteEntity copyWith({String? content, int? likes, bool? likedByCurrentUser}) {
    return QuoteEntity(
      id: id,
      bookId: bookId,
      userId: userId,
      content: content ?? this.content,
      likes: likes ?? this.likes,
      createdAt: createdAt,
      likedByCurrentUser: likedByCurrentUser ?? this.likedByCurrentUser,
      userName: userName,
    );
  }
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

class RatingSummary {
  const RatingSummary({required this.average, required this.count});

  static const empty = RatingSummary(average: 0, count: 0);

  /// Mean on the stored 1-10 scale; meaningless when [count] is 0.
  final double average;
  final int count;
}
