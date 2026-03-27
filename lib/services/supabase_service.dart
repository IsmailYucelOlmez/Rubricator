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
}
