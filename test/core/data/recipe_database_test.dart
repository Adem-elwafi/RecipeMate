import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipemate/core/data/mock_data.dart';
import 'package:recipemate/core/data/recipe_database.dart';
import 'package:recipemate/core/models/recipe.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  RecipeDatabaseController db() =>
      container.read(recipeDatabaseProvider.notifier);

  Recipe recipe(String id) => MockData.recipes.firstWhere((r) => r.id == id);

  group('RecipeDatabaseController', () {
    test('fridge is seeded from the mock stock', () {
      final fridge = container.read(recipeDatabaseProvider).fridgeItems;
      expect(fridge.length, MockData.initialFridgeItems.length);
      expect(fridge, isNotEmpty);
    });

    test('fridgeItem returns null for unknown ingredients', () {
      expect(db().fridgeItem('does_not_exist'), isNull);
    });

    test('finishing a recipe deducts ingredients from the fridge', () {
      // The fridge holds 6 eggs (MockData initialFridgeItems), the omelette
      // needs 3 of them: 3 eggs must remain.
      expect(db().fridgeItem('ing_eggs')?.quantity, 6);

      db().recordRecipeCompletion(recipe('rec_5'));

      expect(db().fridgeItem('ing_eggs')?.quantity, 3);
    });

    test('a fridge item is removed when nothing is left', () {
      final eggs = db().fridgeItem('ing_eggs');
      expect(eggs, isNotNull);

      // Finish the recipe twice with a small quantity tweak: the fridge
      // must lose the eggs instead of going negative.
      db().consumeIngredient('ing_eggs', quantity: eggs!.quantity);
      db().consumeIngredient('ing_eggs', quantity: eggs.quantity);

      expect(db().fridgeItem('ing_eggs'), isNull);
    });

    test('finishing a recipe adds the nutrition to today totals', () {
      final omelette = recipe('rec_5');

      db().recordRecipeCompletion(omelette);

      final today = container.read(recipeDatabaseProvider).today;
      expect(today.calories, omelette.calories);
      expect(today.proteinGrams, omelette.proteinGrams);
      expect(today.carbsGrams, omelette.carbsGrams);
      expect(today.fatGrams, omelette.fatGrams);
      expect(today.completedRecipes, 1);
    });

    test('finishing two recipes accumulates the nutrition', () {
      final omelette = recipe('rec_5');

      db()
        ..recordRecipeCompletion(omelette)
        ..recordRecipeCompletion(recipe('rec_3'));

      final today = container.read(recipeDatabaseProvider).today;
      expect(
        today.calories,
        closeTo(omelette.calories + recipe('rec_3').calories, 0.001),
      );
      expect(today.completedRecipes, 2);
    });

    test('records a completion per recipe', () {
      db().recordRecipeCompletion(recipe('rec_5'));

      expect(db().recipeCompletionCount('rec_5'), 1);
      expect(db().recipeCompletionCount('rec_1'), 0);
      expect(container.read(recipeDatabaseProvider).completions, hasLength(1));
    });

    test('recipes finished by several people are popular', () {
      db()
        ..recordRecipeCompletion(recipe('rec_5'))
        ..recordRecipeCompletion(recipe('rec_5'));

      final popular = container.read(popularRecipesProvider);
      expect(popular, contains(recipe('rec_5')));
      // Not popular yet at a single completion.
      db().recordRecipeCompletion(recipe('rec_5'));
      expect(container.read(recipeCompletionCountsProvider)['rec_5'], 3);
    });

    test('popular recipes are sorted by completion count', () {
      db()
        ..recordRecipeCompletion(recipe('rec_5'))
        ..recordRecipeCompletion(recipe('rec_5'))
        ..recordRecipeCompletion(recipe('rec_2'));

      final popular = container.read(popularRecipesProvider);
      expect(popular.first, recipe('rec_5'));
    });
  });
}
