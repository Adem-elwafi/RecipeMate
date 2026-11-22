import 'package:flutter/foundation.dart';
import 'package:recipemate/core/models/recipe.dart';

/// Result of matching a [Recipe] against the user's fridge inventory and profile.
@immutable
class RecipeMatchResult {
  const RecipeMatchResult({
    required this.recipe,
    required this.matchPercentage,
    required this.matchedIngredients,
    required this.missingIngredients,
    required this.usesExpiringSoonIngredient,
    required this.hasAllergyConflict,
    required this.difficultyLabel,
  });

  final Recipe recipe;
  final int matchPercentage;
  final List<String> matchedIngredients;
  final List<String> missingIngredients;
  final bool usesExpiringSoonIngredient;
  final bool hasAllergyConflict;
  final String difficultyLabel;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is RecipeMatchResult &&
            runtimeType == other.runtimeType &&
            recipe == other.recipe &&
            matchPercentage == other.matchPercentage &&
            listEquals(matchedIngredients, other.matchedIngredients) &&
            listEquals(missingIngredients, other.missingIngredients) &&
            usesExpiringSoonIngredient == other.usesExpiringSoonIngredient &&
            hasAllergyConflict == other.hasAllergyConflict &&
            difficultyLabel == other.difficultyLabel;
  }

  @override
  int get hashCode => Object.hash(
    recipe,
    matchPercentage,
    Object.hashAll(matchedIngredients),
    Object.hashAll(missingIngredients),
    usesExpiringSoonIngredient,
    hasAllergyConflict,
    difficultyLabel,
  );
}
