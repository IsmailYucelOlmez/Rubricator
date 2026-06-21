/// Book metadata stored on [user_books] for fast list display.
class UserBookSnapshot {
  const UserBookSnapshot({
    required this.title,
    required this.author,
    this.categories = const [],
  });

  final String title;
  final String author;
  final List<String> categories;
}
