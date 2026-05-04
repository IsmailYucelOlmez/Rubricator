import 'package:flutter/material.dart';

import '../i18n/l10n/app_localizations.dart';
import '../theme/app_spacing.dart';
import '../ux/l10n_app_error.dart';

/// Full-region friendly error + retry (no raw exception text).
class AsyncErrorView extends StatelessWidget {
  const AsyncErrorView({
    super.key,
    required this.error,
    required this.onRetry,
    this.compact = false,
  });

  final Object error;
  final VoidCallback onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final msg = l10n.userFacingMessage(error);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.wifi_find_outlined,
          size: compact ? 32 : 44,
          color: Theme.of(context).colorScheme.error,
        ),
        SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
        Text(msg, textAlign: TextAlign.center),
        SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
        FilledButton(onPressed: onRetry, child: Text(l10n.uxRetry)),
      ],
    );
    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: content,
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: content,
      ),
    );
  }
}
