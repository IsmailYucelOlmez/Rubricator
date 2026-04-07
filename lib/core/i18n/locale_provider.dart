import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'localization_service.dart';

const supportedLocales = [Locale('en'), Locale('tr')];

final localizationServiceProvider = Provider<LocalizationService>(
  (ref) => LocalizationService(),
);

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(ref.read(localizationServiceProvider)),
);

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(this._service) : super(const Locale('en')) {
    loadLocale();
  }

  final LocalizationService _service;

  Future<void> loadLocale() async {
    final saved = await _service.getSavedLocale();
    if (saved != null) {
      state = Locale(saved);
    }
  }

  Future<void> changeLocale(String code) async {
    final normalized = LocalizationService.supportedLanguageCodes.contains(code)
        ? code
        : LocalizationService.fallbackLanguageCode;
    state = Locale(normalized);
    await _service.saveLocale(normalized);
  }
}
