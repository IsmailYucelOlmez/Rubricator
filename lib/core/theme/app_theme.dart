import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
    scaffoldBackgroundColor: const Color(0xFFF8F9FB),
    appBarTheme: const AppBarTheme(centerTitle: false),
  );
}
