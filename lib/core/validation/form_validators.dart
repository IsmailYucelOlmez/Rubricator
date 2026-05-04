abstract final class FormValidators {
  const FormValidators._();

  static bool isNonEmpty(String value) => value.trim().isNotEmpty;

  static bool isValidEmail(String value) {
    final v = value.trim();
    return v.contains('@') && v.length >= 3;
  }
}
