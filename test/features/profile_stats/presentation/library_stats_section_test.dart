import 'dart:io';

import 'package:bookapp/core/i18n/l10n/app_localizations.dart';
import 'package:bookapp/core/theme/app_theme.dart';
import 'package:bookapp/features/profile_stats/domain/entities/profile_stats_entities.dart';
import 'package:bookapp/features/profile_stats/presentation/providers/profile_stats_providers.dart';
import 'package:bookapp/features/profile_stats/presentation/widgets/library_stats_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the real Outfit font so label widths match the device (the default
/// test font renders every glyph as a 1em square).
Future<void> _loadOutfit() async {
  final loader = FontLoader('Outfit');
  for (final weight in ['Regular', 'Medium', 'SemiBold']) {
    final bytes = File(
      'assets/Virgil/Outfit/static/Outfit-$weight.ttf',
    ).readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

void main() {
  setUpAll(_loadOutfit);

  for (final width in [320.0, 360.0, 412.0]) {
    testWidgets('Turkish stat labels stay on one line at ${width}px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width * 3, 1600);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            libraryStatsProvider.overrideWith(
              (ref) async => const LibraryStat(
                toRead: 128,
                reading: 12,
                completed: 347,
                dropped: 9,
                favorites: 56,
              ),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('tr'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // Same body size factor as the real app (lib/app.dart).
            theme: AppTheme.light(bodyFontSizeFactor: 1.2),
            home: const Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: LibraryStatsSection(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final columns = {
        for (final label in ['Okunacak', 'Okunuyor', 'Tamamlandı'])
          tester.getRect(find.text(label)).left.round(),
      }.length;
      // ignore: avoid_print
      print('${width}px  columns: $columns');
      for (final label in ['Okunacak', 'Okunuyor', 'Tamamlandı', 'Bırakıldı', 'Favoriler']) {
        final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
        final oneLine = TextPainter(
          text: paragraph.text,
          textDirection: TextDirection.ltr,
          textScaler: paragraph.textScaler,
        )..layout();
        // ignore: avoid_print
        print('${width}px  $label: width ${oneLine.width.toStringAsFixed(1)}, '
            'box ${paragraph.size.width.toStringAsFixed(1)}, '
            'height ${paragraph.size.height.toStringAsFixed(1)} '
            '(one line ${oneLine.height.toStringAsFixed(1)})');
        expect(paragraph.didExceedMaxLines, isFalse, reason: label);
        expect(paragraph.size.height, closeTo(oneLine.height, 0.5), reason: label);
        oneLine.dispose();
      }
      expect(find.text('Tamamlandı'), findsOneWidget);
    });
  }
}
