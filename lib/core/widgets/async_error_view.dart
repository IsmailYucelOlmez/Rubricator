import 'package:flutter/material.dart';

import '../errors/app_error.dart';
import '../errors/error_mapper.dart';
import 'app_error_view.dart';
import 'app_no_internet_view.dart';

/// Picks [AppNoInternetView] for network failures, [AppErrorView] otherwise.
class AsyncErrorView extends StatelessWidget {
  const AsyncErrorView({
    super.key,
    required this.error,
    required this.onRetry,
    this.compact = false,
  });

  final Object error;
  final VoidCallback onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final code = ErrorMapper.map(error).code;
    if (code == AppErrorCodes.network) {
      return AppNoInternetView(onRetry: onRetry, compact: compact);
    }
    return AppErrorView(error: error, onRetry: onRetry, compact: compact);
  }
}
