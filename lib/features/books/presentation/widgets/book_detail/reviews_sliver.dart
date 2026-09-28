import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_toggle_switch.dart';
import '../../../../auth/presentation/auth_provider.dart';
import '../../../domain/entities/book_detail_entities.dart';
import '../../providers/books_providers.dart';
import 'book_detail_common.dart';
import 'content_list_sliver.dart';

/// Whether the reviews tab shows links to external reviews instead of app
/// reviews. Lives outside the widget so adding an external review from the
/// sheet can switch the tab over.
final reviewsShowExternalProvider = StateProvider.autoDispose
    .family<bool, String>((ref, bookId) => false);

class ReviewsSliver extends ConsumerWidget {
  const ReviewsSliver({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showExternal = ref.watch(reviewsShowExternalProvider(bookId));
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: ReviewSourceToggle(
            showExternal: showExternal,
            onChanged: (value) =>
                ref.read(reviewsShowExternalProvider(bookId).notifier).state =
                    value,
          ),
        ),
        if (showExternal)
          _ExternalReviewList(bookId: bookId)
        else
          _ReviewList(bookId: bookId),
      ],
    );
  }
}

/// "App reviews ◯ External reviews" switch with tappable labels.
class ReviewSourceToggle extends StatelessWidget {
  const ReviewSourceToggle({
    super.key,
    required this.showExternal,
    required this.onChanged,
  });

  final bool showExternal;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final onChanged = this.onChanged;

    Widget label(String text, {required bool external}) {
      final active = showExternal == external;
      return Expanded(
        child: InkWell(
          onTap: onChanged == null ? null : () => onChanged(external),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: kMinTapTarget),
            child: Align(
              alignment: external
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Text(
                text,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: active ? cs.primary : cs.onSurfaceVariant,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          label(l10n.userReviews, external: false),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: AppToggleSwitch(value: showExternal, onChanged: onChanged),
          ),
          label(l10n.externalReviews, external: true),
        ],
      ),
    );
  }
}

class _ReviewList extends ConsumerWidget {
  const _ReviewList({required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = ref.watch(currentUserIdProvider);
    final currentUserName = ref.watch(currentUserDisplayNameProvider);
    final notifier = ref.read(reviewListProvider(bookId).notifier);

    return ContentListSliver<ReviewEntity>(
      value: ref.watch(reviewListProvider(bookId)),
      emptyText: l10n.noUserReviewsYet,
      onRetry: () => ref.invalidate(reviewListProvider(bookId)),
      itemBuilder: (context, review) {
        final own = review.userId == currentUserId;
        return _ReviewCard(
          key: ValueKey(review.id),
          review: review,
          own: own,
          userName: contentAuthorName(
            review.userName,
            own: own,
            currentUserDisplayName: currentUserName,
            l10n: l10n,
          ),
          onLike: () =>
              runSignedIn(context, ref, () => notifier.toggleLike(review.id)),
          onEdit: () async {
            final edited = await showEditContentDialog(
              context,
              title: l10n.editReview,
              initialValue: review.content,
              initialIsSpoiler: review.isSpoiler,
            );
            if (edited == null || !context.mounted) return;
            try {
              await notifier.editReview(
                review,
                edited.content,
                isSpoiler: edited.isSpoiler,
              );
              if (context.mounted) {
                showBookDetailMessage(context, l10n.reviewUpdated);
              }
            } catch (e) {
              if (context.mounted) showBookDetailError(context, e);
            }
          },
          onDelete: () async {
            final confirmed = await confirmDelete(
              context,
              title: l10n.uxDeleteReviewTitle,
              message: l10n.uxDeleteReviewMessage,
            );
            if (!confirmed || !context.mounted) return;
            try {
              await notifier.remove(review);
              if (context.mounted) {
                showBookDetailMessage(context, l10n.reviewDeleted);
              }
            } catch (e) {
              if (context.mounted) showBookDetailError(context, e);
            }
          },
        );
      },
    );
  }
}

class _ReviewCard extends StatefulWidget {
  const _ReviewCard({
    super.key,
    required this.review,
    required this.userName,
    required this.own,
    required this.onLike,
    required this.onEdit,
    required this.onDelete,
  });

  final ReviewEntity review;
  final String userName;
  final bool own;
  final VoidCallback onLike;
  final Future<void> Function() onEdit;
  final Future<void> Function() onDelete;

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _spoilerRevealed = false;

  @override
  void didUpdateWidget(covariant _ReviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.review.isSpoiler != widget.review.isSpoiler) {
      _spoilerRevealed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final review = widget.review;
    final hideContent = review.isSpoiler && !widget.own && !_spoilerRevealed;

    return ContentTile(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.userName,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (review.isSpoiler) ...[
                  _SpoilerBadge(label: l10n.spoilerBadge),
                  const SizedBox(width: AppSpacing.xs),
                ],
                if (review.userRating != null)
                  ReadOnlyStarRating(rating: review.userRating!),
                if (review.isFavorite) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(Icons.favorite, color: cs.primary, size: 16),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: hideContent
                ? InkWell(
                    onTap: () => setState(() => _spoilerRevealed = true),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                        horizontal: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        l10n.showSpoiler,
                        textAlign: TextAlign.center,
                        style: bookDetailBodyStyle(context).copyWith(
                          color: cs.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  )
                : Text(
                    review.content,
                    style: bookDetailBodyStyle(context).copyWith(height: 1.42),
                  ),
          ),
          ContentFooter(
            createdAt: review.createdAt,
            likeButton: LikeButton(
              liked: review.likedByCurrentUser,
              likes: review.likes,
              onPressed: widget.onLike,
            ),
            ownerActions: widget.own
                ? OwnerActions(onEdit: widget.onEdit, onDelete: widget.onDelete)
                : null,
          ),
        ],
      ),
    );
  }
}

class _SpoilerBadge extends StatelessWidget {
  const _SpoilerBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: cs.onErrorContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ExternalReviewList extends ConsumerWidget {
  const _ExternalReviewList({required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = ref.watch(currentUserIdProvider);
    final currentUserName = ref.watch(currentUserDisplayNameProvider);

    return ContentListSliver<ExternalReviewEntity>(
      value: ref.watch(externalReviewProvider(bookId)),
      emptyText: l10n.noExternalReviewsYet,
      onRetry: () => ref.invalidate(externalReviewProvider(bookId)),
      itemBuilder: (context, review) {
        final own = review.userId == currentUserId;
        return _ExternalReviewCard(
          key: ValueKey(review.id),
          review: review,
          own: own,
          userName: contentAuthorName(
            review.userName,
            own: own,
            currentUserDisplayName: currentUserName,
            l10n: l10n,
          ),
          onDelete: () async {
            final confirmed = await confirmDelete(
              context,
              title: l10n.uxDeleteExternalReviewTitle,
              message: l10n.uxDeleteExternalReviewMessage,
            );
            if (!confirmed || !context.mounted) return;
            try {
              await ref
                  .read(externalReviewProvider(bookId).notifier)
                  .remove(review);
              if (context.mounted) {
                showBookDetailMessage(context, l10n.externalReviewDeleted);
              }
            } catch (e) {
              if (context.mounted) showBookDetailError(context, e);
            }
          },
        );
      },
    );
  }
}

class _ExternalReviewCard extends StatelessWidget {
  const _ExternalReviewCard({
    super.key,
    required this.review,
    required this.userName,
    required this.own,
    required this.onDelete,
  });

  final ExternalReviewEntity review;
  final String userName;
  final bool own;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final description = review.description.trim();

    return ContentTile(
      onTap: () => openExternalUrl(context, review.url),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        review.title,
                        style: bookDetailBodyStyle(
                          context,
                        ).copyWith(height: 1.25, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              if (own) OwnerActions(onDelete: onDelete),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Text(
                description,
                style: bookDetailBodyStyle(context).copyWith(height: 1.42),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    _hostOf(review.url),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.open_in_new, size: 14, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _hostOf(String url) {
  final host = Uri.tryParse(url)?.host.trim();
  if (host == null || host.isEmpty) return url;
  return host.startsWith('www.') ? host.substring(4) : host;
}
