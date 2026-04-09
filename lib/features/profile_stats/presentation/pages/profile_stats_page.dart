import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/i18n/l10n/app_localizations.dart';

import '../../../auth/presentation/auth_provider.dart';
import '../../../lists/presentation/pages/lists_feed_page.dart';
import '../providers/profile_stats_providers.dart';
import '../widgets/content_stats_section.dart';
import '../widgets/library_stats_section.dart';
import '../widgets/rating_section.dart';
import '../widgets/reading_identity_section.dart';

class ProfileStatsPage extends ConsumerWidget {
  const ProfileStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.readingStats)),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              l10n.signInToSeeStats,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.readingStats),
          bottom: TabBar(tabs: [Tab(text: l10n.stats), Tab(text: l10n.navLists)]),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                ref.read(profileStatsGenerationProvider.notifier).state++;
                ref.invalidate(genreStatsProvider);
                ref.invalidate(authorStatsProvider);
                ref.invalidate(ratingStatsProvider);
                ref.invalidate(libraryStatsProvider);
                ref.invalidate(contentStatsProvider);
                ref.invalidate(profileStatsSummaryProvider);
                await Future.wait<void>([
                  ref.read(genreStatsProvider.future),
                  ref.read(authorStatsProvider.future),
                  ref.read(ratingStatsProvider.future),
                  ref.read(libraryStatsProvider.future),
                  ref.read(contentStatsProvider.future),
                ]);
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  ReadingIdentitySection(),
                  SizedBox(height: 20),
                  LibraryStatsSection(),
                  SizedBox(height: 20),
                  RatingSection(),
                  SizedBox(height: 20),
                  ContentStatsSection(),
                  SizedBox(height: 32),
                ],
              ),
            ),
            const ListsPage(embedded: true),
          ],
        ),
      ),
    );
  }
}
