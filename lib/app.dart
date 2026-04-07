import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/i18n/locale_provider.dart';
import 'core/i18n/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/favorites/presentation/favorites_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/search/presentation/pages/search_page.dart';
import 'features/auth/presentation/profile_page.dart';

class BookApp extends ConsumerStatefulWidget {
  const BookApp({super.key});

  @override
  ConsumerState<BookApp> createState() => _BookAppState();
}

class _BookAppState extends ConsumerState<BookApp> {
  int _currentIndex = 0;

  static const _pages = [
    HomePage(),
    SearchPage(),
    ListsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    return MaterialApp(
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          return Scaffold(
            body: _pages[_currentIndex],
            bottomNavigationBar: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) => setState(() => _currentIndex = index),
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.menu_book_outlined),
                  selectedIcon: const Icon(Icons.menu_book),
                  label: l10n.navHome,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.search_outlined),
                  selectedIcon: const Icon(Icons.search),
                  label: l10n.navSearch,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.library_books_outlined),
                  selectedIcon: const Icon(Icons.library_books),
                  label: l10n.navLists,
                ),
                NavigationDestination(
                  icon: const Icon(Icons.person_outline),
                  selectedIcon: const Icon(Icons.person),
                  label: l10n.profile,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
