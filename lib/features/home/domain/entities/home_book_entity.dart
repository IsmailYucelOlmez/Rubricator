import '../../../books/domain/entities/book.dart';

class HomeBookEntity {
  const HomeBookEntity({
    required this.id,
    required this.title,
    required this.coverId,
    required this.authorNames,
  });

  final String id;
  final String title;
  final int? coverId;
  final String authorNames;

  Book toBook() {
    return Book(
      id: id,
      title: title,
      author: authorNames,
      coverId: coverId,
      description: '',
    );
  }
}
