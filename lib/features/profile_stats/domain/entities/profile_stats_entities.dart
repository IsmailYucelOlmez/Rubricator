class ProfileStatsSummary {
  const ProfileStatsSummary({
    required this.completedBooks,
    required this.averageRating,
    required this.topGenre,
  });

  final int completedBooks;
  final double averageRating;
  final String topGenre;
}

class GenreStat {
  const GenreStat({required this.genre, required this.count});

  final String genre;
  final int count;
}

class AuthorStat {
  const AuthorStat({required this.author, required this.count});

  final String author;
  final int count;
}

class RatingStat {
  const RatingStat({
    required this.averageRating,
    required this.distribution,
  });

  final double averageRating;
  final Map<int, int> distribution;
}

class LibraryStat {
  const LibraryStat({
    required this.toRead,
    required this.reading,
    required this.completed,
    required this.dropped,
    required this.favorites,
  });

  final int toRead;
  final int reading;
  final int completed;
  final int dropped;
  final int favorites;
}

class ContentStat {
  const ContentStat({required this.reviewCount, required this.quoteCount});

  final int reviewCount;
  final int quoteCount;
}

class ReadingIdentityStats {
  const ReadingIdentityStats({
    required this.genres,
    required this.authors,
  });

  final List<GenreStat> genres;
  final List<AuthorStat> authors;
}
