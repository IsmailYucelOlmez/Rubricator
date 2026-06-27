import '../../../user_books/domain/entities/user_book_entity.dart';

class HabitReadingBookChoice {
  const HabitReadingBookChoice({
    required this.bookId,
    required this.title,
    required this.status,
    this.author,
    this.progress,
  });

  final String bookId;
  final String title;
  final ReadingStatus status;
  final String? author;
  final int? progress;
}
