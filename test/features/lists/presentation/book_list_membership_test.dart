import 'dart:async';

import 'package:bookapp/features/auth/presentation/auth_provider.dart';
import 'package:bookapp/features/lists/data/repositories/in_memory_lists_repository.dart';
import 'package:bookapp/features/lists/domain/entities/list_entities.dart';
import 'package:bookapp/features/lists/presentation/providers/lists_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

/// In-memory lists whose adds wait for the test to release them (or fail).
class _GatedRepository extends InMemoryListsRepository {
  Completer<void>? gate;
  int addCalls = 0;

  @override
  Future<ListItemEntity> addBookToList({
    required String listId,
    required String bookId,
    required String title,
    required String author,
    String? coverImageUrl,
  }) async {
    addCalls++;
    await (gate = Completer<void>()).future;
    return super.addBookToList(
      listId: listId,
      bookId: bookId,
      title: title,
      author: author,
      coverImageUrl: coverImageUrl,
    );
  }
}

const _user = User(
  id: 'me',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00Z',
);

const ListBookSnapshot _book = (
  bookId: 'b1',
  title: 'Book',
  author: 'Author',
  coverImageUrl: null,
);

void main() {
  late _GatedRepository repo;
  late ProviderContainer container;
  late String listId;

  setUp(() async {
    repo = _GatedRepository();
    final list = await repo.createList(
      userId: 'me',
      userName: 'Me',
      title: 'Mine',
      description: '',
      isPublic: true,
    );
    listId = list.id;
    container = ProviderContainer(
      overrides: [
        listsRepositoryProvider.overrideWithValue(repo),
        authStateProvider.overrideWith((ref) => Stream.value(_user)),
      ],
    );
    addTearDown(container.dispose);
    container.listen(bookListMembershipProvider('b1'), (_, _) {});
    await container.read(authStateProvider.future);
    await container.read(bookListMembershipProvider('b1').future);
  });

  Map<String, String?> members() =>
      container.read(bookListMembershipProvider('b1')).requireValue;

  BookListMembershipNotifier notifier() =>
      container.read(bookListMembershipProvider('b1').notifier);

  test('an add shows immediately and gets its item id once saved', () async {
    final add = notifier().toggle(listId, _book);
    expect(members(), {listId: null});

    repo.gate!.complete();
    await add;
    expect(members()[listId], isNotNull);
    expect(await repo.countListsContainingBook('b1'), 1);
  });

  test('taps on a list with a toggle in flight are ignored', () async {
    final add = notifier().toggle(listId, _book);
    await notifier().toggle(listId, _book);
    expect(repo.addCalls, 1);
    expect(members().containsKey(listId), isTrue);

    repo.gate!.complete();
    await add;
  });

  test('a failed add is rolled back', () async {
    final add = notifier().toggle(listId, _book);
    repo.gate!.completeError(Exception('offline'));
    await expectLater(add, throwsException);
    expect(members(), isEmpty);
  });

  test('toggling a member removes the book from that list', () async {
    final add = notifier().toggle(listId, _book);
    repo.gate!.complete();
    await add;

    await notifier().toggle(listId, _book);
    expect(members(), isEmpty);
    expect(await repo.countListsContainingBook('b1'), 0);
  });
}
