import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widgets/global_error_view.dart';

/// Installs app-wide widget build error handling (Flutter's global error boundary).
abstract final class AppGlobalErrorHandler {
  static VoidCallback? _restartApp;

  static void install({VoidCallback? restartApp}) {
    _restartApp = restartApp;

    ErrorWidget.builder = (FlutterErrorDetails details) {
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
      return GlobalErrorView(onRetry: _restartApp);
    };
  }
}
