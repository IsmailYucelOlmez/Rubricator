import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_input.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../data/support_contact_service.dart';

final supportContactServiceProvider = Provider<SupportContactService>(
  (ref) => SupportContactService(),
);

/// Profile page "Contact us" form: a message to support, answered by email at
/// the signed-in account's address.
class SupportContactCard extends ConsumerStatefulWidget {
  const SupportContactCard({super.key});

  @override
  ConsumerState<SupportContactCard> createState() => _SupportContactCardState();
}

class _SupportContactCardState extends ConsumerState<SupportContactCard> {
  final _message = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  String? _validate(AppLocalizations l10n) {
    final length = _message.text.trim().length;
    if (length < SupportContactService.messageMinLength) {
      return l10n.contactMessageTooShort;
    }
    if (length > SupportContactService.messageMaxLength) {
      return l10n.contactMessageTooLong;
    }
    return null;
  }

  Future<void> _send(AppLocalizations l10n) async {
    final error = _validate(l10n);
    setState(() => _error = error);
    if (error != null) return;

    final user = ref.read(authStateProvider).valueOrNull;
    final messenger = ScaffoldMessenger.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    setState(() => _sending = true);
    try {
      await ref
          .read(supportContactServiceProvider)
          .send(message: _message.text, name: userDisplayName(user), lang: lang);
      if (!mounted) return;
      _message.clear();
      FocusScope.of(context).unfocus();
      messenger.showSnackBar(SnackBar(content: Text(l10n.contactSent)));
    } on SupportContactException catch (e) {
      if (!mounted) return;
      switch (e.code) {
        case 'too_short':
          setState(() => _error = l10n.contactMessageTooShort);
        case 'too_long':
          setState(() => _error = l10n.contactMessageTooLong);
        case 'rate_limited':
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.contactRateLimited)),
          );
        default:
          messenger.showSnackBar(SnackBar(content: Text(l10n.contactFailed)));
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.contactFailed)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final email = ref.watch(authStateProvider).valueOrNull?.email ?? '';

    return Card(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.contactTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.contactSubtitle(email),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            AppInput(
              controller: _message,
              labelText: l10n.contactMessageLabel,
              keyboardType: TextInputType.multiline,
              minLines: 4,
              maxLines: 8,
              errorText: _error,
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton.icon(
                onPressed: _sending ? null : () => _send(l10n),
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: AppLoadingIndicator(
                          size: 18,
                          strokeWidth: 2,
                          centered: false,
                        ),
                      )
                    : const Icon(Icons.send_outlined),
                label: Text(l10n.contactSend),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
