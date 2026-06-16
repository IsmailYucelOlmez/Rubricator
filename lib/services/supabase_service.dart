import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/env.dart';
import '../core/logging/app_logger.dart';

/// Central Supabase client bootstrap. Keys come from dart-defines — never hardcode.
class SupabaseService {
  SupabaseService._();

  static Future<void> initialize() async {
    Env.assertConfigured();
    await Supabase.initialize(
      url: Env.supabaseUrl.trim(),
      anonKey: Env.supabaseAnonKey.trim(),
    );
    AppLogger.info('supabase', 'Client initialized');
  }

  static SupabaseClient get client => Supabase.instance.client;

  static String get url => Env.supabaseUrl.trim();

  static String get anonKey => Env.supabaseAnonKey.trim();

  /// Headers for Edge Function HTTP calls.
  ///
  /// `sb_publishable_*` keys are not JWTs — never send them as Bearer tokens.
  /// With [verify_jwt = false] on `google-books`, `apikey` alone is enough for
  /// anonymous traffic; logged-in users also send their session access token.
  static Map<String, String> edgeFunctionHeaders() {
    final key = anonKey;
    final headers = <String, String>{'apikey': key};

    if (key.startsWith('eyJ')) {
      headers['Authorization'] = 'Bearer $key';
      return headers;
    }

    final sessionToken = client.auth.currentSession?.accessToken.trim();
    if (sessionToken != null && sessionToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $sessionToken';
    }
    return headers;
  }
}
