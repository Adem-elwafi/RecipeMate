import 'package:flutter_test/flutter_test.dart';
import 'package:recipemate/features/add_recipe/utils/recipe_validators.dart';

void main() {
  group('RecipeValidators', () {
    test('champ obligatoire', () {
      expect(RecipeValidators.required('  ', 'Le nom'), isNotNull);
      expect(RecipeValidators.required('Salade', 'Le nom'), isNull);
    });

    test('entier positif', () {
      expect(RecipeValidators.positiveInteger('0', 'Le temps'), isNotNull);
      expect(RecipeValidators.positiveInteger('-3', 'Le temps'), isNotNull);
      expect(RecipeValidators.positiveInteger('abc', 'Le temps'), isNotNull);
      expect(RecipeValidators.positiveInteger('25', 'Le temps'), isNull);
    });

    test('nombre positif avec virgule décimale', () {
      expect(RecipeValidators.positiveNumber('1,5', 'La quantité'), isNull);
      expect(RecipeValidators.positiveNumber('-1', 'La quantité'), isNotNull);
      expect(RecipeValidators.positiveNumber('', 'La quantité'), isNotNull);
    });

    test('nombre facultatif : vide accepté, valeur invalide refusée', () {
      expect(RecipeValidators.optionalPositiveNumber('', 'Les fibres'), isNull);
      expect(
        RecipeValidators.optionalPositiveNumber(null, 'Les fibres'),
        isNull,
      );
      expect(
        RecipeValidators.optionalPositiveNumber('4', 'Les fibres'),
        isNull,
      );
      expect(
        RecipeValidators.optionalPositiveNumber('0', 'Les fibres'),
        isNotNull,
      );
    });
  });
}
