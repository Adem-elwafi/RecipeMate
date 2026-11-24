import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipemate/core/data/mock_data.dart';
import 'package:recipemate/core/data/recipe_api.dart';
import 'package:recipemate/core/data/recipe_database.dart';
import 'package:recipemate/core/models/recipe.dart';

/// Looks up a recipe in the API cache or fake catalogue, falling back to the first one.
Recipe findRecipeById(String recipeId) {
  if (apiRecipeCache.containsKey(recipeId)) {
    return apiRecipeCache[recipeId]!;
  }
  for (final recipe in MockData.recipes) {
    if (recipe.id == recipeId) return recipe;
  }
  return MockData.recipes.first;
}

/// Ids of the ingredients currently available in the fridge, from the
/// database (used to seed the "in fridge" state of the recipe sheet).
final fridgeIngredientIdsProvider = Provider<Set<String>>((ref) {
  final fridgeItems = ref.watch(recipeDatabaseProvider).fridgeItems;
  return fridgeItems.map((item) => item.ingredient.id).toSet();
});

/// Match percentage of a recipe from the checked (available) ingredient ids:
/// checking more ingredients raises it, unchecking one lowers it.
double recipeMatchPercentage(Recipe recipe, Set<String> checkedIngredientIds) {
  if (recipe.ingredients.isEmpty) return 0;
  final available = recipe.ingredients
      .where((item) => checkedIngredientIds.contains(item.ingredient.id))
      .length;
  return available / recipe.ingredients.length * 100;
}

/// Formats an ingredient quantity scaled to the selected servings.
String scaledQuantity(
  double quantity,
  String unit,
  int servings,
  int baseServings,
) {
  final scaled = quantity * servings / baseServings;
  final clean = scaled % 1 == 0
      ? scaled.toInt().toString()
      : scaled.toStringAsFixed(1);
  return unit.isEmpty ? clean : '$clean $unit';
}
