import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_loading.dart';
import '../../../../../core/widgets/async_error_view.dart';
import '../../providers/books_providers.dart';
import 'book_detail_common.dart';

/// The signed-in user's own rating: pick stars and submit, or edit an
/// existing rating. The community average lives in the header.
class UserRatingCard extends ConsumerStatefulWidget {
  const UserRatingCard({super.key, required this.bookId});

  final String bookId;

  @override
  ConsumerState<UserRatingCard> createState() => _UserRatingCardState();
}

class _UserRatingCardState extends ConsumerState<UserRatingCard> {
  /// Pending selection on the 1-10 scale; 0 means none.
  int _selected = 0;
  bool _editing = false;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(ratingProvider(widget.bookId).notifier).submit(_selected);
      if (!mounted) return;
      setState(() {
        _selected = 0;
        _editing = false;
      });
      showBookDetailMessage(context, l10n.ratingSubmitted);
    } catch (e) {
      if (mounted) showBookDetailError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final async = ref.watch(ratingProvider(widget.bookId));
    final state = async.valueOrNull;
    final userRating = state?.userRating;
    final hasRated = userRating != null;
    final submitting = state?.submitting ?? false;
    final canChange = (!hasRated || _editing) && !submitting && state != null;
    final shown = _selected > 0 ? _selected : (userRating ?? 0);

    Widget trailing;
    if (!hasRated) {
      trailing = BusyFilledButton(
        busy: submitting,
        onPressed: _selected == 0 ? null : _submit,
        label: l10n.submitRating,
      );
    } else if (_editing) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l10n.submitRating,
            onPressed: _selected == 0 || submitting ? null : _submit,
            icon: submitting
                ? const AppLoadingIndicator(
                    size: 18,
                    strokeWidth: 2,
                    centered: false,
                  )
                : const Icon(Icons.check),
          ),
          IconButton(
            tooltip: l10n.cancel,
            onPressed: submitting
                ? null
                : () => setState(() {
                    _editing = false;
                    _selected = 0;
                  }),
            icon: const Icon(Icons.close),
          ),
        ],
      );
    } else {
      trailing = IconButton(
        tooltip: l10n.edit,
        onPressed: () => setState(() {
          _editing = true;
          _selected = userRating;
        }),
        icon: const Icon(Icons.edit_outlined),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm + AppSpacing.xs,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(l10n.yourRating, style: theme.textTheme.titleMedium),
                if (shown > 0) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '${formatStarRating(shown)} / 5',
                    style: bookDetailBodyStyle(context),
                  ),
                ],
              ],
            ),
            if (async.hasError && state == null)
              AsyncErrorView(
                error: async.error!,
                compact: true,
                onRetry: () => ref.invalidate(ratingProvider(widget.bookId)),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: _StarPicker(
                          value: shown,
                          onChanged: canChange
                              ? (value) => setState(() => _selected = value)
                              : null,
                        ),
                      ),
                    ),
                  ),
                  trailing,
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Five tappable stars with half-star precision. Each star has a 48dp tap
/// box; tapping its left half picks the half star. Exposed to assistive
/// tech as an adjustable value.
class _StarPicker extends StatelessWidget {
  const _StarPicker({required this.value, required this.onChanged});

  static const _extent = kMinTapTarget;

  /// 0-10.
  final int value;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onChanged = this.onChanged;
    return Semantics(
      label: l10n.yourRating,
      value: '${formatStarRating(value)} / 5',
      increasedValue: '${formatStarRating((value + 1).clamp(1, 10))} / 5',
      decreasedValue: '${formatStarRating((value - 1).clamp(1, 10))} / 5',
      onIncrease: onChanged == null || value >= 10
          ? null
          : () => onChanged(value + 1),
      onDecrease: onChanged == null || value <= 1
          ? null
          : () => onChanged(value - 1),
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(5, (index) {
            final icon = starIconFor(value, index);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: onChanged == null
                  ? null
                  : (details) => onChanged(
                      ratingFromStarTap(
                        index: index,
                        dx: details.localPosition.dx,
                        extent: _extent,
                      ),
                    ),
              child: SizedBox.square(
                dimension: _extent,
                child: Icon(
                  icon,
                  size: 32,
                  color: starColor(context, filled: icon != Icons.star_border),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
