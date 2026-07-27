import '../../../books/domain/entities/book.dart';

class SemanticBookResult {
  const SemanticBookResult({
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

  Book toUnresolvedBook() => Book(
        id: 'pending:$isbn13',
        title: title,
        author: author,
        coverImageUrl: coverImageUrl,
        description: description,
      );
}
