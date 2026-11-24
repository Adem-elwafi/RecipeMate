import 'package:flutter_test/flutter_test.dart';
import 'package:recipemate/core/data/mock_data.dart';
import 'package:recipemate/features/recipe_details/recipe_lookup.dart';

void main() {
  test('match percentage grows when more ingredients are checked', () {
    final recipe = MockData.recipes.first; // 5 ingredients
    expect(recipeMatchPercentage(recipe, <String>{}), 0);

    final firstTwo = recipe.ingredients
        .take(2)
        .map((item) => item.ingredient.id)
        .toSet();
    expect(recipeMatchPercentage(recipe, firstTwo), 40);

    expect(
      recipeMatchPercentage(
        recipe,
        recipe.ingredients.map((item) => item.ingredient.id).toSet(),
      ),
      100,
    );
  });

  test('match percentage falls when an ingredient is unchecked', () {
    final recipe = MockData.recipes.first;
    final all = recipe.ingredients.map((item) => item.ingredient.id).toSet();
    expect(recipeMatchPercentage(recipe, all), 100);

    final withoutOne = Set<String>.from(all)
      ..remove(recipe.ingredients.first.ingredient.id);
    expect(recipeMatchPercentage(recipe, withoutOne), 80);
  });

  test('match percentage is 0 for recipes without ingredients', () {
    final recipe = MockData.recipes.first;
    final without = recipe.copyWith(ingredients: []);
    expect(recipeMatchPercentage(without, {'x'}), 0);
  });
}
