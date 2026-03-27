import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/book.dart';
import 'book_detail_page.dart';
import 'books_controller.dart';

class BookDiscoveryPage extends ConsumerWidget {
  const BookDiscoveryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trending = ref.watch(trendingBooksProvider);
    final query = ref.watch(searchQueryProvider);
    final search = ref.watch(searchedBooksProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Discover Books', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search by title or author',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) =>
                  ref.read(searchQueryProvider.notifier).state = value,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: query.trim().isEmpty
                  ? trending.when(
                      data: (books) => _BookList(books: books),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stackTrace) =>
                          const Center(child: Text('Failed to load books')),
                    )
                  : search.when(
                      data: (books) {
                        if (books.isEmpty) {
                          return const Center(child: Text('No books found'));
                        }
                        return _BookList(books: books);
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stackTrace) =>
                          const Center(child: Text('Search failed')),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookList extends StatelessWidget {
  const _BookList({required this.books});

  final List<Book> books;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: books.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (_, index) {
        final book = books[index];
        final cover = book.coverId == null
            ? null
            : '${AppConstants.openLibraryCoverBaseUrl}/b/id/${book.coverId}-M.jpg';
        return ListTile(
          leading: cover == null
              ? const Icon(Icons.menu_book_outlined)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(cover, width: 44, fit: BoxFit.cover),
                ),
          title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => BookDetailPage(book: book)),
          ),
        );
      },
    );
  }
}
