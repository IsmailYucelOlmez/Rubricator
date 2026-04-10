import 'package:flutter/material.dart';

/// Section title — maps to headline typography from theme.
class AppSectionTitle extends StatelessWidget {
  const AppSectionTitle(this.data, {super.key, this.maxLines = 1});

  final String data;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }
}

/// Secondary / supporting line.
class AppSecondaryText extends StatelessWidget {
  const AppSecondaryText(this.data, {super.key, this.maxLines});

  final String data;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}
