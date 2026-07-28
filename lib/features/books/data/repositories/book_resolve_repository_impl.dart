import '../../domain/entities/book.dart';
import '../../domain/repositories/book_resolve_repository.dart';
import '../datasources/book_identity_cache_datasource.dart';
import '../repositories/book_repository.dart';

/// Resolves semantic-discovery books (`pending:<isbn13>`) to Google volume IDs.
class BookResolveRepositoryImpl implements BookResolveRepository {
  BookResolveRepositoryImpl({
    required BookRepository bookRepository,
    required BookIdentityCacheDataSource identityCache,
  })  : _books = bookRepository,
        _cache = identityCache;

  final BookRepository _books;
  final BookIdentityCacheDataSource _cache;

  static const _pendingPrefix = 'pending:';

  @override
  Future<Book> resolve(Book unresolved) async {
    final id = unresolved.id.trim();
    if (id.isNotEmpty && !id.startsWith(_pendingPrefix)) {
      return unresolved;
    }

    final isbn13 = _extractIsbn(id);
    if (isbn13 == null) {
      return _resolveByTitleAuthor(unresolved, resolveMethod: 'title_author');
    }

    final cached = await _cache.lookup(isbn13);
    if (cached != null) {
      return _books.getBookByWorkId(cached.googleVolumeId);
    }

    final byIsbn = await _searchBestMatch('isbn:$isbn13', seed: unresolved);
    if (byIsbn != null) {
      await _cache.upsert(
        isbn13: isbn13,
        googleVolumeId: byIsbn.id,
        resolvedTitle: byIsbn.title,
        resolveMethod: 'isbn',
      );
      return byIsbn;
    }

    final byMetadata = await _resolveByTitleAuthor(
      unresolved,
      resolveMethod: 'title_author',
      isbn13: isbn13,
    );
    return byMetadata;
  }

  String? _extractIsbn(String id) {
    if (id.startsWith(_pendingPrefix)) {
      final isbn = id.substring(_pendingPrefix.length).trim();
      return isbn.isEmpty ? null : isbn;
    }
    return null;
  }

  Future<Book> _resolveByTitleAuthor(
    Book seed, {
    required String resolveMethod,
    String? isbn13,
  }) async {
    final title = seed.title.trim();
    final author = seed.author.trim();
    if (title.isEmpty) return seed;

    final query = author.isEmpty ? title : '$title $author';
    final match = await _searchBestMatch(query, seed: seed);
    if (match != null) {
      if (isbn13 != null) {
        await _cache.upsert(
          isbn13: isbn13,
          googleVolumeId: match.id,
          resolvedTitle: match.title,
          resolveMethod: resolveMethod,
        );
      }
      return match;
    }
    return seed;
  }

  Future<Book?> _searchBestMatch(String query, {required Book seed}) async {
    final page = await _books.searchBooks(query: query, page: 1);
    if (page.books.isEmpty) return null;

    final normalizedTitle = _normalize(seed.title);
    final normalizedAuthor = _normalize(seed.author);

    for (final candidate in page.books) {
      final titleMatch = normalizedTitle.isNotEmpty &&
          _normalize(candidate.title).contains(normalizedTitle);
      final authorMatch = normalizedAuthor.isEmpty ||
          _normalize(candidate.author).contains(normalizedAuthor);
      if (titleMatch && authorMatch) {
        return candidate;
      }
    }
    return page.books.first;
  }

  String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}
