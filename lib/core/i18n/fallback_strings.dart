import 'dart:ui';

import 'package:intl/intl.dart';

import 'l10n/app_localizations.dart';

/// Locale-aware placeholder text for data-layer parsing sites (model
/// `fromJson` factories, repositories) that have no `BuildContext` to pull
/// [AppLocalizations] from. Tracks [LocaleNotifier]'s [Intl.defaultLocale].
abstract final class FallbackStrings {
  static AppLocalizations get _l10n =>
      lookupAppLocalizations(Locale(Intl.defaultLocale ?? 'en'));

  static String get unknownTitle => _l10n.unknownTitle;

  static String get unknownAuthor => _l10n.unknownAuthor;
}
