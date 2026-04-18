import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading.dart';
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
      fontSize: (Theme.of(context).textTheme.titleMedium?.fontSize ?? 16) * 1.1,
    );
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + AppSpacing.xs),
            child: Text(
              'Listbox',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontFamily: 'EFCOBrookshire',
                fontSize: (Theme.of(context).textTheme.headlineSmall?.fontSize ?? 24) * 1.1,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TabBar(
            isScrollable: true,
            labelStyle: tabLabelStyle,
            unselectedLabelStyle: tabLabelStyle,
            tabs: [Tab(text: l10n.myLists), Tab(text: l10n.savedLists)],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ListsTab(async: ref.watch(userListsProvider)),
                _ListsTab(async: ref.watch(savedListsProvider)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListsTab extends StatelessWidget {
  const _ListsTab({required this.async});
  final AsyncValue<List<ListEntity>> async;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return async.when(
      data: (lists) {
        if (lists.isEmpty) return Center(child: Text(l10n.noListsYet));
        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: lists.length,
          itemBuilder: (context, index) {
            final list = lists[index];
            return ListCard(
              list: list,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => ListDetailPage(list: list)),
              ),
              onLikeTap: () {},
              onSaveTap: () {},
            );
          },
        );
      },
      loading: () => ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, _) => const AppSkeletonBox(height: 92),
      ),
      error: (e, _) => Center(child: Text(l10n.couldNotLoadLists(e.toString()))),
    );
  }
}
