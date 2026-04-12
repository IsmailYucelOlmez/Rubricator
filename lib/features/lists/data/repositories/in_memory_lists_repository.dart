import '../../domain/entities/list_entities.dart';
import '../../domain/repositories/lists_repository.dart';

class InMemoryListsRepository implements ListsRepository {
  final List<ListEntity> _lists = <ListEntity>[
    ListEntity(
      id: 'l1',
      userId: 'seed_u1',
      userName: 'Mina',
      title: 'Comfort Reads for Rainy Days',
      description: 'Warm stories with calm pacing and cozy vibes.',
      isPublic: true,
      likeCount: 42,
      commentCount: 8,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      previewCoverImageUrls: const <String?>[],
    ),
    ListEntity(
      id: 'l2',
      userId: 'seed_u2',
      userName: 'Arda',
      title: 'Short Books Under 250 Pages',
      description: 'Fast and impactful reads for busy weeks.',
      isPublic: true,
      likeCount: 67,
      commentCount: 14,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      previewCoverImageUrls: const <String?>[],
    ),
  ];

  final Map<String, List<ListItemEntity>> _itemsByList = <String, List<ListItemEntity>>{
    'l1': <ListItemEntity>[
      const ListItemEntity(
        id: 'li1',
        listId: 'l1',
        bookId: 'gb1',
        bookTitle: 'Pride and Prejudice',
        bookAuthor: 'Jane Austen',
        orderIndex: 0,
        note: 'Perfect pacing and mood.',
      ),
      const ListItemEntity(
        id: 'li2',
        listId: 'l1',
        bookId: 'gb2',
        bookTitle: 'Anne of Green Gables',
        bookAuthor: 'L. M. Montgomery',
        orderIndex: 1,
      ),
    ],
    'l2': <ListItemEntity>[
      const ListItemEntity(
        id: 'li3',
        listId: 'l2',
        bookId: 'gb3',
        bookTitle: 'Animal Farm',
        bookAuthor: 'George Orwell',
        orderIndex: 0,
      ),
    ],
  };

  final Map<String, List<ListComment>> _commentsByList = <String, List<ListComment>>{
    'l1': <ListComment>[
      ListComment(
        id: 'c1',
        userId: 'seed_u3',
        userName: 'Elif',
        listId: 'l1',
        content: 'Loved this theme, added to my saved lists.',
        createdAt: DateTime.now().subtract(const Duration(hours: 9)),
      ),
    ],
  };

  final Map<String, Set<String>> _likesByList = <String, Set<String>>{};
  final Map<String, Set<String>> _savesByUser = <String, Set<String>>{};

  @override
  Future<ListEntity> createList({
    required String userId,
    required String userName,
    required String title,
    required String description,
    required bool isPublic,
  }) async {
    final list = ListEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      userName: userName,
      title: title.trim(),
      description: description.trim(),
      isPublic: isPublic,
      likeCount: 0,
      commentCount: 0,
      createdAt: DateTime.now(),
      previewCoverImageUrls: const <String?>[],
    );
    _lists.insert(0, list);
    _itemsByList[list.id] = <ListItemEntity>[];
    return list;
  }

  @override
  Future<void> deleteList(String listId) async {
    _lists.removeWhere((list) => list.id == listId);
    _itemsByList.remove(listId);
    _commentsByList.remove(listId);
    for (final saveSet in _savesByUser.values) {
      saveSet.remove(listId);
    }
  }

  @override
  Future<List<ListEntity>> getFeedLists() async {
    final copy = List<ListEntity>.from(_lists);
    copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return copy;
  }

  @override
  Future<List<ListEntity>> getFollowingLists() async {
    final feed = await getFeedLists();
    return feed.take(10).toList();
  }

  @override
  Future<List<ListItemEntity>> getListItems(String listId) async {
    final items = List<ListItemEntity>.from(_itemsByList[listId] ?? const <ListItemEntity>[]);
    items.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return items;
  }

  @override
  Future<List<ListEntity>> getPopularLists() async {
    final copy = List<ListEntity>.from(_lists);
    copy.sort((a, b) => b.likeCount.compareTo(a.likeCount));
    return copy;
  }

  @override
  Future<List<ListEntity>> getSavedLists(String userId) async {
    final saved = _savesByUser[userId] ?? const <String>{};
    return _lists.where((l) => saved.contains(l.id)).toList();
  }

  @override
  Future<List<ListEntity>> getUserLists(String userId) async {
    return _lists.where((l) => l.userId == userId).toList();
  }

  @override
  Future<void> likeList(String userId, String listId) async {
    final liked = _likesByList.putIfAbsent(listId, () => <String>{});
    if (liked.add(userId)) {
      _updateList(listId, (l) => l.copyWith(likeCount: l.likeCount + 1, isLikedByMe: true));
    }
  }

  @override
  Future<void> unlikeList(String userId, String listId) async {
    final liked = _likesByList.putIfAbsent(listId, () => <String>{});
    if (liked.remove(userId)) {
      _updateList(
        listId,
        (l) => l.copyWith(
          likeCount: (l.likeCount - 1).clamp(0, 1 << 30),
          isLikedByMe: false,
        ),
      );
    }
  }

  @override
  Future<void> addComment({
    required String userId,
    required String userName,
    required String listId,
    required String content,
  }) async {
    final comments = _commentsByList.putIfAbsent(listId, () => <ListComment>[]);
    comments.add(
      ListComment(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        userId: userId,
        userName: userName,
        listId: listId,
        content: content.trim(),
        createdAt: DateTime.now(),
      ),
    );
    _updateList(
      listId,
      (l) => l.copyWith(commentCount: l.commentCount + 1),
    );
  }

  @override
  Future<List<ListComment>> getComments(String listId) async {
    return List<ListComment>.from(_commentsByList[listId] ?? const <ListComment>[]);
  }

  @override
  Future<void> saveList(String userId, String listId) async {
    final saved = _savesByUser.putIfAbsent(userId, () => <String>{});
    if (saved.add(listId)) {
      _updateList(listId, (l) => l.copyWith(isSavedByMe: true));
    }
  }

  @override
  Future<void> unsaveList(String userId, String listId) async {
    final saved = _savesByUser.putIfAbsent(userId, () => <String>{});
    if (saved.remove(listId)) {
      _updateList(listId, (l) => l.copyWith(isSavedByMe: false));
    }
  }

  @override
  Future<void> updateList({
    required String listId,
    required String title,
    required String description,
    required bool isPublic,
  }) async {
    _updateList(
      listId,
      (l) => l.copyWith(
        title: title.trim(),
        description: description.trim(),
        isPublic: isPublic,
      ),
    );
  }

  @override
  Future<ListItemEntity> addBookToList({
    required String listId,
    required String bookId,
    required String title,
    required String author,
    String? coverImageUrl,
  }) async {
    final items = _itemsByList.putIfAbsent(listId, () => <ListItemEntity>[]);
    final entity = ListItemEntity(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      listId: listId,
      bookId: bookId,
      bookTitle: title,
      bookAuthor: author,
      coverImageUrl: coverImageUrl,
      orderIndex: items.length,
    );
    items.add(entity);
    _updateList(
      listId,
      (l) => l.copyWith(
        previewCoverImageUrls: items.take(4).map((e) => e.coverImageUrl).toList(),
      ),
    );
    return entity;
  }

  @override
  Future<void> removeBookFromList(String listItemId) async {
    for (final entry in _itemsByList.entries) {
      final before = entry.value.length;
      entry.value.removeWhere((item) => item.id == listItemId);
      if (entry.value.length != before) {
        for (var i = 0; i < entry.value.length; i++) {
          final old = entry.value[i];
          entry.value[i] = ListItemEntity(
            id: old.id,
            listId: old.listId,
            bookId: old.bookId,
            bookTitle: old.bookTitle,
            bookAuthor: old.bookAuthor,
            coverImageUrl: old.coverImageUrl,
            orderIndex: i,
            note: old.note,
          );
        }
        return;
      }
    }
  }

  @override
  Future<void> reorderListItems({
    required String listId,
    required List<String> orderedItemIds,
  }) async {
    final items = _itemsByList[listId];
    if (items == null) return;
    final byId = {for (final item in items) item.id: item};
    final reordered = <ListItemEntity>[];
    for (var i = 0; i < orderedItemIds.length; i++) {
      final old = byId[orderedItemIds[i]];
      if (old == null) continue;
      reordered.add(
        ListItemEntity(
          id: old.id,
          listId: old.listId,
          bookId: old.bookId,
          bookTitle: old.bookTitle,
          bookAuthor: old.bookAuthor,
          coverImageUrl: old.coverImageUrl,
          orderIndex: i,
          note: old.note,
        ),
      );
    }
    _itemsByList[listId] = reordered;
  }

  void _updateList(String listId, ListEntity Function(ListEntity old) update) {
    final idx = _lists.indexWhere((l) => l.id == listId);
    if (idx < 0) return;
    _lists[idx] = update(_lists[idx]);
  }
}
