import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/layout/responsive_scaffold_body.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/async_error_view.dart';
import '../../../books/presentation/pages/book_detail_page.dart';
import '../../../books/presentation/widgets/vertical_book_card.dart';
import '../providers/home_providers.dart';

class GenreBooksPage extends ConsumerWidget {
  const GenreBooksPage({
    required this.genreKey,
    required this.genreLabel,
    super.key,
  });

  final String genreKey;
  final String genreLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksState = ref.watch(genreBooksProvider(genreKey));
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(genreLabel)),
      body: ResponsiveScaffoldBody(
        child: booksState.when(
          data: (books) {
            if (books.isEmpty) {
              return AppEmptyState(icon: Icons.auto_stories_outlined, title: l10n.noBooksFound);
            }
            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              gridDelegate: BookGridLayout.delegate,
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                final entity = book.toBook();
                return VerticalBookCard(
                  book: entity,
                  author: book.authorNames,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BookDetailPage(book: entity),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => GridView.builder(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            gridDelegate: BookGridLayout.delegate,
            itemCount: 6,
            itemBuilder: (_, _) => const VerticalBookCardSkeleton(),
          ),
          error: (error, stackTrace) => AsyncErrorView(
            error: error,
            onRetry: () => ref.invalidate(genreBooksProvider(genreKey)),
          ),
        ),
      ),
    );
  }
}
