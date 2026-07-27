import 'package:flutter/material.dart';

import 'virgil_colors.dart';

/// Shared VIRGIL + BETA brand row used on hub and recommendation pages.
class VirgilBrandHeader extends StatelessWidget {
  const VirgilBrandHeader({
    super.key,
    required this.badge,
    this.ink,
  });

  final String badge;
  final Color? ink;

  static const double height = 64;

  @override
  Widget build(BuildContext context) {
    final color = ink ?? VirgilColors.of(context).ink;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Virgil',
          style: TextStyle(
            fontFamily: 'Megrim',
            fontSize: 40,
            height: 1,
            letterSpacing: 2,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 24,
          height: 12,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            badge.toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Megrim',
              fontSize: 8,
              fontWeight: FontWeight.w700,
              height: 1,
              letterSpacing: 0.2,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
