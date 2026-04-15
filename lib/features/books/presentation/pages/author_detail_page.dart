import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/book.dart';
import 'book_detail_page.dart';
import '../providers/books_providers.dart';

class AuthorDetailPage extends ConsumerWidget {
  const AuthorDetailPage({super.key, required this.authorId});

  final String authorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncAuthor = ref.watch(authorDetailProvider(authorId));
    final asyncAuthorBooks = ref.watch(authorBooksProvider(authorId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.author)),
      body: asyncAuthor.when(
        data: (author) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const Center(child: Icon(Icons.person, size: 96)),
              const SizedBox(height: AppSpacing.md),
              Text(
                author.name,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              if (author.birthDate != null || author.deathDate != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  [
                    if (author.birthDate != null) author.birthDate,
                    if (author.deathDate != null) '– ${author.deathDate}',
                  ].join(' '),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: AppSpacing.md + AppSpacing.xs),
              if (author.bio.isNotEmpty)
                Text(author.bio, style: Theme.of(context).textTheme.bodyLarge)
              else
                _AuthorBooksFallback(
                  booksState: asyncAuthorBooks,
                  authorName: author.name,
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.couldNotLoadAuthor(
                e.toString().replaceFirst('Exception: ', ''),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthorBooksFallback extends StatelessWidget {
  const _AuthorBooksFallback({required this.booksState, required this.authorName});

  final AsyncValue<List<Book>> booksState;
  final String authorName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return booksState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Text(l10n.noBiographyAvailable),
      data: (books) {
        if (books.isEmpty) return Text(l10n.noBiographyAvailable);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.noBiographyAvailable,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.relatedBooks,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            ...books.map(
              (book) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(book.title),
                subtitle: Text(authorName),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BookDetailPage(book: book),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
