import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipemate/core/data/mock_data.dart';
import 'package:recipemate/core/models/daily_nutrition.dart';
import 'package:recipemate/core/models/fridge_item.dart';
import 'package:recipemate/core/models/recipe.dart';
import 'package:recipemate/core/models/recipe_completion.dart';

/// State of the recipes database: fridge stock, today's nutrition totals
/// and the record of finished recipes.
class RecipeDatabaseState {
  const RecipeDatabaseState({
    this.fridgeItems = const [],
    this.today = const DailyNutrition(),
    this.completions = const [],
  });

  final List<FridgeItem> fridgeItems;
  final DailyNutrition today;
  final List<RecipeCompletion> completions;

  RecipeDatabaseState copyWith({
    List<FridgeItem>? fridgeItems,
    DailyNutrition? today,
    List<RecipeCompletion>? completions,
  }) {
    return RecipeDatabaseState(
      fridgeItems: fridgeItems ?? this.fridgeItems,
      today: today ?? this.today,
      completions: completions ?? this.completions,
    );
  }
}

/// The RecipeMate database: fridge stock, today's nutrition totals and
/// recipe completion records.
///
/// Finishing a recipe (see `recordRecipeCompletion`) deducts the used
/// quantities from the fridge, adds the recipe nutrition to today's totals
/// and records a completion for the recipe's popularity.
class RecipeDatabaseController extends Notifier<RecipeDatabaseState> {
  @override
  RecipeDatabaseState build() => RecipeDatabaseState(
    fridgeItems: List<FridgeItem>.of(MockData.initialFridgeItems),
  );

  /// The fridge item of an ingredient, if any.
  FridgeItem? fridgeItem(String ingredientId) {
    return state.fridgeItems
        .where((item) => item.ingredient.id == ingredientId)
        .firstOrNull;
  }

  /// Deducts `quantity` of an ingredient from the fridge stock.
  /// The item is removed when nothing is left.
  void consumeIngredient(String ingredientId, {double quantity = 1}) {
    final items = List<FridgeItem>.of(state.fridgeItems);
    final index = items.indexWhere(
      (item) => item.ingredient.id == ingredientId,
    );
    if (index == -1) return;

    final item = items[index];
    final remaining = item.quantity - quantity;
    if (remaining <= 0) {
      items.removeAt(index);
    } else {
      items[index] = item.copyWith(quantity: remaining);
    }
    state = state.copyWith(fridgeItems: items);
  }

  /// Adds nutrition to today's totals, e.g. after finishing a recipe.
  void addDailyNutrition({
    double calories = 0,
    double proteinGrams = 0,
    double carbsGrams = 0,
    double fatGrams = 0,
  }) {
    final today = state.today;
    state = state.copyWith(
      today: today.copyWith(
        calories: today.calories + calories,
        proteinGrams: today.proteinGrams + proteinGrams,
        carbsGrams: today.carbsGrams + carbsGrams,
        fatGrams: today.fatGrams + fatGrams,
      ),
    );
  }

  /// Marks a recipe as finished:
  /// - deducts the used ingredients from the fridge (2 eggs used out of 5
  ///   in the fridge leaves 3),
  /// - adds the recipe nutrition (per portion, scaled to servings) to the
  ///   day's totals,
  /// - records the completion for the recipe's popularity.
  void recordRecipeCompletion(Recipe recipe, {int? servings}) {
    final usedServings = servings ?? recipe.servings;
    final baseServings = recipe.servings == 0 ? 1 : recipe.servings;

    for (final ingredient in recipe.ingredients) {
      consumeIngredient(
        ingredient.ingredient.id,
        quantity: ingredient.quantity * usedServings / baseServings,
      );
    }

    addDailyNutrition(
      calories: recipe.calories.toDouble() * usedServings,
      proteinGrams: recipe.proteinGrams * usedServings,
      carbsGrams: recipe.carbsGrams * usedServings,
      fatGrams: recipe.fatGrams * usedServings,
    );

    state = state.copyWith(
      completions: [
        ...state.completions,
        RecipeCompletion(
          recipeId: recipe.id,
          recipeTitle: recipe.title,
          completedAt: DateTime.now(),
        ),
      ],
      today: state.today.copyWith(
        completedRecipes: state.today.completedRecipes + 1,
      ),
    );
  }

  /// Number of times a recipe has been finished.
  int recipeCompletionCount(String recipeId) {
    return state.completions
        .where((completion) => completion.recipeId == recipeId)
        .length;
  }
}

/// The database of the app.
final recipeDatabaseProvider =
    NotifierProvider<RecipeDatabaseController, RecipeDatabaseState>(
      RecipeDatabaseController.new,
    );

/// Number of completions a recipe needs to be shown in the popular section.
const kPopularCompletionThreshold = 2;

/// Number of times each recipe has been finished, by recipe id.
final recipeCompletionCountsProvider = Provider<Map<String, int>>((ref) {
  final completions = ref.watch(recipeDatabaseProvider).completions;
  final counts = <String, int>{};
  for (final completion in completions) {
    counts[completion.recipeId] = (counts[completion.recipeId] ?? 0) + 1;
  }
  return counts;
});

/// Popular recipes: recipes that have been initialized as finished by
/// several people, sorted by completion count (most popular first).
final popularRecipesProvider = Provider<List<Recipe>>((ref) {
  final counts = ref.watch(recipeCompletionCountsProvider);
  final popular =
      MockData.recipes
          .where(
            (recipe) => (counts[recipe.id] ?? 0) >= kPopularCompletionThreshold,
          )
          .toList()
        ..sort((a, b) => (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0));
  return popular;
});
