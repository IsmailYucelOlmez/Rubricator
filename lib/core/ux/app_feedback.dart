import 'package:flutter/material.dart';

import '../i18n/l10n/app_localizations.dart';
import 'l10n_app_error.dart';

class AppFeedback {
  const AppFeedback._();

  static void showErrorSnackBar(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context)!;
    final detail = _postgrestDetail(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          detail == null || detail.isEmpty
              ? l10n.userFacingMessage(error)
              : detail,
        ),
      ),
    );
  }

  static String? _postgrestDetail(Object error) {
    try {
      // supabase_flutter PostgrestException exposes `message`.
      final dynamic dyn = error;
      final message = dyn.message;
      if (message is String && message.trim().isNotEmpty) {
        final detail = message.trim();
        if (detail.length > 180) return '${detail.substring(0, 177)}...';
        return detail;
      }
    } catch (_) {
      // Not a PostgrestException-like object.
    }
    final text = error.toString().trim();
    if (text.isEmpty || text == 'Exception') return null;
    if (text.length > 180) return '${text.substring(0, 177)}...';
    return text;
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
