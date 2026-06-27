class HabitReadingBookChoice {
  const HabitReadingBookChoice({
    required this.bookId,
    required this.title,
    this.author,
    this.progress,
  });

  final String bookId;
  final String title;
  final String? author;
  final int? progress;
}
