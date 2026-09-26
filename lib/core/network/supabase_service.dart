import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../env.dart';
import '../logging/app_logger.dart';

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

  /// Dio interceptor that stamps every request with *fresh* [edgeFunctionHeaders].
  ///
  /// A `Dio` built once with static `headers:` bakes in the session access
  /// token as it was at construction; that token expires after about an hour
  /// (or was absent because the user hadn't signed in yet), and the
  /// `rubricatorApi` edge function verifies it. Reading the current session per
  /// request keeps the token valid for as long as supabase_flutter keeps
  /// refreshing it.
  static Interceptor edgeFunctionAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers.addAll(edgeFunctionHeaders());
        handler.next(options);
      },
    );
  }

  /// Headers for Edge Function HTTP calls.
  ///
  /// `sb_publishable_*` keys are not JWTs — never send them as Bearer tokens.
  /// With [verify_jwt = false] on `google-books` / `rubricatorApi`, `apikey`
  /// alone is enough for anonymous traffic; logged-in users also send their
  /// session access token.
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
