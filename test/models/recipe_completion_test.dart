import 'package:flutter_test/flutter_test.dart';
import 'package:recipemate/core/models/recipe_completion.dart';

void main() {
  group('RecipeCompletion', () {
    test('copyWith only overrides given values', () {
      final completion = RecipeCompletion(
        recipeId: 'rec_1',
        recipeTitle: 'Salade grecque au poulet',
        completedAt: DateTime(2026, 11, 16, 10, 30),
      );
      final updated = completion.copyWith(recipeId: 'rec_5');
      expect(updated.recipeId, 'rec_5');
      expect(updated.recipeTitle, 'Salade grecque au poulet');
      expect(updated.completedAt, completion.completedAt);
    });

    test('value equality', () {
      final at = DateTime(2026, 11, 16, 10, 30);
      final a = RecipeCompletion(
        recipeId: 'rec_1',
        recipeTitle: 'T',
        completedAt: at,
      );
      final b = RecipeCompletion(
        recipeId: 'rec_1',
        recipeTitle: 'T',
        completedAt: at,
      );
      final c = RecipeCompletion(
        recipeId: 'rec_2',
        recipeTitle: 'T',
        completedAt: at,
      );
      expect(a, b);
      expect(a == c, isFalse);
    });
  });
}
