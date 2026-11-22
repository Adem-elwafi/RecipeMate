import 'package:flutter_test/flutter_test.dart';
import 'package:recipemate/core/models/user_profile.dart';

void main() {
  UserProfile profile({
    String id = 'user_1',
    String name = 'Farah',
    String email = 'farah@exemple.com',
  }) {
    return UserProfile(id: id, name: name, email: email);
  }

  group('UserProfile', () {
    test('un nouveau profil est totalement vide (point 5)', () {
      final item = profile();

      expect(item.age, isNull);
      expect(item.weight, isNull);
      expect(item.height, isNull);
      expect(item.goal, isNull);
      expect(item.photoUrl, isNull);
      expect(item.bio, isEmpty);
      expect(item.diets, isEmpty);
      expect(item.allergies, isEmpty);
      expect(item.excludedIngredients, isEmpty);
      expect(item.calorieGoal, isNull);
      expect(item.proteinGoal, isNull);
      expect(item.carbsGoal, isNull);
      expect(item.fatGoal, isNull);
    });

    test('copyWith ne modifie que les champs fournis', () {
      final item = profile().copyWith(
        name: 'Farah B.',
        diets: const <String>['Végétarien'],
        calorieGoal: 1800,
      );

      expect(item.id, 'user_1');
      expect(item.email, 'farah@exemple.com');
      expect(item.name, 'Farah B.');
      expect(item.diets, <String>['Végétarien']);
      expect(item.calorieGoal, 1800);
      expect(item.proteinGoal, isNull);
    });

    test('l’identité est basée sur l’id', () {
      final a = profile(name: 'A');
      final b = profile(name: 'B');
      final c = profile(id: 'user_2');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
    });
  });
}
