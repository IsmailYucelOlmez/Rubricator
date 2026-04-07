import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/i18n/l10n/app_localizations.dart';

class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.language),
      subtitle: Text(locale.languageCode == 'tr' ? l10n.turkish : l10n.english),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          builder: (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(l10n.english),
                  onTap: () {
                    ref.read(localeProvider.notifier).changeLocale('en');
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text(l10n.turkish),
                  onTap: () {
                    ref.read(localeProvider.notifier).changeLocale('tr');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
