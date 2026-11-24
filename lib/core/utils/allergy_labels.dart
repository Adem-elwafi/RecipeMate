import 'package:flutter/foundation.dart';

/// Point A5 : corrige les fautes de frappe des allergies à la frontière des
/// données.
///
/// Le texte « Guten, Lait » vu sur téléphone ne vient pas d'un libellé codé en
/// dur (le code contient déjà « Gluten ») : il vient d'une valeur enregistrée
/// telle quelle dans Firestore. On normalise donc à la lecture **et** à
/// l'écriture pour réparer les anciennes données sans casser les valeurs
/// composées comme « Gluten (Avoine) ».
abstract final class AllergyLabels {
  static const Map<String, String> _canonical = <String, String>{
    'guten': 'Gluten',
    'gluten': 'Gluten',
    'lait': 'Lait',
    'oeufs': 'Œufs',
    'œufs': 'Œufs',
    'arachides': 'Arachides',
    'poisson': 'Poisson',
    'soja': 'Soja',
  };

  /// Corrige un libellé isolé en conservant son complément entre parenthèses.
  static String correct(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    var corrected = trimmed;
    for (final entry in _canonical.entries) {
      corrected = corrected.replaceAllMapped(
        RegExp(r'\b' + RegExp.escape(entry.key) + r'\b', caseSensitive: false),
        (Match match) => entry.value,
      );
    }

    if (corrected != trimmed) {
      debugPrint('Allergie normalisée : "$trimmed" → "$corrected"');
    }
    return corrected;
  }

  /// Corrige une liste complète (profils et allergènes de recettes).
  static List<String> correctAll(Iterable<dynamic>? values) =>
      (values ?? const <dynamic>[])
          .where((dynamic value) => value != null)
          .map((dynamic value) => value.toString().trim())
          .where((String value) => value.isNotEmpty)
          .map(correct)
          .toList(growable: false);
}
