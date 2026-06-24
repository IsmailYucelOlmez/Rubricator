import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/layout/app_breakpoints.dart';
import '../../../../core/layout/responsive_scaffold_body.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/ux/app_feedback.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/async_error_view.dart';
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
    final displayName = ref.watch(currentUserDisplayNameProvider);
    final isOwner = user?.id == list.userId;
    final itemsAsync = ref.watch(listItemsProvider(list.id));
    final commentsAsync = ref.watch(commentsProvider(list.id));
    final theme = Theme.of(context);
    final sectionStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          list.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
      body: SafeArea(
        child: ResponsiveScaffoldBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    if (list.description.isNotEmpty) ...[
                      Text(
                        list.description,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                    Text(
                      l10n.byUser(list.userName),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(l10n.books, style: sectionStyle),
                    const SizedBox(height: AppSpacing.xs),
                    itemsAsync.when(
                      data: (items) => items.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xs,
                              ),
                              child: Text(
                                l10n.noBooksSelectedYet,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                for (final item in items)
                                  _BookListItem(item: item),
                              ],
                            ),
                      loading: () => Column(
                        children: List.generate(
                          3,
                          (_) => const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.xs,
                            ),
                            child: AppListTileSkeleton(),
                          ),
                        ),
                      ),
                      error: (e, _) => AsyncErrorView(
                        error: e,
                        compact: true,
                        onRetry: () =>
                            ref.invalidate(listItemsProvider(list.id)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(l10n.comments, style: sectionStyle),
                    const SizedBox(height: AppSpacing.xs),
                    commentsAsync.when(
                      data: (comments) => comments.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xs,
                              ),
                              child: Text(
                                l10n.addCommentHint,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                for (final comment in comments)
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    visualDensity: VisualDensity.compact,
                                    title: Text(
                                      comment.userName,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      comment.content,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                              ],
                            ),
                      loading: () => const SizedBox.shrink(),
                      error: (e, _) => AsyncErrorView(
                        error: e,
                        compact: true,
                        onRetry: () =>
                            ref.invalidate(commentsProvider(list.id)),
                      ),
                    ),
                  ],
                ),
              ),
              if (user != null)
                Material(
                  elevation: 2,
                  color: theme.colorScheme.surface,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentCtrl,
                            decoration: InputDecoration(
                              hintText: l10n.addCommentHint,
                              isDense: true,
                            ),
                            style: theme.textTheme.bodyMedium,
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
                                    userName: displayName,
                                    listId: list.id,
                                  ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          child: _commenting
                              ? const AppLoadingIndicator(
                                  size: 18,
                                  strokeWidth: 2,
                                  centered: false,
                                )
                              : Text(l10n.send),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
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
    } catch (e) {
      if (mounted) AppFeedback.showErrorSnackBar(context, e);
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
    try {
      await ref.read(listsRepositoryProvider).deleteList(listId);
      if (!context.mounted) return;
      _invalidateAll();
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!context.mounted) return;
      AppFeedback.showErrorSnackBar(context, e);
    }
  }

  void _invalidateAll() {
    ref.invalidate(listsFeedProvider);
    ref.invalidate(popularListsProvider);
    ref.invalidate(topListsProvider);
    ref.invalidate(userListsProvider);
    ref.invalidate(savedListsProvider);
  }
}

class _BookListItem extends StatelessWidget {
  const _BookListItem({required this.item});

  final ListItemEntity item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final layoutW = MediaQuery.sizeOf(context).width;
    final basis =
        context.isTabletLayout ? AppBreakpoints.contentMaxWidth : layoutW;
    final coverWidth = (basis * 0.14).clamp(52.0, 80.0);
    final coverHeight = coverWidth * 1.4;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: coverWidth,
            height: coverHeight,
            child: BookCoverWithFavoriteButton(
              bookId: item.bookId,
              title: item.bookTitle,
              author: item.bookAuthor,
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'LTSoul',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.bookAuthor,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
                if (item.note?.isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.note!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
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
                webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
      ),
    );
  }
}
