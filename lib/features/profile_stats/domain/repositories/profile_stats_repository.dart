import '../entities/profile_stats_entities.dart';

abstract class ProfileStatsRepository {
  Future<ProfileStatsSummary> getStatsSummary();

  Future<List<GenreStat>> getGenreStats();

  Future<List<AuthorStat>> getAuthorStats();

  Future<RatingStat> getRatingStats();

  Future<LibraryStat> getLibraryStats();

  Future<ContentStat> getContentStats();
}
