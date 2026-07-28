import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../auth/presentation/login_page.dart';
import '../data/datasources/virgil_usage_remote_datasource.dart';

/// Ensures the user is signed in before a Virgil action.
///
/// Returns `true` when authenticated. Otherwise opens [LoginPage] and returns
/// `false`.
Future<bool> ensureVirgilSignedIn(BuildContext context, WidgetRef ref) async {
  final user = ref.read(authStateProvider).valueOrNull;
  if (user != null) return true;
  if (!context.mounted) return false;
  await Navigator.of(context).push(
    MaterialPageRoute<bool>(
      builder: (_) => const LoginPage(),
    ),
  );
  return ref.read(authStateProvider).valueOrNull != null;
}

void showVirgilSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

String virgilUsageLimitMessage(AppLocalizations l10n, Object error) {
  if (error is VirgilUsageLimitException) {
    return switch (error.action) {
      VirgilUsageAction.upload => l10n.virgilDailyUploadLimit,
      VirgilUsageAction.recommendation => l10n.virgilDailyRecommendationLimit,
    };
  }
  return l10n.virgilDailyRecommendationLimit;
}
