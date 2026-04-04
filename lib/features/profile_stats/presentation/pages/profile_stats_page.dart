import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/auth_provider.dart';
import '../providers/profile_stats_providers.dart';
import '../widgets/content_stats_section.dart';
import '../widgets/library_stats_section.dart';
import '../widgets/rating_section.dart';
import '../widgets/reading_identity_section.dart';

class ProfileStatsPage extends ConsumerWidget {
  const ProfileStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reading stats')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Sign in to see your library analytics and reading identity.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Reading stats')),
      body: RefreshIndicator(
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
    );
  }
}
