import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/i18n/locale_provider.dart';
import 'core/i18n/l10n/app_localizations.dart';
import 'core/network/connectivity_provider.dart';
import 'core/layout/app_breakpoints.dart';
import 'core/layout/responsive_scaffold_body.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'core/theme/app_spacing.dart';
import 'features/lists/presentation/pages/lists_feed_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/search/presentation/pages/search_page.dart';
import 'features/auth/presentation/profile_page.dart';

/// App-wide default; home & search tabs override to 1.0.
const double _kAppCesareFontSizeFactor = 1.2;

ThemeData _themeWithCesareFactor(BuildContext context, double cesareFontSizeFactor) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppTheme.dark(cesareFontSizeFactor: cesareFontSizeFactor)
      : AppTheme.light(cesareFontSizeFactor: cesareFontSizeFactor);
}

class BookApp extends ConsumerStatefulWidget {
  const BookApp({super.key});

  @override
  ConsumerState<BookApp> createState() => _BookAppState();
}

class _BookAppState extends ConsumerState<BookApp> {
  int _currentIndex = 0;

  Widget _tabBody(BuildContext context) {
    return switch (_currentIndex) {
      0 => Theme(
          data: _themeWithCesareFactor(context, 1.0),
          child: const HomePage(),
        ),
      1 => Theme(
          data: _themeWithCesareFactor(context, 1.0),
          child: const SearchPage(),
        ),
      2 => const ListsPage(),
      3 => const ProfilePage(),
      _ => Theme(
          data: _themeWithCesareFactor(context, 1.0),
          child: const HomePage(),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
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
      theme: _webPageTransitions(AppTheme.light(cesareFontSizeFactor: _kAppCesareFontSizeFactor)),
      darkTheme: _webPageTransitions(AppTheme.dark(cesareFontSizeFactor: _kAppCesareFontSizeFactor)),
      themeMode: themeMode,
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          final tablet = context.isTabletLayout;
          final offlineBanner = Consumer(
            builder: (context, ref, _) {
              final offline = ref.watch(isOfflineProvider);
              if (!offline) return const SizedBox.shrink();
              final scheme = Theme.of(context).colorScheme;
              return Material(
                color: scheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      children: [
                        Icon(Icons.wifi_off, size: 18, color: scheme.onErrorContainer),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            l10n.uxOfflineBanner,
                            style: TextStyle(color: scheme.onErrorContainer),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
          final tabPane = Expanded(
            child: ResponsiveScaffoldBody(child: _tabBody(context)),
          );
          return Scaffold(
            body: tablet
                ? SafeArea(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        NavigationRail(
                          extended: false,
                          labelType: NavigationRailLabelType.all,
                          selectedIndex: _currentIndex,
                          onDestinationSelected: (index) =>
                              setState(() => _currentIndex = index),
                          destinations: [
                            NavigationRailDestination(
                              icon: const Icon(Icons.home_outlined),
                              selectedIcon: const Icon(Icons.home),
                              label: Text(l10n.navHome),
                            ),
                            NavigationRailDestination(
                              icon: const Icon(Icons.search),
                              selectedIcon: const Icon(Icons.search),
                              label: Text(l10n.navSearch),
                            ),
                            NavigationRailDestination(
                              icon: const Icon(Icons.menu_book_outlined),
                              selectedIcon: const Icon(Icons.menu_book),
                              label: Text(l10n.navLists),
                            ),
                            NavigationRailDestination(
                              icon: const Icon(Icons.person_outline),
                              selectedIcon: const Icon(Icons.person),
                              label: Text(l10n.profile),
                            ),
                          ],
                        ),
                        const VerticalDivider(width: 1, thickness: 1),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              offlineBanner,
                              tabPane,
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      offlineBanner,
                      tabPane,
                    ],
                  ),
            bottomNavigationBar: tablet
                ? null
                : NavigationBar(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: (index) =>
                        setState(() => _currentIndex = index),
                    destinations: [
                      NavigationDestination(
                        icon: const Icon(Icons.home_outlined),
                        selectedIcon: const Icon(Icons.home),
                        label: l10n.navHome,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.search, fill: 0),
                        selectedIcon: const Icon(Icons.search, fill: 1),
                        label: l10n.navSearch,
                      ),
                      NavigationDestination(
                        icon: const Icon(Icons.menu_book_outlined),
                        selectedIcon: const Icon(Icons.menu_book),
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

/// On web, default Material route transitions apply opacity to the outgoing
/// route, which often forces `Image.network` off the HTML `<img>` path and
/// triggers same-origin errors for cross-origin cover thumbnails.
ThemeData _webPageTransitions(ThemeData base) {
  if (!kIsWeb) return base;
  const builder = _InstantPageTransitionsBuilder();
  return base.copyWith(
    pageTransitionsTheme: PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        for (final p in TargetPlatform.values) p: builder,
      },
    ),
  );
}

class _InstantPageTransitionsBuilder extends PageTransitionsBuilder {
  const _InstantPageTransitionsBuilder();

  @override
  Widget buildTransitions<T extends Object?>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
