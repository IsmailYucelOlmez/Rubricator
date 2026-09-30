import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/ux/app_feedback.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/async_error_view.dart';
import '../../domain/entities/list_entities.dart';
import '../pages/create_edit_list_page.dart';
import '../providers/lists_providers.dart';

/// Lets the signed-in user add [book] to, or remove it from, their own lists.
/// Each row toggles immediately; the last row starts a new list with the book.
Future<void> showAddToListsSheet(BuildContext context, ListBookSnapshot book) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _AddToListsSheet(book: book),
  );
}

class _AddToListsSheet extends ConsumerWidget {
  const _AddToListsSheet({required this.book});

  final ListBookSnapshot book;

  Future<void> _createList(BuildContext context, WidgetRef ref) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => CreateEditListPage(initialBook: book),
      ),
    );
    if (created != true) return;
    ref.invalidate(bookListMembershipProvider(book.bookId));
    ref.invalidate(listsContainingBookProvider(book.bookId));
    ref.invalidate(listsContainingBookCountProvider(book.bookId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lists = ref.watch(userListsProvider);
    final membership = ref.watch(bookListMembershipProvider(book.bookId));

    void retry() {
      ref.invalidate(userListsProvider);
      ref.invalidate(bookListMembershipProvider(book.bookId));
    }

    // Keep showing the previous values while either provider refreshes
    // (every toggle invalidates the user's lists for their preview covers).
    final Widget body = switch ((lists.valueOrNull, membership.valueOrNull)) {
      (final lists?, _?) when lists.isEmpty => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          l10n.noListsYet,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
      ),
      (final lists?, final members?) => ListView.builder(
        shrinkWrap: true,
        itemCount: lists.length,
        itemBuilder: (context, index) => _ListRow(
          list: lists[index],
          selected: members.containsKey(lists[index].id),
          onTap: () async {
            try {
              await ref
                  .read(bookListMembershipProvider(book.bookId).notifier)
                  .toggle(lists[index].id, book);
            } catch (e) {
              if (context.mounted) AppFeedback.showErrorSnackBar(context, e);
            }
          },
        ),
      ),
      _ when lists.hasError || membership.hasError => AsyncErrorView(
        error: (lists.error ?? membership.error)!,
        compact: true,
        onRetry: retry,
      ),
      _ => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: AppLoadingIndicator(),
      ),
    };

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Text(
                l10n.addToMyLists,
                style: theme.textTheme.titleMedium,
              ),
            ),
            Flexible(child: body),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(l10n.createListWithBook),
              onTap: () => _createList(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.list,
    required this.selected,
    required this.onTap,
  });

  final ListEntity list;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CheckboxListTile(
      value: selected,
      onChanged: (_) => onTap(),
      controlAffinity: ListTileControlAffinity.trailing,
      secondary: Icon(
        list.isPublic ? Icons.format_list_bulleted : Icons.lock_outline,
      ),
      title: Text(list.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: list.isPublic ? null : Text(l10n.privateList),
    );
  }
}
