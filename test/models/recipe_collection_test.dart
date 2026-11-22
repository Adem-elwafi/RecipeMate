import 'package:flutter_test/flutter_test.dart';
import 'package:recipemate/core/models/recipe_collection.dart';

void main() {
  final createdAt = DateTime(2026);

  RecipeCollection collection({
    String id = 'col_1',
    String name = 'Desserts',
    List<String> recipeIds = const <String>[],
  }) {
    return RecipeCollection(
      id: id,
      name: name,
      recipeIds: recipeIds,
      createdAt: createdAt,
    );
  }

  group('RecipeCollection', () {
    test('fromMap lit les champs et gère les valeurs absentes', () {
      final parsed = RecipeCollection.fromMap('col_1', const <String, Object?>{
        'name': 'Recettes du dimanche',
        'recipeIds': <String>['rec_1', 'rec_2'],
        'createdAt': '2026-01-15T10:30:00.000',
      });

      expect(parsed.id, 'col_1');
      expect(parsed.name, 'Recettes du dimanche');
      expect(parsed.recipeIds, <String>['rec_1', 'rec_2']);
      expect(parsed.createdAt, DateTime.parse('2026-01-15T10:30:00.000'));

      final withoutData = RecipeCollection.fromMap(
        'col_2',
        const <String, Object?>{},
      );
      expect(withoutData.name, '');
      expect(withoutData.recipeIds, isEmpty);
    });

    test('toMap et copyWith conservent les données', () {
      final item = collection(recipeIds: const <String>['rec_3']);
      final renamed = item.copyWith(name: 'Gâteaux');

      expect(renamed.name, 'Gâteaux');
      expect(renamed.recipeIds, item.recipeIds);
      expect(renamed.id, item.id);

      final map = item.toMap();
      expect(map['name'], 'Desserts');
      expect(map['recipeIds'], <String>['rec_3']);
      expect(map['createdAt'], createdAt.toIso8601String());
    });

    test('l’identité est basée sur l’id', () {
      final a = collection(name: 'A');
      final b = collection(name: 'B');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
