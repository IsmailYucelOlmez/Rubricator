import 'package:flutter/material.dart' hide NotificationMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/notification/notification_provider.dart';
import 'profile_toggle_row.dart';

class NotificationSelector extends ConsumerWidget {
  const NotificationSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notificationMode = ref.watch(notificationModeProvider);
    final isEnabled = notificationMode == NotificationMode.enabled;

    return ProfileToggleRow(
      label: l10n.notifications,
      trailing: Icon(
        isEnabled ? Icons.notifications_outlined : Icons.notifications_off_outlined,
        size: 26,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      onTap: () {
        ref.read(notificationModeProvider.notifier).setNotificationMode(
              isEnabled ? NotificationMode.disabled : NotificationMode.enabled,
            );
      },
    );
  }
}