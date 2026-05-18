/// Book metadata captured when the user marks a volume completed.
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
