import 'package:flutter/material.dart';

/// Layout breakpoints aligned with Material window size classes.
abstract final class AppBreakpoints {
  /// Phone vs tablet: use [MediaQuery.sizeOf] shortest side.
  static const double tabletShortSide = 600;

  /// When list/card areas are at least this wide, prefer two columns.
  static const double listsTwoColumnMinWidth = 640;

  /// Max width for primary content on large tablets / landscape (readability).
  static const double contentMaxWidth = 900;

  /// Narrow column for sign-in / register forms on wide screens.
  static const double formMaxWidth = 440;
}

extension AppLayoutContext on BuildContext {
  /// Tablet-sized window (shortest side ≥ [AppBreakpoints.tabletShortSide]).
  bool get isTabletLayout =>
      MediaQuery.sizeOf(this).shortestSide >= AppBreakpoints.tabletShortSide;

  /// Max width for a standard full-screen body (uncapped on phones).
  double get responsiveContentMaxWidth =>
      isTabletLayout ? AppBreakpoints.contentMaxWidth : double.infinity;
}
