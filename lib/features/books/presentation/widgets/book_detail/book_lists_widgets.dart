import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../auth/presentation/auth_provider.dart';
import '../../../../auth/presentation/sign_in_guard.dart';
import '../../../../lists/presentation/pages/book_lists_page.dart';
import '../../../../lists/presentation/providers/lists_providers.dart';
import '../../../../lists/presentation/widgets/add_to_lists_sheet.dart';
import '../../../domain/entities/book_detail_entities.dart';
import 'book_detail_common.dart';

ListBookSnapshot listBookSnapshotOf(BookEntity book) => (
  bookId: book.id,
  title: book.title,
  author: book.author,
  coverImageUrl: book.coverImageUrl,
);

/// App bar action that opens the "add to my lists" sheet; shows a check
/// once the book is in at least one of the user's lists.
class AddToListsAction extends ConsumerWidget {
  const AddToListsAction({super.key, required this.book});

  final BookEntity book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final signedIn = ref.watch(
      authStateProvider.select((auth) => auth.valueOrNull != null),
    );
    final inAnyList =
        signedIn &&
        (ref
                .watch(bookListMembershipProvider(book.id))
                .valueOrNull
                ?.isNotEmpty ??
            false);

    return IconButton(
      tooltip: inAnyList ? l10n.inMyLists : l10n.addToMyLists,
      onPressed: () async {
        if (!await ensureSignedIn(context, ref) || !context.mounted) return;
        await showAddToListsSheet(context, listBookSnapshotOf(book));
      },
      icon: Icon(
        inAnyList ? Icons.playlist_add_check : Icons.playlist_add,
        color: inAnyList ? Theme.of(context).colorScheme.primary : null,
      ),
    );
  }
}

/// "In 14 lists ›" row leading to [BookListsPage]; hidden while loading, on
/// error and when the book isn't in any list.
class BookListsEntry extends ConsumerWidget {
  const BookListsEntry({super.key, required this.book});

  final BookEntity book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count =
        ref.watch(listsContainingBookCountProvider(book.id)).valueOrNull ?? 0;
    if (count == 0) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  BookListsPage(bookId: book.id, bookTitle: book.title),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kMinTapTarget + 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.collections_bookmark_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.listsContainingBook,
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          l10n.bookInListsCount(count),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
