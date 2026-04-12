import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/i18n/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/books_providers.dart';

class AuthorDetailPage extends ConsumerWidget {
  const AuthorDetailPage({super.key, required this.authorId});

  final String authorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final asyncAuthor = ref.watch(authorDetailProvider(authorId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.author)),
      body: asyncAuthor.when(
        data: (author) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const Center(child: Icon(Icons.person, size: 96)),
              const SizedBox(height: AppSpacing.md),
              Text(
                author.name,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              if (author.birthDate != null || author.deathDate != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  [
                    if (author.birthDate != null) author.birthDate,
                    if (author.deathDate != null) '– ${author.deathDate}',
                  ].join(' '),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: AppSpacing.md + AppSpacing.xs),
              Text(
                author.bio.isEmpty ? l10n.noBiographyAvailable : author.bio,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.couldNotLoadAuthor(
                e.toString().replaceFirst('Exception: ', ''),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
