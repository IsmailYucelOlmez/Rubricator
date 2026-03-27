import '../../../services/api_service.dart';
import '../domain/book.dart';

class BookRepository {
  BookRepository(this._apiService);

  final ApiService _apiService;

  Future<List<Book>> searchBooks(String query) async {
    if (query.trim().isEmpty) return <Book>[];
    final json = await _apiService.getJson('/search.json', queryParameters: {
      'q': query,
      'limit': 20,
    });
    final docs = (json['docs'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>();
    return docs.map(Book.fromSearchJson).toList();
  }

  Future<List<Book>> trendingBooks() async {
    final json = await _apiService.getJson('/subjects/popular.json', queryParameters: {
      'limit': 20,
    });
    final works = (json['works'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>();
    return works
        .map(
          (work) => Book(
            id: (work['key'] as String? ?? '').replaceFirst('/works/', ''),
            title: work['title'] as String? ?? 'Unknown title',
            author: ((work['authors'] as List<dynamic>?)?.isNotEmpty ?? false)
                ? ((work['authors']!.first as Map<String, dynamic>)['name'] as String? ??
                    'Unknown author')
                : 'Unknown author',
            coverId: work['cover_id'] as int?,
            description: '',
          ),
        )
        .toList();
  }

  /// Load a work by Open Library work id (e.g. from Supabase `favorites.book_id`).
  Future<Book> getBookByWorkId(String workId) async {
    return getBookDetail(Book(
      id: workId,
      title: '',
      author: '',
      coverId: null,
      description: '',
    ));
  }

  Future<Book> getBookDetail(Book book) async {
    final json = await _apiService.getJson('/works/${book.id}.json');
    final dynamic descriptionField = json['description'];
    final description = switch (descriptionField) {
      String text => text,
      Map<String, dynamic> map => map['value'] as String? ?? '',
      _ => '',
    };
    return book.copyWith(description: description);
  }
}
