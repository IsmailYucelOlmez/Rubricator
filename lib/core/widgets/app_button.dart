import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'app_loading.dart';

/// Primary action — brand red only for actions.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: isLoading
              ? const AppLoadingIndicator(
                  size: 22,
                  strokeWidth: 2,
                  centered: false,
                )
              : Text(text),
        ),
      ),
    );
  }
}
