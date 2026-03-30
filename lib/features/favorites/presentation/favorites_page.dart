import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_provider.dart';
import '../../books/domain/entities/book.dart';
import '../../books/presentation/pages/book_detail_page.dart';
import '../../user_books/domain/entities/user_book_entity.dart';
import 'favorites_provider.dart';

class ListsPage extends ConsumerWidget {
  const ListsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(authStateProvider).valueOrNull != null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DefaultTabController(
          length: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Lists', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              const TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'To Read'),
                  Tab(text: 'Reading'),
                  Tab(text: 'Re-reading'),
                  Tab(text: 'Completed'),
                  Tab(text: 'Dropped'),
                  Tab(text: 'Favorites'),
                ],
              ),
              const SizedBox(height: 12),
              if (!signedIn)
                const Expanded(
                  child: Center(
                    child: Text('Sign in from Profile to see your lists.'),
                  ),
                )
              else
                Expanded(
                  child: TabBarView(
                    children: [
                      _ListTabBody(status: ReadingStatus.toRead),
                      _ListTabBody(status: ReadingStatus.reading),
                      _ListTabBody(status: ReadingStatus.reReading),
                      _ListTabBody(status: ReadingStatus.completed),
                      _ListTabBody(status: ReadingStatus.dropped),
                      const _FavoritesTabBody(),
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
  const _ListTabBody({required this.status});

  final ReadingStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(listEntriesByStatusProvider(status));
    return _EntriesList(
      entriesAsync: entriesAsync,
      emptyText: 'No books in ${_statusLabel(status)}.',
    );
  }
}

class _FavoritesTabBody extends ConsumerWidget {
  const _FavoritesTabBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(favoriteEntriesProvider);
    return _EntriesList(
      entriesAsync: entriesAsync,
      emptyText: 'No favorites yet.',
    );
  }
}

class _EntriesList extends StatelessWidget {
  const _EntriesList({required this.entriesAsync, required this.emptyText});

  final AsyncValue<List<({Book book, UserBookEntity userBook})>> entriesAsync;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
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
              title: Text(book.title),
              subtitle: Text(
                '${book.author} • ${_statusLabel(userBook.status)}${userBook.progress != null ? ' • ${userBook.progress}%' : ''}',
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
        child: Text('Could not load list: $error'),
      ),
    );
  }
}

String _statusLabel(ReadingStatus status) {
  switch (status) {
    case ReadingStatus.toRead:
      return 'To Read';
    case ReadingStatus.reading:
      return 'Reading';
    case ReadingStatus.completed:
      return 'Completed';
    case ReadingStatus.dropped:
      return 'Dropped';
    case ReadingStatus.reReading:
      return 'Re-reading';
  }
}
