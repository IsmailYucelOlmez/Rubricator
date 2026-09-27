import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/i18n/locale_provider.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import 'add_turkish_book_form_sheet.dart';

/// Persistent entry point on the search page for contributing a missing
/// Turkish book to trbooks — only shown in Turkish locale, regardless of
/// whether the search box is empty or has a query.
class AddTurkishBookBanner extends ConsumerWidget {
  const AddTurkishBookBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTurkish = ref.watch(localeProvider).languageCode == 'tr';
    if (!isTurkish) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final textStyle = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.addTurkishBookBannerText,
                style: textStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            TextButton(
              onPressed: () => showAddTurkishBookSheet(context),
              style: TextButton.styleFrom(
                textStyle: textStyle,
                visualDensity: VisualDensity.compact,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(l10n.addTurkishBookBannerAction),
            ),
          ],
        ),
      ),
    );
  }
}
