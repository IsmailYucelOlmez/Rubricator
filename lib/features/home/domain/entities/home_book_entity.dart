import '../../../books/domain/entities/book.dart';

class HomeBookEntity {
  const HomeBookEntity({
    required this.id,
    required this.title,
    this.coverImageUrl,
    required this.authorNames,
    this.description,
    this.sourceUrl,
  });

  final String id;
  final String title;
  final String? coverImageUrl;
  final String authorNames;
  final String? description;
  final String? sourceUrl;

  Book toBook() {
    return Book(
      id: id,
      title: title,
      author: authorNames,
      coverImageUrl: coverImageUrl,
      description: description ?? '',
      sourceUrl: sourceUrl,
    );
  }
}
