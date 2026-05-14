import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/layout/app_breakpoints.dart';
import '../../../../core/layout/responsive_scaffold_body.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/async_error_view.dart';
import '../../domain/entities/book.dart';
import '../providers/books_providers.dart';
import 'book_detail_page.dart';
import '../widgets/book_cover_leading.dart';
import '../widgets/book_cover_with_favorite_button.dart';

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
      loading: () => LayoutBuilder(
        builder: (context, constraints) {
          final twoCol = constraints.maxWidth >= AppBreakpoints.listsTwoColumnMinWidth;
          if (!twoCol) {
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, _) => const AppListTileSkeleton(),
            );
          }
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 3.2,
            ),
            itemCount: 6,
            itemBuilder: (_, _) => const AppListTileSkeleton(),
          );
        },
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
        return LayoutBuilder(
          builder: (context, constraints) {
            final twoCol = constraints.maxWidth >= AppBreakpoints.listsTwoColumnMinWidth;
            if (!twoCol) {
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: books.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) => _AuthorBookTile(book: books[index]),
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 3.2,
              ),
              itemCount: books.length,
              itemBuilder: (_, i) => _AuthorBookTile(book: books[i]),
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

class _AuthorBookTile extends StatelessWidget {
  const _AuthorBookTile({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontFamily: 'LTSoul',
          fontSize: 18 * 0.8,
        );
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => BookDetailPage(book: book)),
      ),
      child: Ink(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              height: 84,
              child: BookCoverWithFavoriteButton(
                bookId: book.id,
                compact: true,
                child: BookCoverLeading(
                  coverImageUrl: book.coverImageUrl,
                  size: 56,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
