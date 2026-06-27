import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/ux/app_feedback.dart';
import '../../domain/usecases/book_notes_usecases.dart';

void showBookNoteFeedback(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context)!;
  final s = error.toString().toLowerCase();
  if (s.contains('sign in required') || s.contains('sign in to')) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.uxMustSignIn)),
    );
    return;
  }
  if (error is BookNoteValidationException) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.message)),
    );
    return;
  }
  AppFeedback.showErrorSnackBar(context, error);
}

Future<bool?> confirmDeleteBookNote(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.deleteNoteTitle),
      content: Text(l10n.deleteNoteMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.delete),
        ),
      ],
    ),
  );
}
