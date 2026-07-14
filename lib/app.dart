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
import 'features/habit/presentation/widgets/habit_offline_sync_listener.dart';
import 'core/notification/reading_reminder_bootstrap.dart';
import 'features/virgil/presentation/pages/virgil_hub_page.dart';
import 'features/virgil/presentation/widgets/bottom_tab_icon.dart';

/// App-wide default; home & search tabs override to 1.0.
const double _kAppBodyFontSizeFactor = 1.2;

ThemeData _themeWithBodyFontFactor(BuildContext context, double bodyFontSizeFactor) {
  return Theme.of(context).brightness == Brightness.dark
      ? AppTheme.dark(bodyFontSizeFactor: bodyFontSizeFactor)
      : AppTheme.light(bodyFontSizeFactor: bodyFontSizeFactor);
}

class BookApp extends ConsumerStatefulWidget {
  const BookApp({super.key});

  @override
  ConsumerState<BookApp> createState() => _BookAppState();
}

class _BookAppState extends ConsumerState<BookApp> {
  int _currentIndex = 0;

  static const _homeIcon = 'assets/bottomtab/homeicon.svg';
  static const _searchIcon = 'assets/bottomtab/Search.svg';
  static const _booksIcon = 'assets/bottomtab/Books.svg';
  static const _userIcon = 'assets/bottomtab/user.svg';

  Widget _tabBody(BuildContext context) {
    // IndexedStack keeps tab state (and in-flight document uploads) alive.
    return IndexedStack(
      index: _currentIndex,
      sizing: StackFit.expand,
      children: [
        Theme(
          data: _themeWithBodyFontFactor(context, 1.0),
          child: const HomePage(),
        ),
        Theme(
          data: _themeWithBodyFontFactor(context, 1.0),
          child: const SearchPage(),
        ),
        const VirgilHubPage(),
        const ListsPage(),
        const ProfilePage(),
      ],
    );
  }

  List<NavigationDestination> _navDestinations(AppLocalizations l10n) {
    return [
      NavigationDestination(
        icon: const BottomTabIcon(assetPath: _homeIcon, size: 36),
        selectedIcon: const BottomTabSelectionHalo(
          child: BottomTabIcon(assetPath: _homeIcon, size: 36),
        ),
        label: l10n.navHome,
      ),
      NavigationDestination(
        icon: const BottomTabIcon(assetPath: _searchIcon, size: 42),
        selectedIcon: const BottomTabSelectionHalo(
          child: BottomTabIcon(assetPath: _searchIcon, size: 42),
        ),
        label: l10n.navSearch,
      ),
      NavigationDestination(
        icon: const VirgilTabMark(size: 42),
        selectedIcon: const BottomTabSelectionHalo(
          child: VirgilTabMark(size: 42),
        ),
        label: l10n.navVirgil,
      ),
      NavigationDestination(
        icon: const BottomTabIcon(assetPath: _booksIcon, size: 30),
        selectedIcon: const BottomTabSelectionHalo(
          child: BottomTabIcon(assetPath: _booksIcon, size: 30),
        ),
        label: l10n.navLists,
      ),
      NavigationDestination(
        icon: const BottomTabIcon(assetPath: _userIcon, size: 38),
        selectedIcon: const BottomTabSelectionHalo(
          child: BottomTabIcon(assetPath: _userIcon, size: 38),
        ),
        label: l10n.profile,
      ),
    ];
  }

  List<NavigationRailDestination> _railDestinations(AppLocalizations l10n) {
    return [
      NavigationRailDestination(
        icon: const BottomTabIcon(assetPath: _homeIcon, size: 36),
        selectedIcon: const BottomTabSelectionHalo(
          child: BottomTabIcon(assetPath: _homeIcon, size: 36),
        ),
        label: Text(l10n.navHome),
      ),
      NavigationRailDestination(
        icon: const BottomTabIcon(assetPath: _searchIcon, size: 42),
        selectedIcon: const BottomTabSelectionHalo(
          child: BottomTabIcon(assetPath: _searchIcon, size: 42),
        ),
        label: Text(l10n.navSearch),
      ),
      NavigationRailDestination(
        icon: const VirgilTabMark(size: 42),
        selectedIcon: const BottomTabSelectionHalo(
          child: VirgilTabMark(size: 42),
        ),
        label: Text(l10n.navVirgil),
      ),
      NavigationRailDestination(
        icon: const BottomTabIcon(assetPath: _booksIcon, size: 30),
        selectedIcon: const BottomTabSelectionHalo(
          child: BottomTabIcon(assetPath: _booksIcon, size: 30),
        ),
        label: Text(l10n.navLists),
      ),
      NavigationRailDestination(
        icon: const BottomTabIcon(assetPath: _userIcon, size: 38),
        selectedIcon: const BottomTabSelectionHalo(
          child: BottomTabIcon(assetPath: _userIcon, size: 38),
        ),
        label: Text(l10n.profile),
      ),
    ];
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
      theme: _webPageTransitions(AppTheme.light(bodyFontSizeFactor: _kAppBodyFontSizeFactor)),
      darkTheme: _webPageTransitions(AppTheme.dark(bodyFontSizeFactor: _kAppBodyFontSizeFactor)),
      themeMode: themeMode,
      home: ReadingReminderBootstrap(
        child: HabitOfflineSyncListener(
          child: Builder(
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
                          destinations: _railDestinations(l10n),
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
                    labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                    height: 82,
                    onDestinationSelected: (index) =>
                        setState(() => _currentIndex = index),
                    destinations: _navDestinations(l10n),
                  ),
          );
        },
        ),
      ),
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
