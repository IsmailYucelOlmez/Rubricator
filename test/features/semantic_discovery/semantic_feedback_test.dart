import 'dart:async';

import 'package:bookapp/features/auth/presentation/auth_provider.dart';
import 'package:bookapp/features/books/presentation/providers/books_providers.dart';
import 'package:bookapp/features/semantic_discovery/domain/entities/semantic_feedback.dart';
import 'package:bookapp/features/semantic_discovery/domain/entities/semantic_search_request.dart';
import 'package:bookapp/features/semantic_discovery/domain/repositories/semantic_feedback_repository.dart';
import 'package:bookapp/features/semantic_discovery/presentation/providers/semantic_discovery_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFeedbackRepository implements SemanticFeedbackRepository {
  _FakeFeedbackRepository(this.stored);

  final Map<String, SemanticFeedbackVote> stored;
  final submitted = <(String, SemanticFeedbackVote?, int?)>[];
  Completer<void>? pending;
  Object? failWith;

  @override
  Future<Map<String, SemanticFeedbackVote>> fetchMyVotes(
    SemanticFeedbackKey key,
  ) async => Map.of(stored);

  @override
  Future<void> submitVote({
    required SemanticFeedbackKey key,
    required String isbn13,
    required SemanticFeedbackVote? vote,
    int? resultPosition,
    double? similarity,
    String? mode,
    String? category,
    String? tone,
  }) async {
    submitted.add((isbn13, vote, resultPosition));
    if (pending != null) await pending!.future;
    if (failWith != null) throw failWith!;
  }
}

const _r = SemanticFeedbackVote.relevant;
const _i = SemanticFeedbackVote.irrelevant;

void main() {
  group('SemanticSearchRequest.toJson', () {
    test('omits feedback when nothing is marked', () {
      const request = SemanticSearchRequest(query: 'dark fantasy');
      expect(request.toJson().containsKey('feedback'), isFalse);
    });

    test('sends marks capped at five per side', () {
      final request = SemanticSearchRequest(
        query: 'dark fantasy',
        relevantIsbns: [for (var i = 0; i < 7; i++) '978000000000$i'],
        irrelevantIsbns: const ['9781111111111'],
      );
      final feedback = request.toJson()['feedback'] as Map<String, dynamic>;
      expect(feedback['relevant'], hasLength(5));
      expect(feedback['irrelevant'], ['9781111111111']);
    });
  });

  group('SemanticSearchRefinement', () {
    test('keeps the most recent five marks per side', () {
      final votes = {
        for (var i = 0; i < 7; i++) '978000000000$i': _r,
        '9781111111111': _i,
      };
      final refinement = SemanticSearchRefinement.fromVotes(votes);
      expect(refinement.relevant, [
        for (var i = 2; i < 7; i++) '978000000000$i',
      ]);
      expect(refinement.irrelevant, ['9781111111111']);
    });

    test('sameAs ignores order', () {
      const a = SemanticSearchRefinement(
        relevant: ['1', '2'],
        irrelevant: ['3'],
      );
      const b = SemanticSearchRefinement(
        relevant: ['2', '1'],
        irrelevant: ['3'],
      );
      expect(a.sameAs(b), isTrue);
      expect(
        a.sameAs(const SemanticSearchRefinement(relevant: ['1'])),
        isFalse,
      );
      expect(a.sameAs(null), isFalse);
    });
  });

  test('isVotableIsbn matches the RPC pattern', () {
    expect(isVotableIsbn('9780306406157'), isTrue);
    expect(isVotableIsbn('080442957x'), isTrue);
    expect(isVotableIsbn('gb:abc123'), isFalse);
    expect(isVotableIsbn(''), isFalse);
  });

  group('SemanticFeedbackVotesNotifier', () {
    const key = (query: 'dark fantasy', language: 'en');
    late _FakeFeedbackRepository repo;
    late ProviderContainer container;

    ProviderContainer build({String? userId = 'me'}) {
      final c = ProviderContainer(
        overrides: [
          semanticFeedbackRepositoryProvider.overrideWithValue(repo),
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          currentUserIdProvider.overrideWithValue(userId),
        ],
      );
      addTearDown(c.dispose);
      c.listen(semanticFeedbackVotesProvider(key), (_, _) {});
      return c;
    }

    Map<String, SemanticFeedbackVote> votes() =>
        container.read(semanticFeedbackVotesProvider(key)).requireValue;

    SemanticFeedbackVotesNotifier notifier() =>
        container.read(semanticFeedbackVotesProvider(key).notifier);

    setUp(() {
      repo = _FakeFeedbackRepository({'9780000000001': _r});
      container = build();
    });

    test('loads stored votes', () async {
      await container.read(semanticFeedbackVotesProvider(key).future);
      expect(votes(), {'9780000000001': _r});
    });

    test('is empty when signed out', () async {
      container = build(userId: null);
      expect(
        await container.read(semanticFeedbackVotesProvider(key).future),
        isEmpty,
      );
    });

    test('casts, flips and removes a vote', () async {
      await container.read(semanticFeedbackVotesProvider(key).future);

      await notifier().toggle('9780000000002', _i, resultPosition: 3);
      expect(votes()['9780000000002'], _i);

      await notifier().toggle('9780000000002', _r);
      expect(votes()['9780000000002'], _r);

      await notifier().toggle('9780000000002', _r);
      expect(votes().containsKey('9780000000002'), isFalse);

      expect(repo.submitted, [
        ('9780000000002', _i, 3),
        ('9780000000002', _r, null),
        ('9780000000002', null, null),
      ]);
    });

    test('updates optimistically and ignores taps while saving', () async {
      await container.read(semanticFeedbackVotesProvider(key).future);
      repo.pending = Completer<void>();

      final first = notifier().toggle('9780000000002', _r);
      expect(votes()['9780000000002'], _r);
      await notifier().toggle('9780000000002', _i);
      expect(repo.submitted, hasLength(1));

      repo.pending!.complete();
      await first;
      expect(votes()['9780000000002'], _r);
    });

    test('reverts and rethrows when saving fails', () async {
      await container.read(semanticFeedbackVotesProvider(key).future);
      repo.failWith = const SemanticFeedbackRateLimitException();

      await expectLater(
        notifier().toggle('9780000000001', _i),
        throwsA(isA<SemanticFeedbackRateLimitException>()),
      );
      expect(votes(), {'9780000000001': _r});
    });
  });
}
