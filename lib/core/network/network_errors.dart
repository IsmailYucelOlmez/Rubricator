import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

bool isConnectivityOffline(List<ConnectivityResult> results) {
  return results.isEmpty ||
      results.every((r) => r == ConnectivityResult.none);
}

bool isLikelyNetworkError(Object error) {
  if (error is SocketException) return true;
  final message = error.toString().toLowerCase();
  return message.contains('socket') ||
      message.contains('network') ||
      message.contains('connection') ||
      message.contains('timeout') ||
      message.contains('host lookup') ||
      message.contains('failed host lookup');
}
