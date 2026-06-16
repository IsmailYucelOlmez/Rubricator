abstract final class FormValidators {
  const FormValidators._();

  static bool isNonEmpty(String value) => value.trim().isNotEmpty;

  static bool isValidEmail(String value) {
    final v = value.trim();
    return v.contains('@') && v.length >= 3;
  }

  static const int minPasswordLength = 6;

  static final RegExp _uppercase = RegExp(r'[A-Z]');
  static final RegExp _lowercase = RegExp(r'[a-z]');
  static final RegExp _punctuation = RegExp(r'\p{P}', unicode: true);

  static PasswordValidationFailure? validatePassword(String value) {
    if (value.isEmpty) return PasswordValidationFailure.empty;
    if (value.length < minPasswordLength) return PasswordValidationFailure.tooShort;
    if (!_uppercase.hasMatch(value)) return PasswordValidationFailure.missingUppercase;
    if (!_lowercase.hasMatch(value)) return PasswordValidationFailure.missingLowercase;
    if (!_punctuation.hasMatch(value)) return PasswordValidationFailure.missingPunctuation;
    return null;
  }
}

enum PasswordValidationFailure {
  empty,
  tooShort,
  missingUppercase,
  missingLowercase,
  missingPunctuation,
}
