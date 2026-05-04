import 'package:flutter/material.dart';

import '../i18n/l10n/app_localizations.dart';
import 'l10n_app_error.dart';

class AppFeedback {
  const AppFeedback._();

  static void showErrorSnackBar(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.userFacingMessage(error))),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  static Future<bool?> showRetryDialog(BuildContext context, Object error) async {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l10n.userFacingMessage(error)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.uxRetry)),
        ],
      ),
    );
  }
}
