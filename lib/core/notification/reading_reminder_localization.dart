import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

import '../i18n/localization_service.dart';
import '../i18n/l10n/app_localizations.dart';

class ReadingReminderCopy {
  const ReadingReminderCopy({
    required this.title,
    required this.body,
    required this.channelName,
    required this.channelDescription,
  });

  final String title;
  final String body;
  final String channelName;
  final String channelDescription;
}

Future<ReadingReminderCopy> loadReadingReminderCopy({required int streak}) async {
  final prefs = await SharedPreferences.getInstance();
  final code = prefs.getString(LocalizationService.key) ??
      LocalizationService.fallbackLanguageCode;
  final l10n = lookupAppLocalizations(Locale(code));

  return ReadingReminderCopy(
    title: l10n.readingReminderTitle,
    body: streak > 0
        ? l10n.readingReminderBodyWithStreak(streak)
        : l10n.readingReminderBodyNoStreak,
    channelName: l10n.readingReminderChannelName,
    channelDescription: l10n.readingReminderChannelDescription,
  );
}
