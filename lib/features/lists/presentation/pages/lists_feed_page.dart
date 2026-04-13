import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
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
    void invalidateAll() {
      ref.invalidate(listsFeedProvider);
      ref.invalidate(popularListsProvider);
      ref.invalidate(followingListsProvider);
      ref.invalidate(userListsProvider);
      ref.invalidate(savedListsProvider);
    }

    final body = DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + AppSpacing.xs),
            child: Row(
              children: [
                if (!embedded)
                  Text(
                    'Listbox',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontFamily: 'EFCOBrookshire',
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
          TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: l10n.listsForYou),
              Tab(text: l10n.popular),
              Tab(text: l10n.listsFollowing),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _FeedTab(async: ref.watch(listsFeedProvider), onChanged: invalidateAll),
                _FeedTab(async: ref.watch(popularListsProvider), onChanged: invalidateAll),
                _FeedTab(async: ref.watch(followingListsProvider), onChanged: invalidateAll),
              ],
            ),
          ),
        ],
      ),
    );
    if (embedded) return body;
    return SafeArea(child: body);
  }
}

class _FeedTab extends ConsumerWidget {
  const _FeedTab({required this.async, required this.onChanged});
  final AsyncValue<List<ListEntity>> async;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return async.when(
      data: (lists) {
        final l10n = AppLocalizations.of(context)!;
        if (lists.isEmpty) return Center(child: Text(l10n.noListsYet));
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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(AppLocalizations.of(context)!.couldNotLoadLists(e.toString()))),
    );
  }
}
