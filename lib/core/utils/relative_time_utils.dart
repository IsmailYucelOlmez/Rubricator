import '../i18n/l10n/app_localizations.dart';

String formatRelativeTime(DateTime value, AppLocalizations l10n) {
  final diff = DateTime.now().difference(value.toLocal());
  if (diff.inMinutes < 1) return l10n.relativeTimeJustNow;
  if (diff.inHours < 1) return l10n.relativeTimeMinutesAgo(diff.inMinutes);
  if (diff.inDays < 1) return l10n.relativeTimeHoursAgo(diff.inHours);
  if (diff.inDays < 7) return l10n.relativeTimeDaysAgo(diff.inDays);
  return l10n.relativeTimeWeeksAgo(diff.inDays ~/ 7);
}
