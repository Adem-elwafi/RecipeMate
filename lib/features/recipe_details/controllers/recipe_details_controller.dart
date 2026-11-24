import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipemate/features/recipe_details/recipe_lookup.dart';

/// State of a recipe detail sheet: servings, checked ingredients and favorite.
class RecipeDetailsState {
  const RecipeDetailsState({
    required this.servings,
    required this.checkedIngredientIds,
    this.isFavorite = false,
  });

  final int servings;
  final Set<String> checkedIngredientIds;
  final bool isFavorite;

  RecipeDetailsState copyWith({
    int? servings,
    Set<String>? checkedIngredientIds,
    bool? isFavorite,
  }) => RecipeDetailsState(
    servings: servings ?? this.servings,
    checkedIngredientIds: checkedIngredientIds ?? this.checkedIngredientIds,
    isFavorite: isFavorite ?? this.isFavorite,
  );
}

/// Per-recipe controller created on demand for each detail screen.
class RecipeDetailsController
    extends FamilyNotifier<RecipeDetailsState, String> {
  @override
  RecipeDetailsState build(String recipeId) {
    final fridgeIds = ref.watch(fridgeIngredientIdsProvider);
    final recipe = findRecipeById(recipeId);
    return RecipeDetailsState(
      servings: recipe.servings,
      checkedIngredientIds: recipe.ingredients
          .map((item) => item.ingredient.id)
          .where(fridgeIds.contains)
          .toSet(),
      isFavorite: recipe.isFavorite,
    );
  }

  void changeServings(int delta) {
    final next = state.servings + delta;
    if (next < 1 || next > 12) return;
    state = state.copyWith(servings: next);
  }

  void toggleIngredient(String ingredientId) {
    final checked = Set<String>.from(state.checkedIngredientIds);
    if (!checked.remove(ingredientId)) {
      checked.add(ingredientId);
    }
    state = state.copyWith(checkedIngredientIds: checked);
  }

  void toggleFavorite() =>
      state = state.copyWith(isFavorite: !state.isFavorite);
}

final recipeDetailsControllerProvider =
    NotifierProvider.family<
      RecipeDetailsController,
      RecipeDetailsState,
      String
    >(RecipeDetailsController.new);
