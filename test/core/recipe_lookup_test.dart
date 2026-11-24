import 'package:flutter_test/flutter_test.dart';
import 'package:recipemate/core/data/mock_data.dart';
import 'package:recipemate/core/models/recipe.dart';
import 'package:recipemate/core/utils/recipe_lookup.dart';

void main() {
  test('all rassemble le catalogue et les recettes de l’utilisateur', () {
    final own = <Recipe>[
      MockData.recipes.first.copyWith(id: 'own_recipe', title: 'Ma recette'),
    ];

    final all = RecipeLookup.all(own);

    expect(all.length, MockData.recipes.length + 1);
    expect(all.last.id, 'own_recipe');
  });

  test('find retrouve une recette du catalogue ou une recette personnelle', () {
    final own = <Recipe>[
      MockData.recipes.first.copyWith(id: 'own_recipe', title: 'Ma recette'),
    ];

    expect(RecipeLookup.find('own_recipe', own)?.title, 'Ma recette');
    expect(RecipeLookup.find(MockData.recipes.first.id, own), isNotNull);
    expect(RecipeLookup.find('inconnu', own), isNull);
  });
}
