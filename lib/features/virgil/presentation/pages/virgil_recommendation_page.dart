import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/layout/responsive_scaffold_body.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../semantic_discovery/presentation/pages/semantic_discovery_view.dart';

/// Route: `virgil/recommendation`
class VirgilRecommendationPage extends StatelessWidget {
  const VirgilRecommendationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.virgilRecommendationTitle),
      ),
      body: const SafeArea(
        child: ResponsiveScaffoldBody(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: SemanticDiscoveryView(),
          ),
        ),
      ),
    );
  }
}
