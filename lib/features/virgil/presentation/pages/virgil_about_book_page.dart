import 'package:flutter/material.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/layout/responsive_scaffold_body.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../document_chat/presentation/pages/document_chat_view.dart';

/// Route: `virgil/aboutbook`
class VirgilAboutBookPage extends StatelessWidget {
  const VirgilAboutBookPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.virgilAboutBookTitle),
      ),
      body: const SafeArea(
        child: ResponsiveScaffoldBody(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: DocumentChatView(),
          ),
        ),
      ),
    );
  }
}
