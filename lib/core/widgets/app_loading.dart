import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    super.key,
    this.size = 28,
    this.strokeWidth = 2.4,
    this.centered = true,
  });

  final double size;
  final double strokeWidth;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final indicator = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(strokeWidth: strokeWidth),
    );
    if (centered) {
      return Center(child: indicator);
    }
    return indicator;
  }
}

class AppSkeletonBox extends StatefulWidget {
  const AppSkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = AppRadius.md,
  });

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  State<AppSkeletonBox> createState() => _AppSkeletonBoxState();
}

class _AppSkeletonBoxState extends State<AppSkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: Color.lerp(
              colors.surfaceContainerHighest,
              colors.surfaceContainerLow,
              t,
            ),
          ),
        );
      },
    );
  }
}

class AppListTileSkeleton extends StatelessWidget {
  const AppListTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        AppSkeletonBox(width: 56, height: 84),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeletonBox(height: 16, width: double.infinity),
              SizedBox(height: 8),
              AppSkeletonBox(height: 12, width: 120),
            ],
          ),
        ),
      ],
    );
  }
}
