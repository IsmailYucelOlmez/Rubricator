import '../../domain/entities/book_detail_entities.dart';

class ReviewModel {
  const ReviewModel({
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

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: (json['id'] ?? '').toString(),
      bookId: (json['book_id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'book_id': bookId,
    'user_id': userId,
    'content': content,
    'created_at': createdAt.toUtc().toIso8601String(),
  };

  ReviewEntity toEntity() => ReviewEntity(
    id: id,
    bookId: bookId,
    userId: userId,
    content: content,
    createdAt: createdAt,
  );

  factory ReviewModel.fromEntity(ReviewEntity entity) => ReviewModel(
    id: entity.id,
    bookId: entity.bookId,
    userId: entity.userId,
    content: entity.content,
    createdAt: entity.createdAt,
  );
}

class ExternalReviewModel {
  const ExternalReviewModel({
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

  factory ExternalReviewModel.fromJson(Map<String, dynamic> json) {
    return ExternalReviewModel(
      id: (json['id'] ?? '').toString(),
      bookId: (json['book_id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'book_id': bookId,
    'user_id': userId,
    'title': title,
    'url': url,
    'created_at': createdAt.toUtc().toIso8601String(),
  };

  ExternalReviewEntity toEntity() => ExternalReviewEntity(
    id: id,
    bookId: bookId,
    userId: userId,
    title: title,
    url: url,
    createdAt: createdAt,
  );

  factory ExternalReviewModel.fromEntity(ExternalReviewEntity entity) =>
      ExternalReviewModel(
        id: entity.id,
        bookId: entity.bookId,
        userId: entity.userId,
        title: entity.title,
        url: entity.url,
        createdAt: entity.createdAt,
      );
}

class QuoteModel {
  const QuoteModel({
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

  factory QuoteModel.fromJson(Map<String, dynamic> json) {
    return QuoteModel(
      id: (json['id'] ?? '').toString(),
      bookId: (json['book_id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse((json['created_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'book_id': bookId,
    'user_id': userId,
    'content': content,
    'likes': likes,
    'created_at': createdAt.toUtc().toIso8601String(),
  };

  QuoteEntity toEntity() => QuoteEntity(
    id: id,
    bookId: bookId,
    userId: userId,
    content: content,
    likes: likes,
    createdAt: createdAt,
  );

  factory QuoteModel.fromEntity(QuoteEntity entity) => QuoteModel(
    id: entity.id,
    bookId: entity.bookId,
    userId: entity.userId,
    content: entity.content,
    likes: entity.likes,
    createdAt: entity.createdAt,
  );
}
