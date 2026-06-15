import 'package:flutter/material.dart' hide NotificationMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/locale_provider.dart';
import 'notification_provider.dart';
import 'reading_reminder_scheduler.dart';

/// Keeps the daily reading reminder aligned with prefs and app lifecycle.
class ReadingReminderBootstrap extends ConsumerStatefulWidget {
  const ReadingReminderBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ReadingReminderBootstrap> createState() =>
      _ReadingReminderBootstrapState();
}

class _ReadingReminderBootstrapState extends ConsumerState<ReadingReminderBootstrap>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final enabled = ref.read(notificationModeProvider) == NotificationMode.enabled;
    await ReadingReminderScheduler.ensureScheduled(enabled);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<NotificationMode>(notificationModeProvider, (previous, next) {
      ReadingReminderScheduler.ensureScheduled(next == NotificationMode.enabled);
    });
    ref.listen<Locale>(localeProvider, (previous, next) {
      if (previous?.languageCode != next.languageCode) {
        _refresh();
      }
    });
    return widget.child;
  }
}
