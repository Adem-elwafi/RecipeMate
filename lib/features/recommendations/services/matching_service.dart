import 'package:recipemate/core/models/fridge_item.dart';
import 'package:recipemate/core/models/ingredient.dart';
import 'package:recipemate/core/models/recipe.dart';
import 'package:recipemate/core/models/user_profile.dart';
import 'package:recipemate/features/fridge/providers/fridge_provider.dart';
import 'package:recipemate/features/recommendations/models/recipe_match_result.dart';

/// Available sorting criteria for AI recipe recommendations.
enum RecommendationSort {
  match('Match'),
  time('Temps'),
  calories('Calories');

  const RecommendationSort(this.label);

  final String label;
}

/// Pure Dart engine that scores, filters, and ranks recipes against fridge stock.
class MatchingService {
  const MatchingService();

  static final RegExp _cutPrefixPattern = RegExp(
    r"^(blancs?|filets?|pav[ée]s?|tranches?)\s+d[e'’]\s*",
    caseSensitive: false,
  );

  static final List<RegExp> _qualifierSuffixPatterns = [
    RegExp(r'\s+extra\s+vierge$', caseSensitive: false),
    RegExp(r'\s+hass$', caseSensitive: false),
    RegExp(r'\s+(aop|igp|bio)$', caseSensitive: false),
    RegExp(r'\s+fra[iî](?:s|ches?)$', caseSensitive: false),
  ];

  /// Scores and ranks [recipes] using [fridgeItems] and [userProfile].
  List<RecipeMatchResult> rankRecipes({
    required List<Recipe> recipes,
    required List<FridgeItem> fridgeItems,
    required UserProfile userProfile,
    RecommendationSort sort = RecommendationSort.match,
    bool excludeAllergens = true,
  }) {
    final results = <RecipeMatchResult>[];

    for (final recipe in recipes) {
      final hasAllergyConflict = _hasAllergyConflict(recipe, userProfile);
      if (excludeAllergens && hasAllergyConflict) {
        continue;
      }

      final matched = <String>[];
      final missing = <String>[];
      var usesExpiringSoon = false;

      for (final recipeIng in recipe.ingredients) {
        final matchingFridgeItems = fridgeItems
            .where((item) => _ingredientsMatch(item, recipeIng))
            .toList();

        final displayName = _shortDisplayName(recipeIng.ingredient.name);
        if (matchingFridgeItems.isNotEmpty) {
          matched.add(displayName);
          if (matchingFridgeItems.any((item) => item.isExpiringSoon)) {
            usesExpiringSoon = true;
          }
        } else {
          missing.add(displayName);
        }
      }

      final basePercentage = recipe.ingredients.isEmpty
          ? 0
          : ((matched.length / recipe.ingredients.length) * 100).round();

      // Prioritize recipes that rescue soon-to-expire ingredients.
      final bonus = (usesExpiringSoon && matched.isNotEmpty) ? 5 : 0;
      final matchPercentage = (basePercentage + bonus).clamp(0, 100);

      results.add(
        RecipeMatchResult(
          recipe: recipe,
          matchPercentage: matchPercentage,
          matchedIngredients: List<String>.unmodifiable(matched),
          missingIngredients: List<String>.unmodifiable(missing),
          usesExpiringSoonIngredient: usesExpiringSoon,
          hasAllergyConflict: hasAllergyConflict,
          difficultyLabel: _computeDifficultyLabel(recipe),
        ),
      );
    }

    results.sort((a, b) => _compareResults(a, b, sort));
    return List<RecipeMatchResult>.unmodifiable(results);
  }

  /// Counts recipes with at least 50% ingredient match.
  int countPossibleRecipes(List<RecipeMatchResult> results) {
    return results.where((result) => result.matchPercentage >= 50).length;
  }

  bool _hasAllergyConflict(Recipe recipe, UserProfile userProfile) {
    if (recipe.allergens.isEmpty || userProfile.allergies.isEmpty) {
      return false;
    }

    for (final recipeAllergen in recipe.allergens) {
      final normRecipe = normalizeIngredientName(recipeAllergen);
      if (normRecipe.isEmpty) {
        continue;
      }
      for (final userAllergy in userProfile.allergies) {
        final normUser = normalizeIngredientName(userAllergy);
        if (normUser.isEmpty) {
          continue;
        }
        if (normRecipe.contains(normUser) || normUser.contains(normRecipe)) {
          return true;
        }
      }
    }
    return false;
  }

  bool _ingredientsMatch(FridgeItem fridgeItem, RecipeIngredient recipeIng) {
    if (fridgeItem.ingredient.id == recipeIng.ingredient.id) {
      return true;
    }

    final fridgeName = normalizeIngredientName(fridgeItem.ingredient.name);
    final targetName = normalizeIngredientName(recipeIng.ingredient.name);
    if (fridgeName.isEmpty || targetName.isEmpty) {
      return false;
    }

    if (fridgeName.contains(targetName) || targetName.contains(fridgeName)) {
      return true;
    }

    final fridgeRoot = _singularPluralRoot(fridgeName);
    final targetRoot = _singularPluralRoot(targetName);
    if (fridgeRoot.length >= 3 && targetRoot.length >= 3) {
      return fridgeRoot.contains(targetRoot) || targetRoot.contains(fridgeRoot);
    }

    return false;
  }

  String _singularPluralRoot(String normalized) {
    final words = normalized
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) {
          if (word.length > 3 && (word.endsWith('s') || word.endsWith('x'))) {
            return word.substring(0, word.length - 1);
          }
          return word;
        });
    return words.join(' ');
  }

  String _shortDisplayName(String rawName) {
    var name = rawName.trim();
    if (name.isEmpty) {
      return rawName;
    }

    name = name.replaceFirst(_cutPrefixPattern, '').trim();

    var changed = true;
    while (changed) {
      changed = false;
      for (final pattern in _qualifierSuffixPatterns) {
        final updated = name.replaceFirst(pattern, '').trim();
        if (updated != name && updated.isNotEmpty) {
          name = updated;
          changed = true;
        }
      }
    }

    if (name.isEmpty) {
      return rawName.trim();
    }
    return name[0].toUpperCase() + name.substring(1);
  }

  String _computeDifficultyLabel(Recipe recipe) {
    if (recipe.totalTimeMinutes <= 25 && recipe.instructions.length <= 5) {
      return 'Facile';
    }
    if (recipe.totalTimeMinutes <= 45) {
      return 'Moyen';
    }
    return 'Avancé';
  }

  int _compareResults(
    RecipeMatchResult a,
    RecipeMatchResult b,
    RecommendationSort sort,
  ) {
    switch (sort) {
      case RecommendationSort.match:
        final matchDiff = b.matchPercentage.compareTo(a.matchPercentage);
        if (matchDiff != 0) {
          return matchDiff;
        }
        if (a.usesExpiringSoonIngredient != b.usesExpiringSoonIngredient) {
          return a.usesExpiringSoonIngredient ? -1 : 1;
        }
        return a.recipe.totalTimeMinutes.compareTo(b.recipe.totalTimeMinutes);

      case RecommendationSort.time:
        final timeDiff = a.recipe.totalTimeMinutes.compareTo(
          b.recipe.totalTimeMinutes,
        );
        if (timeDiff != 0) {
          return timeDiff;
        }
        return b.matchPercentage.compareTo(a.matchPercentage);

      case RecommendationSort.calories:
        final calDiff = a.recipe.calories.compareTo(b.recipe.calories);
        if (calDiff != 0) {
          return calDiff;
        }
        return b.matchPercentage.compareTo(a.matchPercentage);
    }
  }
}
