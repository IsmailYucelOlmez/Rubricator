import '../entities/profile_stats_entities.dart';
import '../repositories/profile_stats_repository.dart';

class GetProfileStatsSummaryUseCase {
  const GetProfileStatsSummaryUseCase(this._repository);

  final ProfileStatsRepository _repository;

  Future<ProfileStatsSummary> call() => _repository.getStatsSummary();
}

class GetGenreStatsUseCase {
  const GetGenreStatsUseCase(this._repository);

  final ProfileStatsRepository _repository;

  Future<List<GenreStat>> call() => _repository.getGenreStats();
}

class GetAuthorStatsUseCase {
  const GetAuthorStatsUseCase(this._repository);

  final ProfileStatsRepository _repository;

  Future<List<AuthorStat>> call() => _repository.getAuthorStats();
}

class GetRatingStatsUseCase {
  const GetRatingStatsUseCase(this._repository);

  final ProfileStatsRepository _repository;

  Future<RatingStat> call() => _repository.getRatingStats();
}

class GetLibraryStatsUseCase {
  const GetLibraryStatsUseCase(this._repository);

  final ProfileStatsRepository _repository;

  Future<LibraryStat> call() => _repository.getLibraryStats();
}

class GetContentStatsUseCase {
  const GetContentStatsUseCase(this._repository);

  final ProfileStatsRepository _repository;

  Future<ContentStat> call() => _repository.getContentStats();
}
