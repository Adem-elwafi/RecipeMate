import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipemate/core/data/mock_data.dart';
import 'package:recipemate/features/fridge/providers/fridge_provider.dart';
import 'package:recipemate/features/recommendations/models/recipe_match_result.dart';
import 'package:recipemate/features/recommendations/services/gemini_recipe_service.dart';
import 'package:recipemate/features/recommendations/services/matching_service.dart';

/// Provides the pure-Dart recipe matching & ranking service.
final matchingServiceProvider = Provider<MatchingService>(
  (ref) => const MatchingService(),
);

/// Provides the Gemini anti-waste recipe idea generator and disposes its client.
final geminiRecipeServiceProvider = Provider<GeminiRecipeService>((ref) {
  final service = GeminiRecipeService();
  ref.onDispose(service.dispose);
  return service;
});

/// Active sorting criterion selected on the Recettes IA screen.
final recommendationSortProvider = StateProvider<RecommendationSort>(
  (ref) => RecommendationSort.match,
);

/// Ranked recipe recommendations computed reactively from the user's fridge.
final recommendationsProvider = Provider<List<RecipeMatchResult>>((ref) {
  final fridgeState = ref.watch(fridgeProvider);
  final sort = ref.watch(recommendationSortProvider);
  final matchingService = ref.watch(matchingServiceProvider);

  return matchingService.rankRecipes(
    recipes: MockData.recipes,
    fridgeItems: fridgeState.items,
    userProfile: MockData.defaultUser,
    sort: sort,
  );
});

/// Count of recipes with at least 50% ingredient match.
final possibleRecipesCountProvider = Provider<int>(
  (ref) => ref
      .watch(matchingServiceProvider)
      .countPossibleRecipes(ref.watch(recommendationsProvider)),
);
