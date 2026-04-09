class ListEntity {
  const ListEntity({
    required this.id,
    required this.userId,
    required this.userName,
    required this.title,
    required this.description,
    required this.isPublic,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    required this.previewCoverIds,
    this.isLikedByMe = false,
    this.isSavedByMe = false,
  });

  final String id;
  final String userId;
  final String userName;
  final String title;
  final String description;
  final bool isPublic;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  final List<int?> previewCoverIds;
  final bool isLikedByMe;
  final bool isSavedByMe;

  ListEntity copyWith({
    String? id,
    String? userId,
    String? userName,
    String? title,
    String? description,
    bool? isPublic,
    int? likeCount,
    int? commentCount,
    DateTime? createdAt,
    List<int?>? previewCoverIds,
    bool? isLikedByMe,
    bool? isSavedByMe,
  }) {
    return ListEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      title: title ?? this.title,
      description: description ?? this.description,
      isPublic: isPublic ?? this.isPublic,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      previewCoverIds: previewCoverIds ?? this.previewCoverIds,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      isSavedByMe: isSavedByMe ?? this.isSavedByMe,
    );
  }
}

class ListItemEntity {
  const ListItemEntity({
    required this.id,
    required this.listId,
    required this.bookId,
    required this.bookTitle,
    required this.bookAuthor,
    required this.coverId,
    required this.orderIndex,
    this.note,
  });

  final String id;
  final String listId;
  final String bookId;
  final String bookTitle;
  final String bookAuthor;
  final int? coverId;
  final int orderIndex;
  final String? note;
}

class ListComment {
  const ListComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.listId,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String userName;
  final String listId;
  final String content;
  final DateTime createdAt;
}
