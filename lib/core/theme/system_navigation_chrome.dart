import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// System back/home bar colors from **device** light/dark — not app theme.
abstract final class SystemNavigationChrome {
  static const lightBackground = Color(0xFFFFFFFF);
  static const darkBackground = Color(0xFF000000);

  static bool isPlatformDark(BuildContext context) =>
      MediaQuery.platformBrightnessOf(context) == Brightness.dark;

  static Color backgroundColor(BuildContext context) =>
      isPlatformDark(context) ? darkBackground : lightBackground;

  static SystemUiOverlayStyle overlayStyle(BuildContext context) {
    final dark = isPlatformDark(context);
    return SystemUiOverlayStyle(
      systemNavigationBarColor: backgroundColor(context),
      systemNavigationBarDividerColor: backgroundColor(context),
      systemNavigationBarIconBrightness:
          dark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: true,
    );
  }
}
