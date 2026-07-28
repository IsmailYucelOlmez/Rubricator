import '../../domain/entities/semantic_book_result.dart';

class SemanticBookResultModel {
  const SemanticBookResultModel({
    required this.isbn13,
    required this.title,
    required this.author,
    required this.description,
    this.coverImageUrl,
    this.category,
    this.similarity,
    this.source = 'local',
  });

  final String isbn13;
  final String title;
  final String author;
  final String description;
  final String? coverImageUrl;
  final String? category;
  final double? similarity;
  final String source;

  factory SemanticBookResultModel.fromJson(Map<String, dynamic> json) {
    return SemanticBookResultModel(
      isbn13: json['isbn13'] as String? ?? '',
      title: json['title'] as String? ?? 'Unknown title',
      author: json['author'] as String? ?? 'Unknown author',
      description: json['description'] as String? ?? '',
      coverImageUrl: json['coverImageUrl'] as String?,
      category: json['category'] as String?,
      similarity: (json['similarity'] as num?)?.toDouble(),
      source: json['source'] as String? ?? 'local',
    );
  }

  SemanticBookResult toEntity() => SemanticBookResult(
        isbn13: isbn13,
        title: title,
        author: author,
        description: description,
        coverImageUrl: coverImageUrl,
        category: category,
        similarity: similarity,
        source: source,
      );
}
