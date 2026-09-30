import 'dart:async';

import 'package:bookapp/features/auth/presentation/auth_provider.dart';
import 'package:bookapp/features/books/domain/entities/book_detail_entities.dart';
import 'package:bookapp/features/books/domain/repositories/book_detail_repository.dart';
import 'package:bookapp/features/books/presentation/providers/books_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements BookDetailRepository {
  _FakeRepository(this.quotes);

  final List<QuoteEntity> quotes;
  Completer<LikeToggleResult>? pendingToggle;
  int toggleCalls = 0;

  @override
  Future<List<QuoteEntity>> getQuotes(String bookId) async => quotes;

  @override
  Future<LikeToggleResult> toggleQuoteLike(String quoteId) {
    toggleCalls++;
    return (pendingToggle = Completer<LikeToggleResult>()).future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

QuoteEntity _quote(String id, {int likes = 3, bool liked = false}) =>
    QuoteEntity(
      id: id,
      bookId: 'b1',
      userId: 'someone',
      content: 'quote $id',
      likes: likes,
      createdAt: DateTime(2026),
      likedByCurrentUser: liked,
    );

void main() {
  late _FakeRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = _FakeRepository([_quote('q1'), _quote('q2', likes: 0)]);
    container = ProviderContainer(
      overrides: [
        bookDetailRepositoryProvider.overrideWithValue(repo),
        authStateProvider.overrideWith((ref) => Stream.value(null)),
        currentUserIdProvider.overrideWithValue('me'),
      ],
    );
    addTearDown(container.dispose);
    // Keep the provider alive the way a watching widget would; an unlistened
    // `.future` isn't rebuilt after the auth stream's first event.
    container.listen(quoteProvider('b1'), (_, _) {});
  });

  QuoteEntity quoteById(String id) => container
      .read(quoteProvider('b1'))
      .requireValue
      .firstWhere((q) => q.id == id);

  test('shows the like immediately and applies the server count', () async {
    await container.read(quoteProvider('b1').future);
    final toggle = container
        .read(quoteProvider('b1').notifier)
        .toggleLike('q1');

    expect(quoteById('q1').likedByCurrentUser, isTrue);
    expect(quoteById('q1').likes, 4);

    repo.pendingToggle!.complete(const LikeToggleResult(liked: true, likes: 9));
    await toggle;
    expect(quoteById('q1').likes, 9);
  });

  test('ignores taps while the same item is in flight', () async {
    await container.read(quoteProvider('b1').future);
    final notifier = container.read(quoteProvider('b1').notifier);
    final first = notifier.toggleLike('q1');
    await notifier.toggleLike('q1');

    expect(repo.toggleCalls, 1);
    expect(quoteById('q1').likedByCurrentUser, isTrue);

    repo.pendingToggle!.complete(const LikeToggleResult(liked: true, likes: 4));
    await first;
  });

  test('rolls back only the failed item', () async {
    await container.read(quoteProvider('b1').future);
    final notifier = container.read(quoteProvider('b1').notifier);
    final failing = notifier.toggleLike('q1');
    final failingToggle = repo.pendingToggle!;
    final other = notifier.toggleLike('q2');
    final otherToggle = repo.pendingToggle!;

    otherToggle.complete(const LikeToggleResult(liked: true, likes: 1));
    await other;
    failingToggle.completeError(Exception('network'));
    await expectLater(failing, throwsException);

    expect(quoteById('q1').likedByCurrentUser, isFalse);
    expect(quoteById('q1').likes, 3);
    expect(quoteById('q2').likedByCurrentUser, isTrue);
    expect(quoteById('q2').likes, 1);
  });
}
