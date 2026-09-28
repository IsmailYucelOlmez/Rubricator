import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../auth/presentation/auth_provider.dart';
import '../../../../auth/presentation/sign_in_guard.dart';
import '../../../../book_notes/presentation/widgets/book_notes_sliver.dart';
import 'quotes_sliver.dart';
import 'reviews_sliver.dart';

enum BookContentTab { reviews, notes, quotes }

/// Reviews / notes / quotes: a tab bar that pins under the app bar, followed
/// by the selected tab's content as slivers of the page's own scroll view (no
/// nested scrolling).
class BookContentTabs extends ConsumerWidget {
  const BookContentTabs({
    super.key,
    required this.bookId,
    required this.controller,
    required this.gutter,
  });

  final String bookId;
  final TabController controller;
  final double gutter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final signedIn = ref.watch(
      authStateProvider.select((auth) => auth.valueOrNull != null),
    );

    return SliverMainAxisGroup(
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarHeader(
            gutter: gutter,
            background: theme.scaffoldBackgroundColor,
            tabBar: TabBar(
              controller: controller,
              tabAlignment: TabAlignment.fill,
              tabs: [
                Tab(text: l10n.reviews),
                Tab(text: l10n.notes),
                Tab(text: l10n.quotes),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          sliver: SliverMainAxisGroup(
            slivers: [
              if (!signedIn)
                SliverPadding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  sliver: SliverToBoxAdapter(
                    child: SignInPromptCard(
                      message: l10n.signInToJoinDiscussion,
                    ),
                  ),
                ),
              ListenableBuilder(
                listenable: controller,
                builder: (context, _) =>
                    switch (BookContentTab.values[controller.index]) {
                      BookContentTab.reviews => ReviewsSliver(bookId: bookId),
                      BookContentTab.notes => BookNotesSliver(bookId: bookId),
                      BookContentTab.quotes => QuotesSliver(bookId: bookId),
                    },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TabBarHeader extends SliverPersistentHeaderDelegate {
  const _TabBarHeader({
    required this.tabBar,
    required this.gutter,
    required this.background,
  });

  final TabBar tabBar;
  final double gutter;
  final Color background;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: background,
      elevation: overlapsContent ? 1 : 0,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: gutter - AppSpacing.md),
        child: tabBar,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarHeader oldDelegate) =>
      oldDelegate.tabBar != tabBar ||
      oldDelegate.gutter != gutter ||
      oldDelegate.background != background;
}
