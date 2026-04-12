import '../../../books/domain/entities/book.dart';

class HomeBookEntity {
  const HomeBookEntity({
    required this.id,
    required this.title,
    this.coverImageUrl,
    required this.authorNames,
  });

  final String id;
  final String title;
  final String? coverImageUrl;
  final String authorNames;

  Book toBook() {
    return Book(
      id: id,
      title: title,
      author: authorNames,
      coverImageUrl: coverImageUrl,
      description: '',
    );
  }
}
