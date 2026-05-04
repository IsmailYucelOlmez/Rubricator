import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/async_error_view.dart';
import '../../../books/presentation/pages/book_detail_page.dart';
import '../../../user_books/domain/entities/user_book_entity.dart';
import '../favorites_provider.dart';

class ReadingStatusListPage extends ConsumerWidget {
  const ReadingStatusListPage({
    super.key,
    this.status,
    this.showFavoritesOnly = false,
  });

  final ReadingStatus? status;
  final bool showFavoritesOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final title = showFavoritesOnly
        ? l10n.favorites
        : status == null
        ? l10n.navLists
        : _statusLabel(status!, l10n);
    final entriesAsync = showFavoritesOnly
        ? ref.watch(favoriteEntriesProvider)
        : ref.watch(listEntriesByStatusProvider(status!));

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: entriesAsync.when(
          data: (entries) {
            if (entries.isEmpty) {
              final emptyText = showFavoritesOnly
                  ? l10n.noFavoritesYet
                  : l10n.noBooksInStatus(_statusLabel(status!, l10n));
              return AppEmptyState(
                icon: showFavoritesOnly ? Icons.favorite_border : Icons.menu_book_outlined,
                title: emptyText,
              );
            }
            return ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final entry = entries[index];
                final book = entry.book;
                final userBook = entry.userBook;
                return ListTile(
                  title: Text(
                    book.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamily: 'Yellowtail',
                    ),
                  ),
                  subtitle: Text(
                    '${book.author} • ${_statusLabel(userBook.status, l10n)}${userBook.progress != null ? ' • ${userBook.progress}%' : ''}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BookDetailPage(book: book),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => ListView.separated(
            itemCount: 6,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, _) => const ListTile(
              title: AppSkeletonBox(height: 18, width: double.infinity),
              subtitle: Padding(
                padding: EdgeInsets.only(top: 6),
                child: AppSkeletonBox(height: 14, width: 180),
              ),
            ),
          ),
          error: (error, stackTrace) => AsyncErrorView(
            error: error,
            onRetry: () {
              if (showFavoritesOnly) {
                ref.invalidate(favoriteEntriesProvider);
              } else {
                ref.invalidate(listEntriesByStatusProvider(status!));
              }
            },
          ),
        ),
      ),
    );
  }
}

String _statusLabel(ReadingStatus status, AppLocalizations l10n) {
  switch (status) {
    case ReadingStatus.toRead:
      return l10n.toRead;
    case ReadingStatus.reading:
      return l10n.reading;
    case ReadingStatus.completed:
      return l10n.completed;
    case ReadingStatus.dropped:
      return l10n.dropped;
    case ReadingStatus.reReading:
      return l10n.reReading;
  }
}
