import '../entities/list_entities.dart';
import '../repositories/lists_repository.dart';

class GetFeedListsUseCase {
  const GetFeedListsUseCase(this._repo);
  final ListsRepository _repo;
  Future<List<ListEntity>> call() => _repo.getFeedLists();
}

class GetPopularListsUseCase {
  const GetPopularListsUseCase(this._repo);
  final ListsRepository _repo;
  Future<List<ListEntity>> call() => _repo.getPopularLists();
}

class GetTopListsByEngagementUseCase {
  const GetTopListsByEngagementUseCase(this._repo);
  final ListsRepository _repo;
  Future<List<ListEntity>> call({int limit = 20}) =>
      _repo.getTopListsByEngagement(limit: limit);
}

class GetFollowingListsUseCase {
  const GetFollowingListsUseCase(this._repo);
  final ListsRepository _repo;
  Future<List<ListEntity>> call() => _repo.getFollowingLists();
}

class GetUserListsUseCase {
  const GetUserListsUseCase(this._repo);
  final ListsRepository _repo;
  Future<List<ListEntity>> call(String userId) => _repo.getUserLists(userId);
}

class GetSavedListsUseCase {
  const GetSavedListsUseCase(this._repo);
  final ListsRepository _repo;
  Future<List<ListEntity>> call(String userId) => _repo.getSavedLists(userId);
}
