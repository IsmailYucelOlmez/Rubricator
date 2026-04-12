import '../entities/list_entities.dart';

abstract class ListsRepository {
  Future<List<ListEntity>> getFeedLists();
  Future<List<ListEntity>> getPopularLists();
  Future<List<ListEntity>> getFollowingLists();
  Future<List<ListEntity>> getUserLists(String userId);
  Future<List<ListEntity>> getSavedLists(String userId);
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
