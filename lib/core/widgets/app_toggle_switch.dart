import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Brand toggle with fixed inactive-like size and always-on active colors.
/// Only the white thumb slides when [value] changes.
class AppToggleSwitch extends StatelessWidget {
  const AppToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Matches Material 3 inactive switch visual scale (no active growth).
  static const double _width = 40;
  static const double _height = 24;
  static const double _thumb = 18;
  static const double _pad = 3;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    return Semantics(
      button: true,
      toggled: value,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled ? () => onChanged!(!value) : null,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: _width,
          height: _height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(_height / 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(_pad),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                child: const SizedBox(
                  width: _thumb,
                  height: _thumb,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
