import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'app_theme_mode';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    state = raw == 'light' ? ThemeMode.light : ThemeMode.dark;
  }

  Future<void> setTheme(ThemeMode mode) async {
    final resolved = mode == ThemeMode.light ? ThemeMode.light : ThemeMode.dark;
    state = resolved;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, resolved == ThemeMode.light ? 'light' : 'dark');
  }
}
