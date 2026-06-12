import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/l10n/app_localizations.dart';
import '../../../core/network/connectivity_provider.dart';
import '../../../core/network/network_errors.dart';
import 'habit_providers.dart';

/// Watches connectivity and syncs queued quick logs when the device goes online.
class HabitOfflineSyncListener extends ConsumerStatefulWidget {
  const HabitOfflineSyncListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<HabitOfflineSyncListener> createState() =>
      _HabitOfflineSyncListenerState();
}

class _HabitOfflineSyncListenerState
    extends ConsumerState<HabitOfflineSyncListener> {
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncIfOnline());
  }

  Future<void> _syncIfOnline() async {
    final offline = ref.read(isOfflineProvider);
    if (offline) {
      _wasOffline = true;
      return;
    }
    await _runSync(showSnackBar: false);
  }

  Future<void> _runSync({required bool showSnackBar}) async {
    final synced = await ref.read(habitLogControllerProvider).syncPendingLogs();
    if (!mounted || synced <= 0) return;
    ref.invalidate(readingStatsProvider);
    ref.invalidate(readingLogsProvider);
    ref.invalidate(todayReadingProvider);
    if (showSnackBar) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.readingLogsSynced)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<ConnectivityResult>>>(
      connectivityStreamProvider,
      (previous, next) {
        final prevOffline = previous?.when(
              data: isConnectivityOffline,
              loading: () => _wasOffline,
              error: (_, _) => _wasOffline,
            ) ??
            _wasOffline;
        final nowOffline = next.when(
          data: isConnectivityOffline,
          loading: () => false,
          error: (_, _) => false,
        );
        if (prevOffline && !nowOffline) {
          _runSync(showSnackBar: true);
        }
        _wasOffline = nowOffline;
      },
    );
    return widget.child;
  }
}
