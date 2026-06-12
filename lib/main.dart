import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:workmanager/workmanager.dart';
import 'core/background/notification_task.dart';
import 'services/notification_service.dart';

import 'app.dart';
import 'core/env.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kReleaseMode) {
    // Release doğrulama: logcat'te (empty) görürseniz define'lar build'e girmemiştir.
    // ignore: avoid_print
    print('Env.apiUrl=${Env.apiUrl.isEmpty ? "(empty)" : Env.apiUrl}');
    // ignore: avoid_print
    print(
      'Env.supabaseUrl=${Env.supabaseUrl.isEmpty ? "(empty)" : Env.supabaseUrl}',
    );
  }

  try {
    await SupabaseService.initialize();

    await NotificationService.instance.initialize();

    await Workmanager().initialize(
      callbackDispatcher,
    );
    
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stackTrace),
    );
    runApp(_ConfigErrorApp(message: error.toString()));
    return;
  }

  runApp(const ProviderScope(child: BookApp()));
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
