import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bookapp/core/i18n/l10n/app_localizations.dart';
import 'package:bookapp/features/auth/presentation/auth_provider.dart';
import 'package:bookapp/features/lists/domain/entities/list_entities.dart';
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
  _list(id: '2', title: 'Yaz Okumaları', description: 'Sahilde okunacak hafif romanlar'),
  _list(id: '3', title: 'Bilim Kurgu Seçkisi', description: 'Uzay ve teknoloji temalı distopya'),
];

void main() {
  testWidgets('search field filters lists by title or description', (tester) async {
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

    // All three lists render initially (For You tab, first tab).
    expect(find.text('Distopik Klasikler'), findsOneWidget);
    expect(find.text('Yaz Okumaları'), findsOneWidget);
    expect(find.text('Bilim Kurgu Seçkisi'), findsOneWidget);

    // Search by title fragment.
    await tester.enterText(find.byType(TextField), 'distopik');
    await tester.pumpAndSettle();

    expect(find.text('Distopik Klasikler'), findsOneWidget);
    expect(find.text('Yaz Okumaları'), findsNothing);
    expect(find.text('Bilim Kurgu Seçkisi'), findsNothing);

    // Search by description fragment (matches a different list than the title search).
    await tester.enterText(find.byType(TextField), 'distopya');
    await tester.pumpAndSettle();

    expect(find.text('Bilim Kurgu Seçkisi'), findsOneWidget);
    expect(find.text('Distopik Klasikler'), findsNothing);
    expect(find.text('Yaz Okumaları'), findsNothing);

    // No match -> empty state, not the "no lists yet" message.
    await tester.enterText(find.byType(TextField), 'zzz-no-match-zzz');
    await tester.pumpAndSettle();

    expect(find.text('Distopik Klasikler'), findsNothing);
    expect(find.text('Yaz Okumaları'), findsNothing);
    expect(find.text('Bilim Kurgu Seçkisi'), findsNothing);

    // Clearing the query restores all lists.
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();

    expect(find.text('Distopik Klasikler'), findsOneWidget);
    expect(find.text('Yaz Okumaları'), findsOneWidget);
    expect(find.text('Bilim Kurgu Seçkisi'), findsOneWidget);
  });
}
