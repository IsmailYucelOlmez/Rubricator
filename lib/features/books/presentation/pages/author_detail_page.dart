import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/layout/responsive_scaffold_body.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/async_error_view.dart';
import '../../domain/entities/book.dart';
import '../providers/books_providers.dart';
import '../widgets/vertical_book_card.dart';

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
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
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
                  const SizedBox(height: AppSpacing.md + AppSpacing.xs),
                ],
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
      loading: () => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: BookGridLayout.delegate,
        itemCount: 4,
        itemBuilder: (_, _) => const VerticalBookCardSkeleton(),
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
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: BookGridLayout.delegate,
          itemCount: books.length,
          itemBuilder: (context, index) {
            final book = books[index];
            return VerticalBookCard(book: book);
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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      children: [
        const AppSkeletonBox(height: 18, width: 180),
        const SizedBox(height: AppSpacing.md + AppSpacing.xs),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: BookGridLayout.delegate,
          itemCount: 4,
          itemBuilder: (_, _) => const VerticalBookCardSkeleton(),
        ),
      ],
    );
  }
}
