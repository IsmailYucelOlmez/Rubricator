/// Machine-readable classification for localized UX messages.
abstract final class AppErrorCodes {
  static const String network = 'NETWORK';
  static const String timeout = 'TIMEOUT';
  static const String unknown = 'UNKNOWN';
}

class AppError {
  const AppError(this.code);

  final String code;
}
