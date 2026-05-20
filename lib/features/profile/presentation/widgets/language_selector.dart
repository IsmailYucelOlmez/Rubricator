import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/i18n/l10n/app_localizations.dart';
import 'profile_toggle_row.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  static const _flagStyle = TextStyle(fontSize: 26, height: 1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final isTurkish = locale.languageCode == 'tr';

    return ProfileToggleRow(
      label: l10n.language,
      trailing: Text(
        isTurkish ? '🇹🇷' : '🇬🇧',
        style: _flagStyle,
      ),
      onTap: () {
        ref.read(localeProvider.notifier).changeLocale(isTurkish ? 'en' : 'tr');
      },
    );
  }
}
