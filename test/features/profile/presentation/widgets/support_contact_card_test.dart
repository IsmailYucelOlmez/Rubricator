import 'package:bookapp/core/i18n/l10n/app_localizations.dart';
import 'package:bookapp/features/auth/presentation/auth_provider.dart';
import 'package:bookapp/features/profile/data/support_contact_service.dart';
import 'package:bookapp/features/profile/presentation/widgets/support_contact_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

class _FakeService implements SupportContactService {
  _FakeService({this.error});

  final SupportContactException? error;
  final sent = <({String message, String name, String lang})>[];

  @override
  Future<void> send({
    required String message,
    required String name,
    required String lang,
  }) async {
    if (error != null) throw error!;
    sent.add((message: message, name: name, lang: lang));
  }
}

const _user = User(
  id: 'u1',
  appMetadata: {},
  userMetadata: {'username': 'Okur'},
  aud: 'authenticated',
  createdAt: '2026-01-01T00:00:00Z',
  email: 'okur@example.com',
);

Future<void> _pump(WidgetTester tester, _FakeService service) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream.value(_user)),
        supportContactServiceProvider.overrideWithValue(service),
      ],
      child: const MaterialApp(
        locale: Locale('tr'),
        supportedLocales: [Locale('en'), Locale('tr')],
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: SingleChildScrollView(child: SupportContactCard()),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('a short message is rejected locally', (tester) async {
    final service = _FakeService();
    await _pump(tester, service);

    await tester.enterText(find.byType(TextField), 'kısa');
    await tester.tap(find.text('Gönder'));
    await tester.pump();

    expect(find.text('Lütfen en az 10 karakter yaz.'), findsOneWidget);
    expect(service.sent, isEmpty);
  });

  testWidgets('a valid message is sent and the field cleared', (tester) async {
    final service = _FakeService();
    await _pump(tester, service);

    expect(find.textContaining('okur@example.com'), findsNothing);
    await tester.enterText(find.byType(TextField), 'Uygulama çok güzel olmuş!');
    await tester.tap(find.text('Gönder'));
    await tester.pump();
    await tester.pump();

    expect(service.sent.single.message, 'Uygulama çok güzel olmuş!');
    expect(service.sent.single.name, 'Okur');
    expect(service.sent.single.lang, 'tr');
    expect(find.text('Mesajın gönderildi. Teşekkürler!'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });

  testWidgets('the rate limit is explained', (tester) async {
    final service = _FakeService(
      error: const SupportContactException('rate_limited'),
    );
    await _pump(tester, service);

    await tester.enterText(find.byType(TextField), 'Uygulama çok güzel olmuş!');
    await tester.tap(find.text('Gönder'));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('bir saat sonra'), findsOneWidget);
  });
}
