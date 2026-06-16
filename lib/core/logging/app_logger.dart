import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../env.dart';

/// Centralized logging: debug console in all modes, Sentry breadcrumbs/events when configured.
class AppLogger {
  AppLogger._();

  static void info(
    String category,
    String message, {
    Map<String, dynamic>? data,
  }) {
    final line = '[$category] $message';
    debugPrint(line);
    if (!_sentryActive) return;
    Sentry.addBreadcrumb(
      Breadcrumb(
        category: category,
        message: message,
        level: SentryLevel.info,
        data: data,
      ),
    );
  }

  static void warning(
    String category,
    String message, {
    Map<String, dynamic>? data,
  }) {
    final line = '[$category] WARNING: $message';
    debugPrint(line);
    if (!_sentryActive) return;
    Sentry.addBreadcrumb(
      Breadcrumb(
        category: category,
        message: message,
        level: SentryLevel.warning,
        data: data,
      ),
    );
  }

  static Future<void> error(
    String category,
    String message,
    Object error, [
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  ]) async {
    debugPrint('[$category] ERROR: $message — $error');
    if (stackTrace != null) debugPrint(stackTrace.toString());
    if (!_sentryActive) return;
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      hint: Hint.withMap({
        'category': category,
        'message': message,
        if (extra != null) ...extra,
      }),
    );
  }

  static bool get _sentryActive => Env.hasSentryConfig;
}
