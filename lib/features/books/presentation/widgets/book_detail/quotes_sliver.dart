import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../auth/presentation/auth_provider.dart';
import '../../../domain/entities/book_detail_entities.dart';
import '../../providers/books_providers.dart';
import 'book_detail_common.dart';
import 'content_list_sliver.dart';

class QuotesSliver extends ConsumerWidget {
  const QuotesSliver({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = ref.watch(currentUserIdProvider);
    final currentUserName = ref.watch(currentUserDisplayNameProvider);
    final notifier = ref.read(quoteProvider(bookId).notifier);

    return SliverPadding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      sliver: ContentListSliver<QuoteEntity>(
        value: ref.watch(quoteProvider(bookId)),
        emptyText: l10n.noQuotesYet,
        onRetry: () => ref.invalidate(quoteProvider(bookId)),
        itemBuilder: (context, quote) {
          final own = quote.userId == currentUserId;
          return _QuoteCard(
            key: ValueKey(quote.id),
            quote: quote,
            userName: contentAuthorName(
              quote.userName,
              own: own,
              currentUserDisplayName: currentUserName,
              l10n: l10n,
            ),
            onLike: () =>
                runSignedIn(context, ref, () => notifier.toggleLike(quote.id)),
            ownerActions: own
                ? OwnerActions(
                    onEdit: () async {
                      final edited = await showEditContentDialog(
                        context,
                        title: l10n.editQuote,
                        initialValue: quote.content,
                      );
                      if (edited == null || !context.mounted) return;
                      try {
                        await notifier.edit(quote, edited.content);
                        if (context.mounted) {
                          showBookDetailMessage(context, l10n.quoteUpdated);
                        }
                      } catch (e) {
                        if (context.mounted) showBookDetailError(context, e);
                      }
                    },
                    onDelete: () async {
                      final confirmed = await confirmDelete(
                        context,
                        title: l10n.uxDeleteQuoteTitle,
                        message: l10n.uxDeleteQuoteMessage,
                      );
                      if (!confirmed || !context.mounted) return;
                      try {
                        await notifier.remove(quote);
                        if (context.mounted) {
                          showBookDetailMessage(context, l10n.quoteDeleted);
                        }
                      } catch (e) {
                        if (context.mounted) showBookDetailError(context, e);
                      }
                    },
                  )
                : null,
          );
        },
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({
    super.key,
    required this.quote,
    required this.userName,
    required this.onLike,
    this.ownerActions,
  });

  final QuoteEntity quote;
  final String userName;
  final VoidCallback onLike;
  final Widget? ownerActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ContentTile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            userName,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Text(
              quote.content,
              style: bookDetailBodyStyle(
                context,
              ).copyWith(height: 1.42, fontStyle: FontStyle.italic),
            ),
          ),
          ContentFooter(
            createdAt: quote.createdAt,
            likeButton: LikeButton(
              liked: quote.likedByCurrentUser,
              likes: quote.likes,
              onPressed: onLike,
            ),
            ownerActions: ownerActions,
          ),
        ],
      ),
    );
  }
}
