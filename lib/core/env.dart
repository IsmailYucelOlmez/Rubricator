/// Compile-time configuration from `--dart-define` / `--dart-define-from-file`.
///
/// Example:
/// `flutter build apk --release --dart-define-from-file=env.production.json`
class Env {
  Env._();

  static const apiUrl = String.fromEnvironment('API_URL');

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get hasSupabaseConfig =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  static void assertConfigured() {
    if (hasSupabaseConfig) return;
    throw StateError(
      'Missing dart-defines for SUPABASE_URL and SUPABASE_ANON_KEY.\n'
      'Debug: flutter run --dart-define-from-file=env.development.json\n'
      'Release APK: flutter build apk --release '
      '--dart-define-from-file=env.production.json\n'
      'Release AAB: flutter build appbundle --release '
      '--dart-define-from-file=env.production.json',
    );
  }
}
