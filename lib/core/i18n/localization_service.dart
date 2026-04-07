import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  static const String key = 'app_language';
  static const String fallbackLanguageCode = 'en';
  static const Set<String> supportedLanguageCodes = {'en', 'tr'};

  Future<void> saveLocale(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, _normalize(code));
  }

  Future<String?> getSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    return _normalize(raw);
  }

  String _normalize(String code) {
    return supportedLanguageCodes.contains(code) ? code : fallbackLanguageCode;
  }
}
