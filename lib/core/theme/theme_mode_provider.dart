import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'app_theme_mode';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier({ThemeMode initial = ThemeMode.light}) : super(initial);

  static Future<ThemeMode> loadInitial() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == 'light') return ThemeMode.light;
    if (raw == 'dark') return ThemeMode.dark;
    return ThemeMode.light;
  }

  Future<void> setTheme(ThemeMode mode) async {
    final resolved = mode == ThemeMode.light ? ThemeMode.light : ThemeMode.dark;
    state = resolved;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, resolved == ThemeMode.light ? 'light' : 'dark');
  }
}
