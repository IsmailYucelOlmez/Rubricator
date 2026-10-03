import 'package:bookapp/core/i18n/l10n/app_localizations.dart';
import 'package:bookapp/core/i18n/locale_provider.dart';
import 'package:bookapp/core/i18n/localization_service.dart';
import 'package:bookapp/features/auth/presentation/auth_provider.dart';
import 'package:bookapp/features/books/domain/entities/book.dart';
import 'package:bookapp/features/books/presentation/providers/book_resolve_providers.dart';
import 'package:bookapp/features/books/presentation/providers/books_providers.dart';
import 'package:bookapp/features/semantic_discovery/domain/entities/semantic_book_result.dart';
import 'package:bookapp/features/semantic_discovery/domain/entities/semantic_feedback.dart';
import 'package:bookapp/features/semantic_discovery/domain/entities/semantic_search_request.dart';
import 'package:bookapp/features/semantic_discovery/domain/repositories/semantic_discovery_repository.dart';
import 'package:bookapp/features/semantic_discovery/domain/repositories/semantic_feedback_repository.dart';
import 'package:bookapp/features/semantic_discovery/domain/usecases/search_semantic_books_usecase.dart';
import 'package:bookapp/features/semantic_discovery/presentation/providers/semantic_discovery_providers.dart';
import 'package:bookapp/features/virgil/data/datasources/virgil_usage_remote_datasource.dart';
import 'package:bookapp/features/virgil/presentation/pages/virgil_recommendation_page.dart';
import 'package:bookapp/features/virgil/presentation/providers/virgil_usage_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

const _query = 'dark fantasy';
const _isbnA = '9780000000001';
const _isbnB = '9780000000002';

class _FakeSearchRepository implements SemanticDiscoveryRepository {
  final requests = <SemanticSearchRequest>[];

  @override
  Future<List<SemanticBookResult>> search(SemanticSearchRequest request) async {
    requests.add(request);
    return [
      if (!request.irrelevantIsbns.contains(_isbnA))
        const SemanticBookResult(
          isbn13: _isbnA,
          title: 'Book A',
          author: 'Author A',
          description: '',
          similarity: 0.8,
        ),
      if (!request.irrelevantIsbns.contains(_isbnB))
        const SemanticBookResult(
          isbn13: _isbnB,
          title: 'Book B',
          author: 'Author B',
          description: '',
          similarity: 0.7,
        ),
      // Not an ISBN: must not get vote buttons.
      const SemanticBookResult(
        isbn13: 'gb:xyz',
        title: 'Book C',
        author: 'Author C',
        description: '',
      ),
    ];
  }
}

class _FakeFeedbackRepository implements SemanticFeedbackRepository {
  final submitted =
      <
        ({
          SemanticFeedbackKey key,
          String isbn,
          SemanticFeedbackVote? vote,
          int? position,
        })
      >[];

  @override
  Future<Map<String, SemanticFeedbackVote>> fetchMyVotes(
    SemanticFeedbackKey key,
  ) async => const {};

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
    submitted.add((
      key: key,
      isbn: isbn13,
      vote: vote,
      position: resultPosition,
    ));
  }
}

class _FakeUsageRemote implements VirgilUsageRemoteDataSource {
  @override
  Future<void> consume(VirgilUsageAction action) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeLocalizationService extends LocalizationService {
  @override
  Future<String?> getSavedLocale() async => 'en';

  @override
  Future<void> saveLocale(String code) async {}
}

const _me = User(
  id: 'me',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00Z',
);

void main() {
  late _FakeSearchRepository search;
  late _FakeFeedbackRepository feedback;

  setUpAll(() {
    // Env.hasSemanticApiConfig only checks that Supabase is configured.
    dotenv.loadFromString(
      envString: 'SUPABASE_URL=https://example.test\nSUPABASE_ANON_KEY=test',
    );
  });

  Future<void> pumpAndSearch(WidgetTester tester) async {
    search = _FakeSearchRepository();
    feedback = _FakeFeedbackRepository();
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(_me)),
          currentUserIdProvider.overrideWithValue(_me.id),
          localeProvider.overrideWith(
            (ref) => LocaleNotifier(
              _FakeLocalizationService(),
              initial: const Locale('en'),
            ),
          ),
          virgilUsageServiceProvider.overrideWithValue(
            VirgilUsageService(_FakeUsageRemote(), onConsumed: () {}),
          ),
          searchSemanticBooksUseCaseProvider.overrideWithValue(
            SearchSemanticBooksUseCase(search),
          ),
          semanticFeedbackRepositoryProvider.overrideWithValue(feedback),
          resolveBookProvider.overrideWith((ref, Book book) async => book),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: const [Locale('en'), Locale('tr')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const VirgilRecommendationPage(),
        ),
      ),
    );
    // The page only reads the auth state on submit; let the stream emit first
    // so the sign-in guard sees the user instead of pushing LoginPage.
    ProviderScope.containerOf(
      tester.element(find.byType(VirgilRecommendationPage)),
    ).listen(authStateProvider, (_, _) {});
    await tester.pump();

    await tester.enterText(find.byType(TextField), _query);
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
  }

  Finder voteButton(String label) => find.bySemanticsLabel(label);

  testWidgets('shows vote buttons only on results with an ISBN', (
    tester,
  ) async {
    await pumpAndSearch(tester);

    expect(find.text('Book A'), findsOneWidget);
    expect(find.text('Book C'), findsOneWidget);
    expect(voteButton('Relevant'), findsNWidgets(2));
    expect(voteButton('Not relevant'), findsNWidgets(2));
    expect(
      find.text('Mark results as relevant or not, then refine.'),
      findsOneWidget,
    );
    expect(find.text('Refine'), findsNothing);
  });

  testWidgets('votes with the search query, language and position', (
    tester,
  ) async {
    await pumpAndSearch(tester);

    await tester.tap(voteButton('Not relevant').at(1));
    await tester.pumpAndSettle();

    expect(feedback.submitted, hasLength(1));
    final sent = feedback.submitted.single;
    expect(sent.key, (query: _query, language: 'en'));
    expect(sent.isbn, _isbnB);
    expect(sent.vote, SemanticFeedbackVote.irrelevant);
    expect(sent.position, 1);

    final semantics = tester.getSemantics(voteButton('Not relevant').at(1));
    expect(semantics, isSemantics(isSelected: true, isButton: true));

    // Tapping the active mark again removes it.
    await tester.tap(voteButton('Not relevant').at(1));
    await tester.pumpAndSettle();
    expect(feedback.submitted.last.vote, isNull);
    expect(find.text('Refine'), findsNothing);
  });

  testWidgets('refines the same query from the marks and can go back', (
    tester,
  ) async {
    await pumpAndSearch(tester);
    expect(search.requests, hasLength(1));

    await tester.tap(voteButton('Relevant').at(0));
    await tester.tap(voteButton('Not relevant').at(1));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Refine'));
    await tester.pumpAndSettle();

    expect(search.requests, hasLength(2));
    final refined = search.requests.last;
    expect(refined.query, _query);
    expect(refined.relevantIsbns, [_isbnA]);
    expect(refined.irrelevantIsbns, [_isbnB]);
    expect(refined.toJson()['feedback'], {
      'relevant': [_isbnA],
      'irrelevant': [_isbnB],
    });

    // The irrelevant book is gone; the bar now reports the refinement.
    expect(find.text('Book B'), findsNothing);
    expect(find.text('Refined with your marks.'), findsOneWidget);
    expect(find.text('Refine'), findsNothing);

    await tester.tap(find.text('Original'));
    await tester.pumpAndSettle();

    expect(search.requests, hasLength(3));
    expect(search.requests.last.isRefined, isFalse);
    expect(find.text('Book B'), findsOneWidget);
    // Marks are still there, so refining is offered again.
    expect(find.text('Refine'), findsOneWidget);
  });
}
