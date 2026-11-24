import 'package:flutter_test/flutter_test.dart';
import 'package:recipemate/core/models/ingredient.dart';
import 'package:recipemate/core/utils/recipe_keywords.dart';

void main() {
  group('RecipeKeywords', () {
    test('normalise la casse, les accents et les espaces', () {
      expect(RecipeKeywords.normalize('Épinards  FRAIS'), 'epinards frais');
      expect(RecipeKeywords.normalize('  Œufs  '), 'oeufs');
    });

    test('construit les mots-clés d’une recette à partir des ingrédients', () {
      final keywords = RecipeKeywords.fromIngredients(<RecipeIngredient>[
        const RecipeIngredient(
          ingredient: Ingredient(
            id: 'tomate',
            name: 'Tomates cerises',
            category: IngredientCategory.vegetables,
          ),
          quantity: 200,
          unit: 'g',
        ),
        const RecipeIngredient(
          ingredient: Ingredient(
            id: 'ail',
            name: 'Ail',
            category: IngredientCategory.vegetables,
          ),
          quantity: 2,
          unit: 'gousse(s)',
        ),
      ]);

      expect(keywords, contains('tomates cerises'));
      expect(keywords, contains('tomates'));
      expect(keywords, contains('cerises'));
      expect(keywords, contains('ail'));
    });

    test('ignore les ingrédients vides et les noms absents', () {
      expect(
        RecipeKeywords.fromNames(<Object?>['Épinards', '', null]),
        <String>['epinards'],
      );
    });

    test('retourne une liste triée sans doublon', () {
      final keywords = RecipeKeywords.fromNames(<Object?>[
        'Lait',
        'lait',
        'Arachides',
      ]);
      expect(keywords, <String>['arachides', 'lait']);
    });
  });
}
