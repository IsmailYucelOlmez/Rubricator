import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../core/theme/app_spacing.dart';

import '../../auth/presentation/auth_provider.dart';
import '../../books/domain/entities/book.dart';
import '../../books/presentation/pages/book_detail_page.dart';
import '../../user_books/domain/entities/user_book_entity.dart';
import 'favorites_provider.dart';

class ListsPage extends ConsumerWidget {
  const ListsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final signedIn = ref.watch(authStateProvider).valueOrNull != null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: DefaultTabController(
          length: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.navLists, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: l10n.toRead),
                  Tab(text: l10n.reading),
                  Tab(text: l10n.reReading),
                  Tab(text: l10n.completed),
                  Tab(text: l10n.dropped),
                  Tab(text: l10n.favorites),
                ],
              ),
              const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
              if (!signedIn)
                Expanded(
                  child: Center(
                    child: Text(l10n.signInToSeeLists),
                  ),
                )
              else
                Expanded(
                  child: TabBarView(
                    children: [
                      _ListTabBody(status: ReadingStatus.toRead, l10n: l10n),
                      _ListTabBody(status: ReadingStatus.reading, l10n: l10n),
                      _ListTabBody(status: ReadingStatus.reReading, l10n: l10n),
                      _ListTabBody(status: ReadingStatus.completed, l10n: l10n),
                      _ListTabBody(status: ReadingStatus.dropped, l10n: l10n),
                      _FavoritesTabBody(l10n: l10n),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListTabBody extends ConsumerWidget {
  const _ListTabBody({required this.status, required this.l10n});

  final ReadingStatus status;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(listEntriesByStatusProvider(status));
    return _EntriesList(
      entriesAsync: entriesAsync,
      emptyText: l10n.noBooksInStatus(_statusLabel(status, l10n)),
    );
  }
}

class _FavoritesTabBody extends ConsumerWidget {
  const _FavoritesTabBody({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(favoriteEntriesProvider);
    return _EntriesList(
      entriesAsync: entriesAsync,
      emptyText: l10n.noFavoritesYet,
    );
  }
}

class _EntriesList extends StatelessWidget {
  const _EntriesList({required this.entriesAsync, required this.emptyText});

  final AsyncValue<List<({Book book, UserBookEntity userBook})>> entriesAsync;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return entriesAsync.when(
      data: (entries) {
        if (entries.isEmpty) return Center(child: Text(emptyText));
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
                MaterialPageRoute(
                  builder: (_) => BookDetailPage(book: book),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text(l10n.couldNotLoadList(error.toString())),
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
