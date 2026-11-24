import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipemate/core/data/mock_data.dart';
import 'package:recipemate/core/data/recipe_api.dart';
import 'package:recipemate/core/models/difficulty.dart';
import 'package:recipemate/core/models/recipe.dart';
import 'package:recipemate/features/cooking_mode/controllers/cooking_controller.dart';
import 'package:recipemate/features/cooking_mode/step_durations.dart';
import 'package:recipemate/features/explore/controllers/explore_controller.dart';
import 'package:recipemate/features/recipe_details/controllers/recipe_details_controller.dart';

class _FakeRecipeApi extends RecipeApi {
  const _FakeRecipeApi();

  @override
  Future<List<Recipe>> searchRecipes(String query) async => MockData.recipes;
}

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        recipeApiProvider.overrideWithValue(const _FakeRecipeApi()),
      ],
    );
  });
  tearDown(() => container.dispose());

  group('ExploreController', () {
    test('filters recipes by a normalised French query when search is active', () async {
      expect(container.read(filteredRecipesProvider), isEmpty);

      container.read(exploreControllerProvider.notifier).setQuery('poulet');
      await container.read(searchRecipesProvider.future);
      expect(container.read(filteredRecipesProvider).length, 1);

      container.read(exploreControllerProvider.notifier).setQuery('vegetarien');
      await container.read(searchRecipesProvider.future);
      expect(container.read(filteredRecipesProvider).length, 3);
    });

    test('returns an empty list for contradictory diets', () async {
      container.read(exploreControllerProvider.notifier).setQuery('a');
      await container.read(searchRecipesProvider.future);

      final controller = container.read(exploreControllerProvider.notifier)
        ..toggleDiet('Vegan')
        ..toggleDiet('Keto');
      expect(container.read(filteredRecipesProvider), isEmpty);

      controller.reset();
      expect(container.read(filteredRecipesProvider), isEmpty);
    });

    test('filters recipes by difficulty', () async {
      container.read(exploreControllerProvider.notifier).setQuery('a');
      await container.read(searchRecipesProvider.future);

      final controller = container.read(exploreControllerProvider.notifier)
        ..setDifficulty(Difficulty.medium);
      expect(container.read(filteredRecipesProvider).length, 2);

      controller.setDifficulty(Difficulty.easy);
      expect(container.read(filteredRecipesProvider).length, 3);

      // The "Tous" chip clears the filter.
      controller.setDifficulty(null);
      expect(container.read(filteredRecipesProvider).length, 5);
    });

    test('reset clears the difficulty filter', () {
      final controller = container.read(exploreControllerProvider.notifier)
        ..setDifficulty(Difficulty.hard);
      expect(container.read(exploreControllerProvider).difficulty, isNotNull);

      controller.reset();
      expect(container.read(exploreControllerProvider).difficulty, isNull);
    });
  });

  group('RecipeDetailsController', () {
    test('scales servings and toggles the favorite flag', () {
      final controller = container.read(
        recipeDetailsControllerProvider('rec_1').notifier,
      );
      final initial = container.read(recipeDetailsControllerProvider('rec_1'));

      expect(initial.servings, 2);
      controller.changeServings(1);
      expect(
        container.read(recipeDetailsControllerProvider('rec_1')).servings,
        3,
      );
      controller.toggleFavorite();
      expect(
        container.read(recipeDetailsControllerProvider('rec_1')).isFavorite,
        isFalse,
      );
    });
  });

  group('CookingController', () {
    test('advances through steps and finishes the flow', () {
      final controller = container.read(
        cookingControllerProvider('rec_1').notifier,
      );
      final state = container.read(cookingControllerProvider('rec_1'));

      expect(state.totalSteps, 5);
      expect(state.hasTimer, isTrue);
      expect(state.remainingSeconds, greaterThan(0));

      controller.nextStep();
      expect(container.read(cookingControllerProvider('rec_1')).currentStep, 1);

      for (var i = 0; i < 4; i++) {
        controller.nextStep();
      }
      expect(
        container.read(cookingControllerProvider('rec_1')).isCompleted,
        isTrue,
      );

      controller.restart();
      expect(container.read(cookingControllerProvider('rec_1')).currentStep, 0);
    });

    test('formats timer values in French style', () {
      expect(formatTimer(720), '12:00');
      expect(formatTimer(65), '01:05');
      expect(stepTitle('Mariner le poulet, 10 min'), 'Mariner le poulet');
    });
  });
}
