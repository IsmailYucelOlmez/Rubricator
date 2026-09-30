import '../entities/list_entities.dart';

abstract class ListsRepository {
  Future<List<ListEntity>> getFeedLists();
  Future<List<ListEntity>> getPopularLists();
  Future<List<ListEntity>> getRecommendedLists({int limit = 50, int offset = 0});
  Future<List<ListEntity>> getTopListsByEngagement({int limit = 20});
  Future<List<ListEntity>> getFollowingLists();
  Future<List<ListEntity>> getUserLists(String userId);
  Future<List<ListEntity>> getSavedLists(String userId);

  /// Searches all public lists in the database by title or description.
  Future<List<ListEntity>> searchLists(String query, {int limit = 30});
  /// Lists the current viewer can see (public ones plus their own) that
  /// contain [bookId], most liked first.
  Future<List<ListEntity>> getListsContainingBook(
    String bookId, {
    int limit = 100,
  });

  /// Count for [getListsContainingBook] without loading the lists.
  Future<int> countListsContainingBook(String bookId);

  /// `listId -> listItemId` for [userId]'s own lists that contain [bookId].
  Future<Map<String, String>> getListItemIdsForBook({
    required String userId,
    required String bookId,
  });

  /// Adds [bookId] to the end of the list. Adding a book that is already in
  /// the list returns the existing item instead of failing.
  Future<ListItemEntity> addBookToList({
    required String listId,
    required String bookId,
    required String title,
    required String author,
    String? coverImageUrl,
  });
  Future<void> reorderListItems({
    required String listId,
    required List<String> orderedItemIds,
  });
  Future<void> removeBookFromList(String listItemId);
  Future<List<ListItemEntity>> getListItems(String listId);

  /// Batch-fetch items for a set of lists (first [maxItemsPerList] per list).
  Future<Map<String, List<ListItemEntity>>> getListItemsByListIds(
    List<String> listIds, {
    int maxItemsPerList = 10,
  });
  Future<ListEntity> createList({
    required String userId,
    required String userName,
    required String title,
    required String description,
    required bool isPublic,
  });
  Future<void> updateList({
    required String listId,
    required String title,
    required String description,
    required bool isPublic,
  });
  Future<void> deleteList(String listId);
  Future<void> likeList(String userId, String listId);
  Future<void> unlikeList(String userId, String listId);
  Future<void> saveList(String userId, String listId);
  Future<void> unsaveList(String userId, String listId);
  Future<List<ListComment>> getComments(String listId);
  Future<void> addComment({
    required String userId,
    required String userName,
    required String listId,
    required String content,
  });
}
