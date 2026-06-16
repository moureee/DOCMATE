class AuthValidators {
  AuthValidators._();

  static final RegExp _emailPattern = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$",
  );

  static final RegExp _namePattern = RegExp(
    r"^[A-Za-z][A-Za-z .'-]{1,49}$",
  );

  static final RegExp _phonePattern = RegExp(
    r'^\+[1-9]\d{7,14}$',
  );

  static final RegExp _strongPasswordPattern = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+\-={}\[\]:;"<>,.?/~`|\\]).{8,64}$',
  );

  static bool isValidEmail(String value) {
    return _emailPattern.hasMatch(value.trim());
  }

  static bool isValidName(String value) {
    return _namePattern.hasMatch(value.trim());
  }

  static bool isValidPhone(String value) {
    return _phonePattern.hasMatch(value.replaceAll(RegExp(r'\s+'), ''));
  }

  static bool isStrongPassword(String value) {
    return _strongPasswordPattern.hasMatch(value);
  }

  static String normalizePhone(String value) {
    return value.replaceAll(RegExp(r'[\s()-]'), '');
  }

  static const String passwordHelp =
      'Use 8-64 characters with uppercase, lowercase, number, and symbol.';
}
