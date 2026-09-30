import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'localization_service.dart';

const supportedLocales = [Locale('en'), Locale('tr')];

final localizationServiceProvider = Provider<LocalizationService>(
  (ref) => LocalizationService(),
);

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(ref.read(localizationServiceProvider)),
);

class LocaleNotifier extends StateNotifier<Locale> {
  /// [initial] should come from [loadInitial] before `runApp`: starting from a
  /// placeholder and flipping once prefs load rebuilds every locale-dependent
  /// provider, which fired the whole home page load twice (en, then tr).
  LocaleNotifier(this._service, {Locale? initial})
    : super(initial ?? const Locale('en')) {
    Intl.defaultLocale = state.languageCode;
    loadLocale();
  }

  final LocalizationService _service;

  static Future<Locale> loadInitial(LocalizationService service) async {
    final saved = await service.getSavedLocale();
    return Locale(saved ?? _deviceLanguageCode);
  }

  /// Device language when supported, else the app fallback.
  static String get _deviceLanguageCode {
    final deviceCode = PlatformDispatcher.instance.locale.languageCode;
    return LocalizationService.supportedLanguageCodes.contains(deviceCode)
        ? deviceCode
        : LocalizationService.fallbackLanguageCode;
  }

  Future<void> loadLocale() async {
    final saved = await _service.getSavedLocale();
    final code = saved ?? _deviceLanguageCode;
    // Same language: keep the existing instance so dependents don't rebuild.
    if (code == state.languageCode) return;
    state = Locale(code);
    Intl.defaultLocale = code;
  }

  Future<void> changeLocale(String code) async {
    final normalized = LocalizationService.supportedLanguageCodes.contains(code)
        ? code
        : LocalizationService.fallbackLanguageCode;
    state = Locale(normalized);
    Intl.defaultLocale = normalized;
    await _service.saveLocale(normalized);
  }
}
