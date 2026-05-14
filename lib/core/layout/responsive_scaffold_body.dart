import 'package:flutter/material.dart';

import 'app_breakpoints.dart';

/// Centers the child and caps width when useful: tablets, very wide phone
/// landscape, or an explicit [maxWidth] (e.g. [AppBreakpoints.formMaxWidth]).
class ResponsiveScaffoldBody extends StatelessWidget {
  const ResponsiveScaffoldBody({
    super.key,
    required this.child,
    this.maxWidth,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;

  /// When null, uses [AppBreakpoints.contentMaxWidth] on tablet only.
  final double? maxWidth;

  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.sizeOf(context);
    final double cap;
    if (maxWidth != null) {
      cap = maxWidth!;
    } else if (context.isTabletLayout) {
      cap = AppBreakpoints.contentMaxWidth;
    } else if (mq.width > AppBreakpoints.contentMaxWidth) {
      cap = AppBreakpoints.contentMaxWidth;
    } else {
      cap = double.infinity;
    }
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: cap),
        child: child,
      ),
    );
  }
}
