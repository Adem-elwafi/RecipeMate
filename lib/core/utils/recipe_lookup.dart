import 'package:recipemate/core/data/mock_data.dart';
import 'package:recipemate/core/models/recipe.dart';

/// Utilitaire partagé par les favoris et les collections.
///
/// Une recette peut venir du catalogue fictif de l'équipe, des recettes
/// Firestore de l'utilisateur, ou d'un document partagé `recipes/{id}` : on
/// fusionne les trois sources en donnant la priorité aux données Firestore.
abstract final class RecipeLookup {
  static List<Recipe> all(
    List<Recipe> userRecipes, [
    List<Recipe> sharedRecipes = const <Recipe>[],
  ]) {
    final byId = <String, Recipe>{};
    for (final recipe in MockData.recipes) {
      byId.putIfAbsent(recipe.id, () => recipe);
    }
    for (final recipe in sharedRecipes) {
      byId[recipe.id] = recipe;
    }
    for (final recipe in userRecipes) {
      byId[recipe.id] = recipe;
    }
    return byId.values.toList(growable: false);
  }

  static Recipe? find(
    String id,
    List<Recipe> userRecipes, [
    List<Recipe> sharedRecipes = const <Recipe>[],
  ]) {
    for (final recipe in all(userRecipes, sharedRecipes)) {
      if (recipe.id == id) {
        return recipe;
      }
    }
    return null;
  }
}
