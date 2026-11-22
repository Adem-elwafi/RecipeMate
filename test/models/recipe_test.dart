import 'package:flutter_test/flutter_test.dart';
import 'package:recipemate/core/data/mock_data.dart';
import 'package:recipemate/core/models/ingredient.dart';
import 'package:recipemate/core/models/recipe.dart';

void main() {
  group('Recipe Model Tests', () {
    test('Calculates totalTimeMinutes correctly', () {
      const recipe = Recipe(
        id: 'rec_test',
        title: 'Test Recipe',
        description: 'Test description',
        imageUrl: 'https://example.com/image.jpg',
        prepTimeMinutes: 15,
        cookTimeMinutes: 25,
        calories: 350,
        proteinGrams: 20,
        carbsGrams: 30,
        fatGrams: 10,
        ingredients: [],
        instructions: ['Step 1'],
      );

      expect(recipe.totalTimeMinutes, equals(40));
      expect(recipe.formattedTotalTime, equals('40 min'));
    });

    test('Formats total time greater than 60 minutes properly', () {
      const recipe = Recipe(
        id: 'rec_test_long',
        title: 'Long Recipe',
        description: 'Long description',
        imageUrl: 'https://example.com/image.jpg',
        prepTimeMinutes: 30,
        cookTimeMinutes: 60,
        calories: 600,
        proteinGrams: 35,
        carbsGrams: 60,
        fatGrams: 22,
        ingredients: [],
        instructions: ['Step 1'],
      );

      expect(recipe.totalTimeMinutes, equals(90));
      expect(recipe.formattedTotalTime, equals('1h 30min'));
    });

    test('Recipe copyWith works as expected', () {
      final original = MockData.recipes.first;
      final updated = original.copyWith(
        title: 'Titre Modifié',
        isFavorite: false,
      );

      expect(updated.id, equals(original.id));
      expect(updated.title, equals('Titre Modifié'));
      expect(updated.isFavorite, isFalse);
      expect(updated.calories, equals(original.calories));
    });

    test('les métadonnées E11 (catégorie, difficulté, régimes, fibres)', () {
      const recipe = Recipe(
        id: 'rec_e11',
        title: 'Salade',
        description: 'Description',
        imageUrl: '',
        prepTimeMinutes: 10,
        cookTimeMinutes: 0,
        calories: 120,
        proteinGrams: 5,
        carbsGrams: 12,
        fatGrams: 3,
        fiberGrams: 4,
        category: 'Entrées',
        difficulty: 'Moyen',
        dietTags: <String>['Vegan', 'Sans gluten'],
        ingredients: [],
        instructions: ['Mélanger'],
      );

      expect(recipe.category, equals('Entrées'));
      expect(recipe.difficulty, equals('Moyen'));
      expect(recipe.dietTags, equals(<String>['Vegan', 'Sans gluten']));
      expect(recipe.fiberGrams, equals(4));

      final updated = recipe.copyWith(difficulty: 'Facile');
      expect(updated.difficulty, equals('Facile'));
      expect(updated.category, equals('Entrées'));
      expect(updated.fiberGrams, equals(4));
    });

    test('RecipeIngredient displayText format', () {
      const ingredient = Ingredient(
        id: 'ing_oil',
        name: "Huile d'olive",
        category: IngredientCategory.spices,
      );

      const ri1 = RecipeIngredient(
        ingredient: ingredient,
        quantity: 2,
        unit: 'c. à soupe',
      );
      expect(ri1.displayText, equals("2 c. à soupe Huile d'olive"));

      const ri2 = RecipeIngredient(
        ingredient: ingredient,
        quantity: 1,
        unit: '',
      );
      expect(ri2.displayText, equals("1 Huile d'olive"));
    });
  });
}
