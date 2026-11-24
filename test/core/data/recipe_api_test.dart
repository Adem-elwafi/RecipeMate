import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:recipemate/core/data/recipe_api.dart';

void main() {
  group('RecipeApi', () {
    test('maps the API response to recipes', () async {
      final api = RecipeApi(client: _FakeClient(statusCode: 200));
      final recipes = await api.searchRecipes('Salade');

      expect(recipes.length, 1);
      final recipe = recipes.single;
      expect(recipe.title, 'Salade grecque au poulet');
      expect(recipe.calories, 420);
      expect(recipe.ingredients.length, 2);
      expect(recipe.ingredients.first.quantity, 200);
      expect(recipe.instructions.length, 2);
    });

    test('throws RecipeApiException on non-200 status', () async {
      final api = RecipeApi(client: _FakeClient(statusCode: 500));

      await expectLater(
        api.searchRecipes('Salade'),
        throwsA(isA<RecipeApiException>()),
      );
    });
  });
}

/// Fake HTTP client returning a canned recipe search response.
class _FakeClient extends http.BaseClient {
  _FakeClient({required this.statusCode});

  final int statusCode;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final body = statusCode == 200
        ? jsonEncode({
            'recipes': [
              {
                'id': 'rec_api_1',
                'title': 'Salade grecque au poulet',
                'prepTimeMinutes': 15,
                'cookTimeMinutes': 10,
                'calories': 420,
                'proteinGrams': 34,
                'ingredients': [
                  {
                    'ingredientId': 'ing_chicken',
                    'quantity': 200,
                    'unit': 'g',
                  },
                  {
                    'ingredientId': 'ing_feta',
                    'quantity': 80,
                    'unit': 'g',
                  },
                ],
                'instructions': ['Couper le poulet.', 'Faire dorer.'],
              },
            ],
          })
        : 'erreur';
    return http.StreamedResponse(
      Stream.value(utf8.encode(body)),
      statusCode,
    );
  }
}
