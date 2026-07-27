import 'package:flutter/material.dart';

import '../i18n/l10n/app_localizations.dart';
import '../theme/app_spacing.dart';

/// Shown only when the failure is a connectivity / offline problem.
class AppNoInternetView extends StatelessWidget {
  const AppNoInternetView({
    super.key,
    required this.onRetry,
    this.compact = false,
  });

  final VoidCallback onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.wifi_off_outlined,
          size: compact ? 32 : 44,
          color: scheme.error,
        ),
        SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
        Text(
          l10n.uxOfflineBanner,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
        Text(
          l10n.uxErrorNetwork,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
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
