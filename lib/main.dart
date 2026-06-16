import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/notification/reading_reminder_scheduler.dart';
import 'core/logging/app_logger.dart';

import 'services/notification_service.dart';

import 'app.dart';

import 'core/env.dart';

import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SentryFlutter.init((options) {
    options.dsn = Env.sentryDsn;
    options.environment = kReleaseMode ? 'production' : 'development';
    options.tracesSampleRate = kReleaseMode ? 0.1 : 0.0;
    options.debug = kDebugMode;
  });

  if (kReleaseMode) {
    AppLogger.info(
      'startup',
      'Release env check',
      data: {
        'apiUrl': Env.apiUrl.isEmpty ? '(empty)' : Env.apiUrl,
        'supabaseUrl': Env.supabaseUrl.isEmpty ? '(empty)' : Env.supabaseUrl,
        'sentryEnabled': Env.hasSentryConfig,
      },
    );
  }

  try {
    AppLogger.info('startup', 'Initializing Supabase');
    await SupabaseService.initialize();

    AppLogger.info('startup', 'Initializing notifications');
    await NotificationService.instance.initialize();

    AppLogger.info('startup', 'Scheduling reading reminders');
    await ReadingReminderScheduler.ensureScheduledFromPrefs();

    _bindSentryUserContext();

    AppLogger.info('startup', 'Bootstrap complete');
    runApp(const ProviderScope(child: BookApp()));
  } catch (error, stackTrace) {
    await AppLogger.error('startup', 'Bootstrap failed', error, stackTrace);
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stackTrace),
    );
    runApp(_ConfigErrorApp(message: error.toString()));
  }
}

void _bindSentryUserContext() {
  if (!Env.hasSentryConfig) return;

  SupabaseService.client.auth.onAuthStateChange.listen((data) {
    final user = data.session?.user;
    Sentry.configureScope((scope) {
      if (user == null) {
        scope.setUser(null);
        return;
      }
      scope.setUser(SentryUser(id: user.id, email: user.email));
    });
    AppLogger.info(
      'auth',
      user == null ? 'Session ended' : 'Session active',
      data: user == null ? null : {'userId': user.id},
    );
  });
}

class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Supabase yapılandırması eksik',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Release build env.production.json ile alınmalı:\n'
                  'flutter build appbundle --release '
                  '--dart-define-from-file=env.production.json',
                ),
                const SizedBox(height: 12),
                Text(message),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
