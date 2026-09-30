import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../../core/layout/app_breakpoints.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/relative_time_utils.dart';
import '../../../../../core/ux/app_feedback.dart';
import '../../../../../core/widgets/app_loading.dart';
import '../../../../auth/presentation/sign_in_guard.dart';
import '../../../../book_notes/domain/usecases/book_notes_usecases.dart';
import '../../../../user_books/data/user_books_repository.dart';
import '../../../domain/entities/book_content_exception.dart';

/// Material's minimum touch target.
const double kMinTapTarget = 48;

TextStyle bookDetailBodyStyle(BuildContext context) =>
    Theme.of(context).textTheme.bodyMedium!;

TextStyle bookDetailInputStyle(BuildContext context) =>
    Theme.of(context).textTheme.bodyLarge!;

/// Side padding that keeps the page content within
/// [AppBreakpoints.contentMaxWidth] while slivers (and their pinned headers)
/// still span the full width.
double bookDetailGutter(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  const cap = AppBreakpoints.contentMaxWidth;
  final extra = width > cap ? (width - cap) / 2 : 0.0;
  return AppSpacing.md + extra;
}

Color starColor(BuildContext context, {required bool filled}) {
  if (filled) return AppColors.accent(context);
  return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45);
}

/// Icon for star [index] (0-4) of a rating on the stored 1-10 scale, where
/// each star is two points and an odd value ends in a half star.
IconData starIconFor(int rating, int index) {
  final value = rating - (index * 2);
  if (value >= 2) return Icons.star;
  if (value == 1) return Icons.star_half;
  return Icons.star_border;
}

/// Rating (1-10) for a tap at [dx] inside star [index] whose tap box is
/// [extent] wide: the left half picks the half star.
int ratingFromStarTap({
  required int index,
  required double dx,
  required double extent,
}) {
  return (index * 2) + (dx < extent / 2 ? 1 : 2);
}

/// Formats a 1-10 value on the 5-star scale the UI shows ("4.5").
String formatStarRating(num tenScale) => (tenScale / 2).toStringAsFixed(1);

void showBookDetailMessage(BuildContext context, String message) {
  AppFeedback.showSuccessSnackBar(context, message);
}

/// Maps known validation / auth failures to a localized message and falls
/// back to the generic error snackbar for everything else.
void showBookDetailError(BuildContext context, Object error) {
  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context)!;
  final message = switch (error) {
    BookContentException(:final error) => switch (error) {
      BookContentError.signInRequired => l10n.uxMustSignIn,
      BookContentError.reviewTooShort => l10n.uxReviewMinLength,
      BookContentError.titleRequired => l10n.uxTitleRequired,
      BookContentError.invalidUrl => l10n.invalidUrl,
      BookContentError.quoteRequired => l10n.uxQuoteRequired,
      BookContentError.ratingOutOfRange => null,
    },
    UserBooksException(signInRequired: true) => l10n.uxMustSignIn,
    BookNoteValidationException(:final message) => message,
    _ => null,
  };
  if (message != null) {
    showBookDetailMessage(context, message);
  } else {
    AppFeedback.showErrorSnackBar(context, error);
  }
}

Future<void> openExternalUrl(BuildContext context, String url) async {
  final l10n = AppLocalizations.of(context)!;
  final uri = Uri.tryParse(url);
  if (uri == null) {
    showBookDetailMessage(context, l10n.invalidUrl);
    return;
  }
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    showBookDetailMessage(context, l10n.couldNotOpenBrowser);
  }
}

Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel ?? l10n.delete),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Name shown on a review / quote: the stored author name, the signed-in
/// user's own name for their rows, or a generic fallback.
String contentAuthorName(
  String? storedName, {
  required bool own,
  required String currentUserDisplayName,
  required AppLocalizations l10n,
}) {
  final stored = storedName?.trim();
  if (stored != null && stored.isNotEmpty) return stored;
  if (own) return currentUserDisplayName;
  return l10n.anonymousReader;
}

/// Runs [action] only when signed in, reporting failures as snackbars.
Future<void> runSignedIn(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function() action,
) async {
  if (!await ensureSignedIn(context, ref)) return;
  try {
    await action();
  } catch (e) {
    if (context.mounted) showBookDetailError(context, e);
  }
}

/// Shared surface for review / quote / external review cards.
class ContentTile extends StatelessWidget {
  const ContentTile({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final content = DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
        border: Border(
          bottom: BorderSide(color: cs.outline.withValues(alpha: 0.28)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.xs,
        ),
        child: child,
      ),
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}

/// Like toggle whose state comes straight from the (optimistically updated)
/// list, so taps show up instantly without a spinner.
class LikeButton extends StatelessWidget {
  const LikeButton({
    super.key,
    required this.liked,
    required this.likes,
    required this.onPressed,
  });

  final bool liked;
  final int likes;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      toggled: liked,
      child: TextButton.icon(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: liked ? cs.primary : cs.onSurfaceVariant,
          minimumSize: const Size(kMinTapTarget, kMinTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        ),
        icon: Icon(liked ? Icons.thumb_up : Icons.thumb_up_outlined, size: 18),
        label: Text('$likes'),
      ),
    );
  }
}

/// Edit / delete buttons for the signed-in user's own content. Both are
/// disabled while either action runs; delete shows the progress.
class OwnerActions extends StatefulWidget {
  const OwnerActions({super.key, this.onEdit, required this.onDelete});

  final Future<void> Function()? onEdit;
  final Future<void> Function() onDelete;

  @override
  State<OwnerActions> createState() => _OwnerActionsState();
}

class _OwnerActionsState extends State<OwnerActions> {
  bool _busy = false;
  bool _deleting = false;

  Future<void> _run(
    Future<void> Function() action, {
    bool delete = false,
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _deleting = delete;
    });
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _deleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onEdit = widget.onEdit;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onEdit != null)
          IconButton(
            tooltip: l10n.edit,
            onPressed: _busy ? null : () => _run(onEdit),
            icon: const Icon(Icons.edit_outlined, size: 20),
          ),
        IconButton(
          tooltip: l10n.delete,
          onPressed: _busy ? null : () => _run(widget.onDelete, delete: true),
          icon: _deleting
              ? const AppLoadingIndicator(
                  size: 18,
                  strokeWidth: 2,
                  centered: false,
                )
              : const Icon(Icons.delete_outline, size: 20),
        ),
      ],
    );
  }
}

/// Like button, owner actions and relative time along a card's bottom edge.
class ContentFooter extends StatelessWidget {
  const ContentFooter({
    super.key,
    required this.createdAt,
    required this.likeButton,
    this.ownerActions,
  });

  final DateTime createdAt;
  final Widget likeButton;
  final Widget? ownerActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        likeButton,
        ?ownerActions,
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: Text(
            formatRelativeTime(createdAt, AppLocalizations.of(context)!),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class ReadOnlyStarRating extends StatelessWidget {
  const ReadOnlyStarRating({super.key, required this.rating, this.size = 18});

  /// On the stored 1-10 scale.
  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List<Widget>.generate(5, (index) {
          final icon = starIconFor(rating, index);
          return Icon(
            icon,
            color: starColor(context, filled: icon != Icons.star_border),
            size: size,
          );
        }),
      ),
    );
  }
}

/// Checkbox + label with a full-height (48dp) tap row.
class CompactCheckbox extends StatelessWidget {
  const CompactCheckbox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    return MergeSemantics(
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged(!value),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kMinTapTarget),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: value,
                onChanged: onChanged == null
                    ? null
                    : (v) => onChanged(v ?? false),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

/// Filled button that swaps its label for a spinner while [busy].
class BusyFilledButton extends StatelessWidget {
  const BusyFilledButton({
    super.key,
    required this.busy,
    required this.onPressed,
    required this.label,
  });

  final bool busy;
  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? const AppLoadingIndicator(size: 18, strokeWidth: 2, centered: false)
          : Text(label),
    );
  }
}

typedef EditedContent = ({String content, bool isSpoiler});

/// Text edit dialog for reviews and quotes. [initialIsSpoiler] shows the
/// spoiler checkbox when non-null.
Future<EditedContent?> showEditContentDialog(
  BuildContext context, {
  required String title,
  required String initialValue,
  bool? initialIsSpoiler,
}) {
  return showDialog<EditedContent>(
    context: context,
    builder: (_) => _EditContentDialog(
      title: title,
      initialValue: initialValue,
      initialIsSpoiler: initialIsSpoiler,
    ),
  );
}

class _EditContentDialog extends StatefulWidget {
  const _EditContentDialog({
    required this.title,
    required this.initialValue,
    this.initialIsSpoiler,
  });

  final String title;
  final String initialValue;
  final bool? initialIsSpoiler;

  @override
  State<_EditContentDialog> createState() => _EditContentDialogState();
}

class _EditContentDialogState extends State<_EditContentDialog> {
  late final _controller = TextEditingController(text: widget.initialValue);
  late bool _isSpoiler = widget.initialIsSpoiler ?? false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 2,
            maxLines: 6,
            style: bookDetailInputStyle(context),
          ),
          if (widget.initialIsSpoiler != null) ...[
            const SizedBox(height: AppSpacing.sm),
            CompactCheckbox(
              label: l10n.containsSpoilers,
              value: _isSpoiler,
              onChanged: (value) => setState(() => _isSpoiler = value),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(
            context,
          ).pop((content: _controller.text.trim(), isSpoiler: _isSpoiler)),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
