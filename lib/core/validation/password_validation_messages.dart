import '../i18n/l10n/app_localizations.dart';
import 'form_validators.dart';

extension PasswordValidationMessages on AppLocalizations {
  String? passwordFieldError(String password) {
    return switch (FormValidators.validatePassword(password)) {
      null => null,
      PasswordValidationFailure.empty => uxPasswordRequired,
      PasswordValidationFailure.tooShort => uxPasswordTooShort,
      PasswordValidationFailure.missingUppercase => uxPasswordMissingUppercase,
      PasswordValidationFailure.missingLowercase => uxPasswordMissingLowercase,
      PasswordValidationFailure.missingPunctuation => uxPasswordMissingPunctuation,
    };
  }
}
