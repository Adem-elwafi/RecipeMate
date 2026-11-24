/// Pure validation functions used by the authentication forms.
///
/// They live outside the widgets so they can be unit tested (see
/// `test/features/auth/auth_validators_test.dart`) and reused by both
/// login and registration.
abstract final class AuthValidators {
  static final RegExp emailPattern = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
  );

  static String? required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label est obligatoire.';
    }
    return null;
  }

  static String? email(String? value) {
    final requiredError = required(value, 'L’e-mail');
    if (requiredError != null) {
      return requiredError;
    }
    if (!emailPattern.hasMatch(value!.trim())) {
      return 'Entrez une adresse e-mail valide.';
    }
    return null;
  }

  static String? password(String? value) {
    final requiredError = required(value, 'Le mot de passe');
    if (requiredError != null) {
      return requiredError;
    }
    if (value!.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères.';
    }
    return null;
  }

  static String? confirmation(String? value, String password) {
    final requiredError = required(value, 'La confirmation');
    if (requiredError != null) {
      return requiredError;
    }
    if (value != password) {
      return 'Les mots de passe ne correspondent pas.';
    }
    return null;
  }
}
