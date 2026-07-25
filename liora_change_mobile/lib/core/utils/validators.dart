/// Shared form validators.
///
/// Messages stay plain and actionable — never blaming — per the copy rules in
/// `docs/mvp/teams/MOBILE-TEAM-GUIDE.md` §7.
abstract final class Validators {
  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Minimum password length from `docs/mvp/05-api-contract.md` §1.1.
  static const int minPasswordLength = 8;

  static String? required(String? value, {required String field}) {
    if (value == null || value.trim().isEmpty) return 'Enter your $field';
    return null;
  }

  static String? email(String? value) {
    final String? empty = required(value, field: 'email');
    if (empty != null) return empty;
    if (!_email.hasMatch(value!.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Login only checks presence — the server decides whether it is correct.
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Enter your password';
    return null;
  }

  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) return 'Choose a password';
    if (value.length < minPasswordLength) {
      return 'Use at least $minPasswordLength characters';
    }
    return null;
  }

  static String? passwordConfirmation(String? value, String password) {
    if (value == null || value.isEmpty) return 'Repeat your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }
}
