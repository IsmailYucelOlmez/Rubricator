import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/layout/app_breakpoints.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/async_error_view.dart';
import '../../domain/entities/list_entities.dart';
import '../providers/lists_providers.dart';
import '../widgets/list_card.dart';
import 'list_detail_page.dart';

class UserListsPage extends ConsumerWidget {
  const UserListsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tabLabelStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontSize: (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) * 1.1 * 0.8,
    );
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              right: AppSpacing.md,
              top: AppSpacing.sm + AppSpacing.xs,
              bottom: AppSpacing.xs,
            ),
            child: Text(
              l10n.listsFeedHeading,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontFamily: 'Nouveau',
                fontSize: (Theme.of(context).textTheme.headlineSmall?.fontSize ?? 24) * 1.1,
              ),
            ),
          ),
          TabBar(
            isScrollable: true,
            labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            labelStyle: tabLabelStyle,
            unselectedLabelStyle: tabLabelStyle,
            tabs: [Tab(text: l10n.myLists), Tab(text: l10n.savedLists)],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ListsTab(
                  async: ref.watch(userListsProvider),
                  onRetry: () => ref.invalidate(userListsProvider),
                ),
                _ListsTab(
                  async: ref.watch(savedListsProvider),
                  onRetry: () => ref.invalidate(savedListsProvider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListsTab extends StatelessWidget {
  const _ListsTab({required this.async, required this.onRetry});
  final AsyncValue<List<ListEntity>> async;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return async.when(
      data: (lists) {
        if (lists.isEmpty) {
          return AppEmptyState(icon: Icons.collections_bookmark_outlined, title: l10n.noListsYet);
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final twoCol =
                constraints.maxWidth >= AppBreakpoints.listsTwoColumnMinWidth;
            Widget cardFor(int index) {
              final list = lists[index];
              return ListCard(
                list: list,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => ListDetailPage(list: list)),
                ),
                onLikeTap: () {},
                onSaveTap: () {},
              );
            }

            if (!twoCol) {
              return ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: lists.length,
                itemBuilder: (context, index) => cardFor(index),
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 2.45,
              ),
              itemCount: lists.length,
              itemBuilder: (context, index) => cardFor(index),
            );
          },
        );
      },
      loading: () => LayoutBuilder(
        builder: (context, constraints) {
          final twoCol =
              constraints.maxWidth >= AppBreakpoints.listsTwoColumnMinWidth;
          if (!twoCol) {
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: 5,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, _) => const AppSkeletonBox(height: 92),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 2.45,
            ),
            itemCount: 6,
            itemBuilder: (_, _) => const AppSkeletonBox(height: 92),
          );
        },
      ),
      error: (e, _) => AsyncErrorView(error: e, onRetry: onRetry),
    );
  }
}
