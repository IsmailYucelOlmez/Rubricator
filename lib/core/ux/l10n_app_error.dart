import '../errors/app_error.dart';
import '../errors/error_mapper.dart';
import '../i18n/l10n/app_localizations.dart';

extension AppLocalizationsUxErrors on AppLocalizations {
  String userFacingMessage(Object error) {
    final code = ErrorMapper.map(error).code;
    switch (code) {
      case AppErrorCodes.network:
        return uxErrorNetwork;
      case AppErrorCodes.timeout:
        return uxErrorTimeout;
      default:
        return uxErrorUnknown;
    }
  }
}
