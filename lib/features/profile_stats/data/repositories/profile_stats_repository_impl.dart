import '../../../books/data/repositories/book_repository.dart';
import '../../../books/domain/entities/book.dart';
import '../../domain/entities/profile_stats_entities.dart';
import '../../domain/repositories/profile_stats_repository.dart';
import '../datasources/profile_stats_remote_datasource.dart';

class ProfileStatsRepositoryImpl implements ProfileStatsRepository {
  ProfileStatsRepositoryImpl(
    this._remote,
    this._books,
    this._currentUserId,
  );

  final ProfileStatsRemoteDataSource _remote;
  final BookRepository _books;
  final String? Function() _currentUserId;

  /// Single in-flight load for [getGenreStats] + [getAuthorStats] (same repo instance).
  Future<ReadingIdentityStats>? _readingIdentityFuture;

  static const int _summaryGenreSample = 16;
  static const int _genreTop = 5;
  static const int _authorTop = 12;
  static const int _fetchConcurrency = 4;

  String? _userId() {
    final id = _currentUserId();
    if (id == null || id.isEmpty) return null;
    return id;
  }

  Future<List<Book>> _booksForIds(List<String> ids) async {
    if (ids.isEmpty) return const <Book>[];
    final out = <Book>[];
    for (var i = 0; i < ids.length; i += _fetchConcurrency) {
      final end = (i + _fetchConcurrency > ids.length)
          ? ids.length
          : i + _fetchConcurrency;
      final chunk = ids.sublist(i, end);
      for (final id in chunk) {
        try {
          out.add(await _books.getBookByWorkId(id));
        } catch (_) {
          // Skip missing or API errors; stats stay useful for the rest.
        }
      }
    }
    return out;
  }

  static List<GenreStat> _genreStatsFromBooks(List<Book> books, int topN) {
    final counts = <String, int>{};
    for (final book in books) {
      for (final raw in book.subjectKeys) {
        final s = raw.trim();
        if (s.isEmpty) continue;
        counts[s] = (counts[s] ?? 0) + 1;
      }
    }
    final list = counts.entries
        .map((e) => GenreStat(genre: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return list.take(topN).toList();
  }

  static List<AuthorStat> _authorStatsFromBooks(List<Book> books, int topN) {
    final counts = <String, int>{};
    for (final book in books) {
      final a = book.author.trim();
      if (a.isEmpty || a == 'Unknown author') continue;
      counts[a] = (counts[a] ?? 0) + 1;
    }
    final list = counts.entries
        .map((e) => AuthorStat(author: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return list.take(topN).toList();
  }

  Future<ReadingIdentityStats> _readingIdentity() async {
    _readingIdentityFuture ??= () async {
      final uid = _userId();
      if (uid == null) {
        return const ReadingIdentityStats(genres: [], authors: []);
      }
      final ids = await _remote.fetchCompletedBookIds(uid);
      final books = await _booksForIds(ids);
      return ReadingIdentityStats(
        genres: _genreStatsFromBooks(books, _genreTop),
        authors: _authorStatsFromBooks(books, _authorTop),
      );
    }();
    return _readingIdentityFuture!;
  }

  static RatingStat _ratingStatFromValues(List<int> ratings) {
    if (ratings.isEmpty) {
      return const RatingStat(
        averageRating: 0,
        distribution: <int, int>{},
      );
    }
    final dist = <int, int>{for (var s = 1; s <= 5; s++) s: 0};
    var sum = 0.0;
    for (final r in ratings) {
      sum += r;
      dist[r] = (dist[r] ?? 0) + 1;
    }
    return RatingStat(
      averageRating: sum / ratings.length,
      distribution: dist,
    );
  }

  @override
  Future<ProfileStatsSummary> getStatsSummary() async {
    final uid = _userId();
    if (uid == null) {
      return const ProfileStatsSummary(
        completedBooks: 0,
        averageRating: 0,
        topGenre: '—',
      );
    }

    final completedF = _remote.countUserBooks(userId: uid, status: 'completed');
    final ratingsF = _remote.fetchUserRatings(uid);
    final idsF = _remote.fetchCompletedBookIds(uid);

    final completed = await completedF;
    final ratings = await ratingsF;
    final ratingStat = _ratingStatFromValues(ratings);

    final ids = await idsF;
    final sampleIds = ids.take(_summaryGenreSample).toList();
    final sampleBooks = await _booksForIds(sampleIds);
    final genres = _genreStatsFromBooks(sampleBooks, 1);
    final topGenre = genres.isEmpty ? '—' : genres.first.genre;

    return ProfileStatsSummary(
      completedBooks: completed,
      averageRating: ratingStat.averageRating,
      topGenre: topGenre,
    );
  }

  @override
  Future<List<GenreStat>> getGenreStats() async {
    return (await _readingIdentity()).genres;
  }

  @override
  Future<List<AuthorStat>> getAuthorStats() async {
    return (await _readingIdentity()).authors;
  }

  @override
  Future<RatingStat> getRatingStats() async {
    final uid = _userId();
    if (uid == null) {
      return const RatingStat(averageRating: 0, distribution: <int, int>{});
    }
    final ratings = await _remote.fetchUserRatings(uid);
    return _ratingStatFromValues(ratings);
  }

  @override
  Future<LibraryStat> getLibraryStats() async {
    final uid = _userId();
    if (uid == null) {
      return const LibraryStat(
        toRead: 0,
        reading: 0,
        completed: 0,
        dropped: 0,
        favorites: 0,
      );
    }

    final toRead = _remote.countUserBooks(userId: uid, status: 'to_read');
    final reading = _remote.countUserBooks(
      userId: uid,
      statusIn: const ['reading', 're_reading'],
    );
    final completed = _remote.countUserBooks(userId: uid, status: 'completed');
    final dropped = _remote.countUserBooks(userId: uid, status: 'dropped');
    final favorites =
        _remote.countUserBooks(userId: uid, isFavorite: true);

    return LibraryStat(
      toRead: await toRead,
      reading: await reading,
      completed: await completed,
      dropped: await dropped,
      favorites: await favorites,
    );
  }

  @override
  Future<ContentStat> getContentStats() async {
    final uid = _userId();
    if (uid == null) {
      return const ContentStat(reviewCount: 0, quoteCount: 0);
    }
    final reviews = _remote.countReviews(uid);
    final quotes = _remote.countQuotes(uid);
    return ContentStat(
      reviewCount: await reviews,
      quoteCount: await quotes,
    );
  }
}
