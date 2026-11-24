import 'package:flutter_test/flutter_test.dart';
import 'package:recipemate/core/models/daily_nutrition.dart';

void main() {
  group('DailyNutrition', () {
    test('starts at zero by default', () {
      const nutrition = DailyNutrition();
      expect(nutrition.calories, 0);
      expect(nutrition.proteinGrams, 0);
      expect(nutrition.carbsGrams, 0);
      expect(nutrition.fatGrams, 0);
      expect(nutrition.completedRecipes, 0);
    });

    test('copyWith only overrides given values', () {
      const nutrition = DailyNutrition(
        calories: 420,
        proteinGrams: 34,
        carbsGrams: 12,
        fatGrams: 26,
      );
      final updated = nutrition.copyWith(calories: 450);
      expect(updated.calories, 450);
      expect(updated.proteinGrams, 34);
      expect(updated.carbsGrams, 12);
      expect(updated.fatGrams, 26);
      expect(updated.completedRecipes, 0);
    });

    test('value equality', () {
      const a = DailyNutrition(calories: 100, proteinGrams: 4.5);
      const b = DailyNutrition(calories: 100, proteinGrams: 4.5);
      const c = DailyNutrition(calories: 101);
      expect(a, b);
      expect(a == c, isFalse);
    });
  });
}
