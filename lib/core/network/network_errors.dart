import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

bool isConnectivityOffline(List<ConnectivityResult> results) {
  return results.isEmpty ||
      results.every((r) => r == ConnectivityResult.none);
}

/// True when a failed remote call should fall back to the offline queue.
bool isLikelyNetworkError(Object error) {
  if (error is SocketException ||
      error is HttpException ||
      error is TimeoutException) {
    return true;
  }

  final typeName = error.runtimeType.toString();
  if (typeName == 'ClientException' ||
      typeName.contains('RetryableFetch')) {
    return true;
  }

  final message = error.toString().toLowerCase();
  return message.contains('socket') ||
      message.contains('network') ||
      message.contains('connection') ||
      message.contains('timeout') ||
      message.contains('timed out') ||
      message.contains('host lookup') ||
      message.contains('failed host lookup') ||
      message.contains('connection refused') ||
      message.contains('connection reset') ||
      message.contains('connection closed') ||
      message.contains('unreachable') ||
      message.contains('no route to host') ||
      message.contains('handshake') ||
      message.contains('certificate') ||
      message.contains('os error');
}

/// Remote insert failed in a way that should fall back to the offline queue.
bool shouldQueueReadingLogOnError(Object error) {
  if (isLikelyNetworkError(error)) return true;

  final typeName = error.runtimeType.toString();
  if (typeName == 'PostgrestException') {
    final code = _readExceptionCode(error);
    if (code == '23514' || code == '23505' || code == '23503') {
      return false;
    }
    return true;
  }
  if (typeName.contains('Auth')) return true;

  final message = error.toString().toLowerCase();
  return message.contains('jwt') ||
      message.contains('unauthorized') ||
      message.contains('not authenticated') ||
      message.contains('row-level security') ||
      message.contains('permission denied');
}

String? _readExceptionCode(Object error) {
  try {
    return (error as dynamic).code as String?;
  } catch (_) {
    return null;
  }
}
