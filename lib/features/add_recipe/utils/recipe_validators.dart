/// Pure validators for the "add recipe" form.
///
/// Kept outside the widget so they can be unit tested and explained like the
/// form validators from the Flutter course support (Form + validator).
abstract final class RecipeValidators {
  static String? required(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label est obligatoire.';
    }
    return null;
  }

  /// Point B2 : évite les recettes d'une seule lettre sans changer le message
  /// « obligatoire » quand le champ est vide.
  static String? minLength(String? value, String label, int minimum) {
    final requiredError = required(value, label);
    if (requiredError != null) {
      return requiredError;
    }
    if (value!.trim().length < minimum) {
      return '$label doit contenir au moins $minimum caractères.';
    }
    return null;
  }

  static String? positiveInteger(String? value, String label) {
    final requiredError = required(value, label);
    if (requiredError != null) {
      return requiredError;
    }
    final number = int.tryParse(value!.trim());
    if (number == null || number <= 0) {
      return '$label doit être un nombre entier positif.';
    }
    return null;
  }

  static String? positiveNumber(String? value, String label) {
    final requiredError = required(value, label);
    if (requiredError != null) {
      return requiredError;
    }
    final number = double.tryParse(value!.trim().replaceAll(',', '.'));
    if (number == null || number <= 0) {
      return '$label doit être un nombre positif.';
    }
    return null;
  }

  /// Point B2 : champs nutritionnels facultatifs (ex. fibres). Une valeur vide
  /// est acceptée, mais une valeur saisie doit rester strictement positive.
  static String? optionalPositiveNumber(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return positiveNumber(value, label);
  }
}
