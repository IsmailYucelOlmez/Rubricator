import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/ux/app_feedback.dart';
import '../../domain/usecases/trbooks_submission_exceptions.dart';

/// Mirrors `showBookNoteFeedback` (book_notes feature): maps known
/// exceptions from the add-book flow to a friendly snackbar message.
void showAddTurkishBookFeedback(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context)!;
  final s = error.toString().toLowerCase();
  if (s.contains('sign in required') || s.contains('sign in to')) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.uxMustSignIn)),
    );
    return;
  }
  if (error is TrbooksValidationException) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.message)),
    );
    return;
  }
  AppFeedback.showErrorSnackBar(context, error);
}
