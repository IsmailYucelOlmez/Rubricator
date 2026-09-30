import 'package:bookapp/core/i18n/l10n/app_localizations.dart';
import 'package:bookapp/features/auth/presentation/auth_provider.dart';
import 'package:bookapp/features/books/domain/entities/book.dart';
import 'package:bookapp/features/books/domain/entities/book_detail_entities.dart';
import 'package:bookapp/features/books/domain/repositories/book_detail_repository.dart';
import 'package:bookapp/features/books/presentation/pages/book_detail_page.dart';
import 'package:bookapp/features/books/presentation/providers/books_providers.dart';
import 'package:bookapp/features/lists/data/repositories/in_memory_lists_repository.dart';
import 'package:bookapp/features/lists/domain/repositories/lists_repository.dart';
import 'package:bookapp/features/lists/presentation/providers/lists_providers.dart';
import 'package:bookapp/features/lists/presentation/widgets/list_card.dart';
import 'package:bookapp/features/user_books/data/user_books_repository.dart';
import 'package:bookapp/features/user_books/domain/entities/user_book_entity.dart';
import 'package:bookapp/features/user_books/domain/entities/user_book_snapshot.dart';
import 'package:bookapp/features/user_books/presentation/providers/user_books_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

class _FakeRepository implements BookDetailRepository {
  @override
  Future<List<ReviewEntity>> getReviews(String bookId) async => [
    for (var i = 0; i < 12; i++)
      ReviewEntity(
        id: 'r$i',
        bookId: bookId,
        userId: 'u$i',
        content: 'Review number $i with enough text to wrap a little.',
        createdAt: DateTime(2026, 9, 1),
        likes: 12 - i,
        userName: 'Reader $i',
        isSpoiler: i == 1,
      ),
  ];

  @override
  Future<List<ExternalReviewEntity>> getExternalReviews(String bookId) async =>
      [];

  @override
  Future<List<QuoteEntity>> getQuotes(String bookId) async => [
    QuoteEntity(
      id: 'q1',
      bookId: bookId,
      userId: 'u1',
      content: 'A memorable quote.',
      likes: 2,
      createdAt: DateTime(2026, 9, 1),
    ),
  ];

  @override
  Future<RatingSummary> getRatingSummary(String bookId) async =>
      const RatingSummary(average: 8.4, count: 38);

  @override
  Future<int?> getUserRating(String bookId) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeUserBooksRepository extends UserBooksRepository {
  _FakeUserBooksRepository(this.userBook);

  UserBookEntity? userBook;
  int deletes = 0;

  @override
  Future<UserBookEntity?> getUserBook(String bookId) async => userBook;

  @override
  Future<void> deleteUserBook(String bookId) async {
    deletes++;
    userBook = null;
  }

  @override
  Future<void> upsertUserBook({
    required String bookId,
    required ReadingStatus status,
    bool? isFavorite,
    int? progress,
    UserBookSnapshot? snapshot,
  }) async {}
}

const _book = Book(
  id: 'trbooks:1',
  title: 'Gece Yarısı Treni',
  author: 'Matt Haig',
  description: 'A long description. ',
);

const _me = User(
  id: 'me',
  appMetadata: {},
  userMetadata: {},
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00Z',
);

Future<void> _pumpPage(
  WidgetTester tester, {
  User? user,
  UserBooksRepository? userBooks,
  ListsRepository? lists,
}) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bookDetailRepositoryProvider.overrideWithValue(_FakeRepository()),
        authStateProvider.overrideWith((ref) => Stream.value(user)),
        currentUserIdProvider.overrideWithValue(user?.id),
        if (userBooks != null)
          userBooksRepositoryProvider.overrideWithValue(userBooks),
        relatedBooksProvider.overrideWith((ref, key) async => const <Book>[]),
        listsRepositoryProvider.overrideWithValue(
          lists ?? InMemoryListsRepository(),
        ),
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
        home: const BookDetailPage(book: _book),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('shows the rating summary under the author', (tester) async {
    await _pumpPage(tester);
    expect(find.text('4.2'), findsOneWidget);
    expect(find.text('(38 oy)'), findsOneWidget);
    expect(find.text('Giriş yap'), findsWidgets);
  });

  testWidgets('pins the tab bar and shows the title after scrolling', (
    tester,
  ) async {
    await _pumpPage(tester);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -1500));
    await tester.pumpAndSettle();

    final tabBar = find.byType(TabBar);
    expect(tabBar, findsOneWidget);
    expect(tester.getTopLeft(tabBar).dy, kToolbarHeight);
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Gece Yarısı Treni'),
      ),
      findsOneWidget,
    );
    // Most-liked review first, the rest built lazily below it.
    expect(find.text('Reader 11'), findsNothing);

    await tester.tap(find.text('Alıntılar'));
    await tester.pumpAndSettle();
    expect(find.text('A memorable quote.'), findsOneWidget);
  });

  testWidgets('completed shows full progress; tapping it again removes', (
    tester,
  ) async {
    final userBooks = _FakeUserBooksRepository(
      UserBookEntity(
        id: 'ub1',
        userId: 'me',
        bookId: _book.id,
        status: ReadingStatus.completed,
        isFavorite: false,
        progress: null,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    );
    await _pumpPage(tester, user: _me, userBooks: userBooks);
    await tester.pumpAndSettle();

    expect(find.text('İlerleme: %100'), findsOneWidget);
    expect(find.text('Senin puanın'), findsOneWidget);

    await tester.tap(find.text('Değiştir'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Tamamlandı'));
    await tester.pumpAndSettle();

    expect(userBooks.deletes, 1);
    expect(find.text('Listeye Ekle'), findsOneWidget);
    expect(find.text('Listenden çıkarıldı.'), findsOneWidget);
  });

  testWidgets('adds the book to an own list and lists the lists with it', (
    tester,
  ) async {
    final lists = InMemoryListsRepository();
    await lists.addBookToList(
      listId: 'l1',
      bookId: _book.id,
      title: _book.title,
      author: _book.author,
    );
    await lists.createList(
      userId: 'me',
      userName: 'Me',
      title: 'Benim listem',
      description: '',
      isPublic: true,
    );
    await _pumpPage(
      tester,
      user: _me,
      userBooks: _FakeUserBooksRepository(null),
      lists: lists,
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('1 listede'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('1 listede'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.playlist_add));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Benim listem'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CheckboxListTile>(
            find.widgetWithText(CheckboxListTile, 'Benim listem'),
          )
          .value,
      isTrue,
    );

    // Close the sheet.
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.playlist_add_check), findsOneWidget);
    expect(find.text('2 listede'), findsOneWidget);

    await tester.tap(find.text('2 listede'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widgetList<ListCard>(find.byType(ListCard))
          .map((card) => card.list.title),
      unorderedEquals(['Benim listem', 'Comfort Reads for Rainy Days']),
    );
  });
}
