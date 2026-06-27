import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/layout/responsive_scaffold_body.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/async_error_view.dart';
import '../../domain/entities/book.dart';
import '../providers/books_providers.dart';
import 'book_detail_page.dart';
import '../widgets/book_search_result_tile.dart';

class AuthorDetailPage extends ConsumerWidget {
  const AuthorDetailPage({super.key, required this.authorId});

  final String authorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncAuthor = ref.watch(authorDetailProvider(authorId));
    final asyncAuthorBooks = ref.watch(authorBooksProvider(authorId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          asyncAuthor.maybeWhen(
            data: (author) => author.name,
            orElse: () => l10n.author,
          ),
        ),
      ),
      body: ResponsiveScaffoldBody(
        child: asyncAuthor.when(
          data: (author) {
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
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
                _AuthorBooksSection(authorId: authorId, booksState: asyncAuthorBooks),
              ],
            );
          },
          loading: () => const _AuthorDetailSkeleton(),
          error: (e, _) => AsyncErrorView(
            error: e,
            onRetry: () => ref.invalidate(authorDetailProvider(authorId)),
          ),
        ),
      ),
    );
  }
}

class _AuthorBooksSection extends ConsumerWidget {
  const _AuthorBooksSection({required this.authorId, required this.booksState});

  final String authorId;
  final AsyncValue<List<Book>> booksState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return booksState.when(
      loading: () => ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, _) => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: AppListTileSkeleton(),
        ),
      ),
      error: (error, stackTrace) => AsyncErrorView(
        error: error,
        compact: true,
        onRetry: () => ref.invalidate(authorBooksProvider(authorId)),
      ),
      data: (books) {
        if (books.isEmpty) {
          return Text(l10n.noBooksFound);
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: books.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final book = books[index];
            return BookSearchResultTile(
              book: book,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => BookDetailPage(book: book),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AuthorDetailSkeleton extends StatelessWidget {
  const _AuthorDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: const [
        AppSkeletonBox(height: 18, width: 180),
        SizedBox(height: AppSpacing.md + AppSpacing.xs),
        AppListTileSkeleton(),
        SizedBox(height: AppSpacing.sm),
        AppListTileSkeleton(),
        SizedBox(height: AppSpacing.sm),
        AppListTileSkeleton(),
      ],
    );
  }
}
