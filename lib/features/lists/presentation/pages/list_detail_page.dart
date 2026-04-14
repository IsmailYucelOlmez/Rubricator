import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../books/presentation/widgets/book_cover_with_favorite_button.dart';
import '../../domain/entities/list_entities.dart';
import '../providers/lists_providers.dart';
import 'create_edit_list_page.dart';

class ListDetailPage extends ConsumerStatefulWidget {
  const ListDetailPage({super.key, required this.list});

  final ListEntity list;

  @override
  ConsumerState<ListDetailPage> createState() => _ListDetailPageState();
}

class _ListDetailPageState extends ConsumerState<ListDetailPage> {
  final _commentCtrl = TextEditingController();
  bool _commenting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final list = widget.list;
    final user = ref.watch(authStateProvider).valueOrNull;
    final isOwner = user?.id == list.userId;
    final itemsAsync = ref.watch(listItemsProvider(list.id));
    final commentsAsync = ref.watch(commentsProvider(list.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(list.title),
        actions: [
          if (isOwner)
            IconButton(
              tooltip: l10n.editListTooltip,
              onPressed: () async {
                final changed = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => CreateEditListPage(initialList: list),
                  ),
                );
                if (!context.mounted) return;
                if (changed == true) {
                  _invalidateAll();
                  Navigator.of(context).pop(true);
                }
              },
              icon: const Icon(Icons.edit_outlined),
            ),
          if (isOwner)
            IconButton(
              tooltip: l10n.deleteListTooltip,
              onPressed: () => _deleteList(context, list.id),
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(list.description),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.byUser(list.userName), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.books, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          itemsAsync.when(
            data: (items) => Column(
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Builder(
                      builder: (context) {
                        final coverWidth = MediaQuery.of(context).size.width * 0.20;
                        final coverHeight = coverWidth * 1.4;
                        return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: coverWidth,
                          height: coverHeight,
                          child: BookCoverWithFavoriteButton(
                            bookId: item.bookId,
                            compact: true,
                            child: _Cover(coverImageUrl: item.coverImageUrl),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.bookTitle,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontFamily: 'Yellowtail',
                                ),
                              ),
                              Text(
                                item.note?.isNotEmpty == true
                                    ? '${item.bookAuthor}\n${item.note}'
                                    : item.bookAuthor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                      },
                    ),
                  ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(l10n.couldNotLoadListItems(e.toString())),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.comments, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          commentsAsync.when(
            data: (comments) => Column(
              children: [
                for (final comment in comments)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(comment.userName),
                    subtitle: Text(comment.content),
                  ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (e, _) => Text(l10n.couldNotLoadComments(e.toString())),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (user != null)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    decoration: InputDecoration(
                      hintText: l10n.addCommentHint,
                      isDense: true,
                    ),
                    minLines: 1,
                    maxLines: 3,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilledButton(
                  onPressed: _commenting
                      ? null
                      : () => _addComment(
                            userId: user.id,
                            userName: (user.email ?? 'user').split('@').first,
                            listId: list.id,
                          ),
                  child: _commenting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.send),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _addComment({
    required String userId,
    required String userName,
    required String listId,
  }) async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _commenting = true);
    try {
      await ref.read(listsRepositoryProvider).addComment(
            userId: userId,
            userName: userName,
            listId: listId,
            content: text,
          );
      _commentCtrl.clear();
      ref.invalidate(commentsProvider(listId));
      _invalidateAll();
    } finally {
      if (mounted) setState(() => _commenting = false);
    }
  }

  Future<void> _deleteList(BuildContext context, String listId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deleteListTitle),
        content: Text(l10n.deleteListConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.delete)),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(listsRepositoryProvider).deleteList(listId);
    if (!context.mounted) return;
    _invalidateAll();
    Navigator.of(context).pop(true);
  }

  void _invalidateAll() {
    ref.invalidate(listsFeedProvider);
    ref.invalidate(popularListsProvider);
    ref.invalidate(followingListsProvider);
    ref.invalidate(userListsProvider);
    ref.invalidate(savedListsProvider);
  }
}

class _Cover extends StatelessWidget {
  const _Cover({this.coverImageUrl});
  final String? coverImageUrl;

  @override
  Widget build(BuildContext context) {
    final imageUrl = AppConstants.bookThumbnailUrl(coverImageUrl);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: double.infinity,
        child: imageUrl == null
            ? Container(color: Theme.of(context).colorScheme.surfaceContainerHighest)
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
      ),
    );
  }
}
