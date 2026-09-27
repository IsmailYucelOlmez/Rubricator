import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bookapp/core/i18n/l10n/app_localizations.dart';
import 'package:bookapp/features/auth/presentation/auth_provider.dart';
import 'package:bookapp/features/lists/domain/entities/list_entities.dart';
import 'package:bookapp/features/lists/presentation/pages/list_search_page.dart';
import 'package:bookapp/features/lists/presentation/pages/lists_feed_page.dart';
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

final _lists = [
  _list(id: '1', title: 'Distopik Klasikler', description: '1984 ve benzeri kitaplar'),
];

void main() {
  testWidgets('search bar sits above the tabs and opens ListSearchPage on tap', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
          forYouListsProvider.overrideWith((ref) => Future.value(_lists)),
          popularListsProvider.overrideWith((ref) => Future.value(_lists)),
          topListsProvider.overrideWith((ref) => Future.value(_lists)),
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
          home: const Scaffold(body: ListsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Search bar renders above the TabBar, not editable inline.
    final hint = lookupAppLocalizations(const Locale('tr')).searchListsHint;
    final searchBarFinder = find.text(hint);
    final tabBarFinder = find.byType(TabBar);
    expect(searchBarFinder, findsOneWidget);
    expect(tabBarFinder, findsOneWidget);
    final searchBarTop = tester.getTopLeft(searchBarFinder).dy;
    final tabBarTop = tester.getTopLeft(tabBarFinder).dy;
    expect(searchBarTop, lessThan(tabBarTop));

    // Tapping it navigates to the dedicated search page instead of filtering inline.
    await tester.tap(searchBarFinder);
    await tester.pumpAndSettle();

    expect(find.byType(ListSearchPage), findsOneWidget);
  });
}
