import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Central Supabase client bootstrap. Keys come from [assets/.env] — never hardcode.
class SupabaseService {
  SupabaseService._();

  static Future<void> initialize() async {
    await dotenv.load(fileName: 'assets/.env');
    final url = dotenv.env['SUPABASE_URL']?.trim();
    final key = dotenv.env['SUPABASE_ANON_KEY']?.trim();
    if (url == null || url.isEmpty || key == null || key.isEmpty) {
      throw StateError(
        'Set SUPABASE_URL and SUPABASE_ANON_KEY in assets/.env.',
      );
    }
    await Supabase.initialize(url: url, anonKey: key);
  }

  static SupabaseClient get client => Supabase.instance.client;

  static String get url {
    final value = dotenv.env['SUPABASE_URL']?.trim();
    if (value == null || value.isEmpty) {
      throw StateError('Set SUPABASE_URL in assets/.env.');
    }
    return value;
  }

  static String get anonKey {
    final value = dotenv.env['SUPABASE_ANON_KEY']?.trim();
    if (value == null || value.isEmpty) {
      throw StateError('Set SUPABASE_ANON_KEY in assets/.env.');
    }
    return value;
  }

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

    final sessionToken = client.auth.currentSession?.accessToken?.trim();
    if (sessionToken != null && sessionToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $sessionToken';
    }
    return headers;
  }
}
