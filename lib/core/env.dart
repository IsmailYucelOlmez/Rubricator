import 'package:flutter_dotenv/flutter_dotenv.dart';

/// App configuration from `--dart-define` / `--dart-define-from-file`, with
/// optional fallback to `assets/.env` via flutter_dotenv.
///
/// Priority: non-empty dart-define wins, otherwise dotenv.
///
/// Local: `flutter run` loads `assets/.env` automatically.
/// Release: prefer `--dart-define-from-file=env.production.json`.
class Env {
  Env._();

  static const _dotenvAsset = 'assets/.env';

  static const _apiUrlDefine = String.fromEnvironment('API_URL');
  static const _supabaseUrlDefine = String.fromEnvironment('SUPABASE_URL');
  static const _supabaseAnonKeyDefine =
      String.fromEnvironment('SUPABASE_ANON_KEY');
  static const _sentryDsnDefine = String.fromEnvironment('SENTRY_DSN');
  static const _semanticApiBaseUrlDefine =
      String.fromEnvironment('SEMANTIC_API_BASE_URL');
  static const _semanticApiKeyDefine = String.fromEnvironment('SEMANTIC_API_KEY');

  /// Loads `assets/.env` when present. Safe to call when the asset is missing.
  static Future<void> load() async {
    await dotenv.load(fileName: _dotenvAsset, isOptional: true);
  }

  static String get apiUrl => _resolve('API_URL', _apiUrlDefine);

  static String get supabaseUrl => _resolve('SUPABASE_URL', _supabaseUrlDefine);

  static String get supabaseAnonKey =>
      _resolve('SUPABASE_ANON_KEY', _supabaseAnonKeyDefine);

  static String get sentryDsn => _resolve('SENTRY_DSN', _sentryDsnDefine);

  static String get semanticApiBaseUrl =>
      _resolve('SEMANTIC_API_BASE_URL', _semanticApiBaseUrlDefine);

  static String get semanticApiKey =>
      _resolve('SEMANTIC_API_KEY', _semanticApiKeyDefine);

  static bool get hasSentryConfig => sentryDsn.trim().isNotEmpty;

  static bool get hasSemanticApiConfig => semanticApiBaseUrl.trim().isNotEmpty;

  static bool get hasSupabaseConfig =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  static String _resolve(String key, String fromDefine) {
    final defined = fromDefine.trim();
    if (defined.isNotEmpty) return defined;
    if (!dotenv.isInitialized) return '';
    return dotenv.maybeGet(key)?.trim() ?? '';
  }

  static void assertConfigured() {
    if (hasSupabaseConfig) return;
    throw StateError(
      'Missing SUPABASE_URL / SUPABASE_ANON_KEY.\n'
      'Debug: add them to assets/.env (loaded by flutter run), or use\n'
      '  flutter run --dart-define-from-file=env.development.json\n'
      'Release APK: flutter build apk --release '
      '--dart-define-from-file=env.production.json\n'
      'Release AAB: flutter build appbundle --release '
      '--dart-define-from-file=env.production.json',
    );
  }
}
