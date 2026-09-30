import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bookapp/core/i18n/l10n/app_localizations.dart';
import 'package:bookapp/features/auth/presentation/auth_provider.dart';
import 'package:bookapp/features/lists/domain/entities/list_entities.dart';
import 'package:bookapp/features/lists/domain/repositories/lists_repository.dart';
import 'package:bookapp/features/lists/presentation/pages/list_search_page.dart';
import 'package:bookapp/features/lists/presentation/providers/lists_providers.dart';

ListEntity _list({
  required String id,
  required String title,
  required String description,
}) {
  return ListEntity(
    id: id,
    userId: 'user-1',
    userName: 'Test User',
    title: title,
    description: description,
    isPublic: true,
    likeCount: 0,
    commentCount: 0,
    createdAt: DateTime(2026, 1, 1),
    previewCoverImageUrls: const [],
  );
}

/// Searches across the entire (fake) database of lists, regardless of what's
/// loaded into any feed tab — mirrors what [SupabaseListsRepository] does
/// against the real `lists` table.
class _FakeListsRepository implements ListsRepository {
  _FakeListsRepository(this._allLists);
  final List<ListEntity> _allLists;

  @override
  Future<List<ListEntity>> searchLists(String query, {int limit = 30}) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const <ListEntity>[];
    return _allLists
        .where(
          (l) =>
              l.isPublic &&
              (l.title.toLowerCase().contains(q) ||
                  l.description.toLowerCase().contains(q)),
        )
        .take(limit)
        .toList();
  }

  @override
  Future<List<ListEntity>> getListsContainingBook(
    String bookId, {
    int limit = 100,
  }) => throw UnimplementedError();

  @override
  Future<int> countListsContainingBook(String bookId) =>
      throw UnimplementedError();

  @override
  Future<Map<String, String>> getListItemIdsForBook({
    required String userId,
    required String bookId,
  }) => throw UnimplementedError();

  @override
  Future<void> addComment({
    required String userId,
    required String userName,
    required String listId,
    required String content,
  }) => throw UnimplementedError();

  @override
  Future<ListItemEntity> addBookToList({
    required String listId,
    required String bookId,
    required String title,
    required String author,
    String? coverImageUrl,
  }) => throw UnimplementedError();

  @override
  Future<ListEntity> createList({
    required String userId,
    required String userName,
    required String title,
    required String description,
    required bool isPublic,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteList(String listId) => throw UnimplementedError();

  @override
  Future<List<ListEntity>> getFeedLists() => throw UnimplementedError();

  @override
  Future<List<ListEntity>> getFollowingLists() => throw UnimplementedError();

  @override
  Future<List<ListComment>> getComments(String listId) => throw UnimplementedError();

  @override
  Future<List<ListItemEntity>> getListItems(String listId) => throw UnimplementedError();

  @override
  Future<Map<String, List<ListItemEntity>>> getListItemsByListIds(
    List<String> listIds, {
    int maxItemsPerList = 10,
  }) => throw UnimplementedError();

  @override
  Future<List<ListEntity>> getPopularLists() => throw UnimplementedError();

  @override
  Future<List<ListEntity>> getRecommendedLists({int limit = 50, int offset = 0}) =>
      throw UnimplementedError();

  @override
  Future<List<ListEntity>> getSavedLists(String userId) => throw UnimplementedError();

  @override
  Future<List<ListEntity>> getTopListsByEngagement({int limit = 20}) =>
      throw UnimplementedError();

  @override
  Future<List<ListEntity>> getUserLists(String userId) => throw UnimplementedError();

  @override
  Future<void> likeList(String userId, String listId) => throw UnimplementedError();

  @override
  Future<void> removeBookFromList(String listItemId) => throw UnimplementedError();

  @override
  Future<void> reorderListItems({
    required String listId,
    required List<String> orderedItemIds,
  }) => throw UnimplementedError();

  @override
  Future<void> saveList(String userId, String listId) => throw UnimplementedError();

  @override
  Future<void> unlikeList(String userId, String listId) => throw UnimplementedError();

  @override
  Future<void> unsaveList(String userId, String listId) => throw UnimplementedError();

  @override
  Future<void> updateList({
    required String listId,
    required String title,
    required String description,
    required bool isPublic,
  }) => throw UnimplementedError();
}

final _allListsInDb = [
  _list(id: '1', title: 'Distopik Klasikler', description: '1984 ve benzeri kitaplar'),
  _list(id: '2', title: 'Yaz Okumaları', description: 'Sahilde okunacak hafif romanlar'),
  _list(id: '3', title: 'Bilim Kurgu Seçkisi', description: 'Uzay ve teknoloji temalı distopya'),
];

Future<void> _pumpDebounce(WidgetTester tester) =>
    tester.pump(const Duration(milliseconds: 350));

void main() {
  testWidgets('typing searches all lists in the database by title or description', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
          listsRepositoryProvider.overrideWithValue(_FakeListsRepository(_allListsInDb)),
        ],
        child: MaterialApp(
          locale: const Locale('tr'),
          supportedLocales: const [Locale('en'), Locale('tr')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const ListSearchPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Nothing has been searched yet.
    expect(find.text('Distopik Klasikler'), findsNothing);
    expect(find.text('Yaz Okumaları'), findsNothing);
    expect(find.text('Bilim Kurgu Seçkisi'), findsNothing);

    // Search by title fragment.
    await tester.enterText(find.byType(TextField), 'distopik');
    await _pumpDebounce(tester);
    await tester.pumpAndSettle();

    expect(find.text('Distopik Klasikler'), findsOneWidget);
    expect(find.text('Yaz Okumaları'), findsNothing);
    expect(find.text('Bilim Kurgu Seçkisi'), findsNothing);

    // Search by description fragment (matches a different list than the title search).
    await tester.enterText(find.byType(TextField), 'distopya');
    await _pumpDebounce(tester);
    await tester.pumpAndSettle();

    expect(find.text('Bilim Kurgu Seçkisi'), findsOneWidget);
    expect(find.text('Distopik Klasikler'), findsNothing);
    expect(find.text('Yaz Okumaları'), findsNothing);

    // No match -> empty state.
    await tester.enterText(find.byType(TextField), 'zzz-no-match-zzz');
    await _pumpDebounce(tester);
    await tester.pumpAndSettle();

    expect(find.text('Distopik Klasikler'), findsNothing);
    expect(find.text('Yaz Okumaları'), findsNothing);
    expect(find.text('Bilim Kurgu Seçkisi'), findsNothing);
    expect(
      find.text(lookupAppLocalizations(const Locale('tr')).noListsFound),
      findsOneWidget,
    );
  });
}
