import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/theme_mode_provider.dart';
import 'profile_toggle_row.dart';

class ThemeSelector extends ConsumerWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);
    final isLight = themeMode == ThemeMode.light;

    return ProfileToggleRow(
      label: l10n.themeAppearance,
      trailing: Icon(
        isLight ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        size: 26,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      onTap: () {
        ref.read(themeModeProvider.notifier).setTheme(
              isLight ? ThemeMode.dark : ThemeMode.light,
            );
      },
    );
  }
}
