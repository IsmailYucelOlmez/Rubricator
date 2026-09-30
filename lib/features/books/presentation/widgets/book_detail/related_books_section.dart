import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/async_error_view.dart';
import '../../../domain/entities/book_detail_entities.dart';
import '../../providers/books_providers.dart';
import '../vertical_book_card.dart';
import 'book_detail_common.dart';

class RelatedBooksSection extends ConsumerWidget {
  const RelatedBooksSection({
    super.key,
    required this.book,
    required this.isPending,
  });

  static const _cardWidth = 110.0;
  static const _rowHeight = 220.0;
  static const _gap = AppSpacing.sm + AppSpacing.xs;

  final BookEntity book;
  final bool isPending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final key = relatedBooksKeyFor(book);
    final related = isPending ? null : ref.watch(relatedBooksProvider(key));
    // The theme's surface container matches the dark background, so covers
    // without an image would vanish there.
    final placeholder = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade800
        : Colors.white;

    Widget skeleton() => SizedBox(
      height: _rowHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(width: _gap),
        itemBuilder: (_, _) => const SizedBox(
          width: _cardWidth,
          child: VerticalBookCardSkeleton(),
        ),
      ),
    );

    final Widget body = switch (related) {
      null => skeleton(),
      AsyncData(:final value) when value.isEmpty => Text(
        l10n.noRelatedTitlesFound,
        style: bookDetailBodyStyle(context),
      ),
      AsyncData(:final value) => SizedBox(
        height: _rowHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: value.length,
          separatorBuilder: (_, _) => const SizedBox(width: _gap),
          itemBuilder: (context, i) {
            for (var ahead = 1; ahead <= kBookCoverPrefetchAhead; ahead++) {
              if (i + ahead < value.length) {
                precacheBookCover(context, value[i + ahead].coverImageUrl);
              }
            }
            return VerticalBookCard(
              book: value[i],
              width: _cardWidth,
              placeholderColor: placeholder,
            );
          },
        ),
      ),
      AsyncError(:final error) => AsyncErrorView(
        error: error,
        compact: true,
        onRetry: () => ref.invalidate(relatedBooksProvider(key)),
      ),
      _ => skeleton(),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.relatedBooks, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        body,
      ],
    );
  }
}
