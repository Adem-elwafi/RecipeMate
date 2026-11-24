import 'package:flutter_test/flutter_test.dart';
import 'package:recipemate/core/models/ingredient.dart';

void main() {
  Ingredient ingredient({String id = 'tomate', String name = 'Tomate'}) {
    return Ingredient(
      id: id,
      name: name,
      category: IngredientCategory.vegetables,
    );
  }

  group('Ingredient', () {
    test(
      'l’unité par défaut est le gramme et les libellés sont en français',
      () {
        final item = ingredient();

        expect(item.defaultUnit, 'g');
        expect(item.imageUrl, isNull);
        expect(item.category.label, 'Légumes');
        expect(IngredientCategory.other.label, 'Autre');
      },
    );

    test('l’identité est basée sur l’id', () {
      expect(ingredient(), ingredient(name: 'Ignoré'));
      expect(ingredient(id: 'pomme') == ingredient(), isFalse);
    });
  });

  group('RecipeIngredient', () {
    RecipeIngredient recipeIngredient({
      double quantity = 2,
      String unit = 'g',
    }) {
      return RecipeIngredient(
        ingredient: ingredient(),
        quantity: quantity,
        unit: unit,
        notes: 'Bien mûre',
      );
    }

    test('displayText formate les quantités entières et décimales', () {
      expect(recipeIngredient().displayText, '2 g Tomate');
      expect(recipeIngredient(quantity: 1.5).displayText, '1.5 g Tomate');
    });

    test('displayText ignore une unité vide', () {
      expect(recipeIngredient(unit: '').displayText, '2 Tomate');
    });

    test('les notes sont conservées', () {
      expect(recipeIngredient().notes, 'Bien mûre');
    });
  });
}
