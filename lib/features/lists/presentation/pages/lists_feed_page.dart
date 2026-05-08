import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/async_error_view.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../domain/entities/list_entities.dart';
import '../providers/lists_providers.dart';
import '../widgets/list_card.dart';
import 'create_edit_list_page.dart';
import 'list_detail_page.dart';
import 'user_lists_page.dart';

class ListsPage extends ConsumerWidget {
  const ListsPage({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tabLabelStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontSize: (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) * 1.1,
    );
    void invalidateAll() {
      ref.invalidate(listsFeedProvider);
      ref.invalidate(popularListsProvider);
      ref.invalidate(topListsProvider);
      ref.invalidate(followingListsProvider);
      ref.invalidate(userListsProvider);
      ref.invalidate(savedListsProvider);
    }

    final body = DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + AppSpacing.xs),
            child: Row(
              children: [
                if (!embedded)
                  Text(
                    l10n.listsFeedHeading,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontFamily: 'Nouveau',
                      fontSize: (Theme.of(context).textTheme.headlineSmall?.fontSize ?? 24) * 1.1,
                    ),
                  ),
                if (!embedded) const Spacer(),
                IconButton(
                  tooltip: l10n.myListsTooltip,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(body: SafeArea(child: UserListsPage())),
                    ),
                  ),
                  icon: const Icon(Icons.collections_bookmark_outlined),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const CreateEditListPage()),
                    );
                    invalidateAll();
                  },
                  icon: const Icon(Icons.add),
                  label: Text(l10n.createList),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: TabBar(
              isScrollable: false,
              splashFactory: NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              labelStyle: tabLabelStyle,
              unselectedLabelStyle: tabLabelStyle,
              tabs: [
                Tab(text: l10n.listsForYou),
                Tab(text: l10n.popular),
                Tab(text: l10n.listsTopTwenty),
                Tab(text: l10n.listsFollowing),
              ],
            ),
          ),
          Expanded(
            child: ScrollConfiguration(
              behavior: const _NoTabViewEdgeGlowScrollBehavior(),
              child: TabBarView(
                physics: const ClampingScrollPhysics(),
                children: [
                  _FeedTab(
                    async: ref.watch(forYouListsProvider),
                    onChanged: invalidateAll,
                    onRetry: () => ref.invalidate(forYouListsProvider),
                  ),
                  _FeedTab(
                    async: ref.watch(popularListsProvider),
                    onChanged: invalidateAll,
                    onRetry: () => ref.invalidate(popularListsProvider),
                  ),
                  _FeedTab(
                    async: ref.watch(topListsProvider),
                    onChanged: invalidateAll,
                    onRetry: () => ref.invalidate(topListsProvider),
                  ),
                  _FeedTab(
                    async: ref.watch(followingListsProvider),
                    onChanged: invalidateAll,
                    onRetry: () => ref.invalidate(followingListsProvider),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
    if (embedded) return body;
    return SafeArea(child: body);
  }
}

/// Removes Android overscroll glow / edge shading on horizontal [TabBarView] swipes.
class _NoTabViewEdgeGlowScrollBehavior extends MaterialScrollBehavior {
  const _NoTabViewEdgeGlowScrollBehavior();

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class _FeedTab extends ConsumerWidget {
  const _FeedTab({required this.async, required this.onChanged, required this.onRetry});
  final AsyncValue<List<ListEntity>> async;
  final VoidCallback onChanged;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return async.when(
      data: (lists) {
        final l10n = AppLocalizations.of(context)!;
        if (lists.isEmpty) {
          return AppEmptyState(
            icon: Icons.menu_book_outlined,
            title: l10n.noListsYet,
          );
        }
        final userId = ref.watch(authStateProvider).valueOrNull?.id;
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: lists.length,
          itemBuilder: (context, index) {
            final list = lists[index];
            return ListCard(
              list: list,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => ListDetailPage(list: list)),
                );
                onChanged();
              },
              onLikeTap: () async {
                if (userId == null) return;
                if (list.isLikedByMe) {
                  await ref.read(listsRepositoryProvider).unlikeList(userId, list.id);
                } else {
                  await ref.read(listsRepositoryProvider).likeList(userId, list.id);
                }
                onChanged();
              },
              onSaveTap: () async {
                if (userId == null) return;
                if (list.isSavedByMe) {
                  await ref.read(listsRepositoryProvider).unsaveList(userId, list.id);
                } else {
                  await ref.read(listsRepositoryProvider).saveList(userId, list.id);
                }
                onChanged();
              },
            );
          },
        );
      },
      loading: () => ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, _) => const AppSkeletonBox(height: 120),
      ),
      error: (e, _) => AsyncErrorView(error: e, onRetry: onRetry),
    );
  }
}
