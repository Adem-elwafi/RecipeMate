import 'package:recipemate/core/models/ingredient.dart';

/// Point B2 : mots-clés normalisés utilisés pour retrouver une recette à partir
/// du contenu du frigo sans dépendre de la casse ni des accents saisis.
abstract final class RecipeKeywords {
  static const Map<String, String> _accentMap = <String, String>{
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'ç': 'c',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'ì': 'i',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ñ': 'n',
    'ò': 'o',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ÿ': 'y',
    'œ': 'oe',
  };

  /// « Épinards frais » devient « epinards frais ».
  static String normalize(String value) {
    final buffer = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      final character = String.fromCharCode(rune);
      buffer.write(_accentMap[character] ?? character);
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Construit `ingredientKeywords[]` à partir des ingrédients du formulaire.
  ///
  /// On garde le nom complet normalisé et chaque mot d'au moins trois
  /// caractères, ce qui permet une recherche tolérante sur « tomate » comme sur
  /// « tomates cerises ».
  static List<String> fromIngredients(Iterable<RecipeIngredient> ingredients) {
    final keywords = <String>{};
    for (final item in ingredients) {
      final name = item.ingredient.name.trim();
      if (name.isEmpty) {
        continue;
      }
      final normalized = normalize(name);
      if (normalized.isEmpty) {
        continue;
      }
      keywords.add(normalized);
      for (final word in normalized.split(' ')) {
        if (word.length >= 3) {
          keywords.add(word);
        }
      }
    }
    return _sorted(keywords);
  }

  /// Utilisé quand un ancien document Firestore n'a pas encore le champ.
  static List<String> fromNames(Iterable<Object?> names) {
    final keywords = <String>{};
    for (final name in names) {
      if (name == null) {
        continue;
      }
      final normalized = normalize(name.toString());
      if (normalized.isNotEmpty) {
        keywords.add(normalized);
      }
    }
    return _sorted(keywords);
  }

  static List<String> _sorted(Set<String> keywords) {
    final sorted = keywords.toList(growable: false)..sort();
    return List<String>.unmodifiable(sorted);
  }
}
