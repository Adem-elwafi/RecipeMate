import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipemate/core/data/recipe_api.dart';
import 'package:recipemate/core/models/difficulty.dart';
import 'package:recipemate/core/models/recipe.dart';

/// Sorting options available on the explore screen.
enum RecipeSortOption { relevance, popularity, prepTime, calories }

/// Immutable state holding every search, filter and sort choice.
class ExploreState {
  const ExploreState({
    this.query = '',
    this.category,
    this.selectedDiets = const <String>{},
    this.maxPrepMinutes,
    this.maxCalories = 1000,
    this.difficulty,
    this.sort = RecipeSortOption.relevance,
    this.recentSearches = const <String>[
      'Poulet',
      'Salade',
      'Pâtes',
    ],
  });

  final String query;
  final String? category;
  final Set<String> selectedDiets;
  final int? maxPrepMinutes;
  final int maxCalories;
  final Difficulty? difficulty;
  final RecipeSortOption sort;
  final List<String> recentSearches;

  ExploreState copyWith({
    String? query,
    String? category,
    Set<String>? selectedDiets,
    int? maxPrepMinutes,
    int? maxCalories,
    Difficulty? difficulty,
    RecipeSortOption? sort,
    List<String>? recentSearches,
    bool clearCategory = false,
    bool clearMaxPrepMinutes = false,
    bool clearDifficulty = false,
  }) {
    return ExploreState(
      query: query ?? this.query,
      category: clearCategory ? null : (category ?? this.category),
      selectedDiets: selectedDiets ?? this.selectedDiets,
      maxPrepMinutes: clearMaxPrepMinutes
          ? null
          : (maxPrepMinutes ?? this.maxPrepMinutes),
      maxCalories: maxCalories ?? this.maxCalories,
      difficulty: clearDifficulty ? null : (difficulty ?? this.difficulty),
      sort: sort ?? this.sort,
      recentSearches: recentSearches ?? this.recentSearches,
    );
  }
}

/// Riverpod controller for the explore screen state.
class ExploreController extends Notifier<ExploreState> {
  @override
  ExploreState build() => const ExploreState();

  void setQuery(String query) => state = state.copyWith(query: query);

  void clearQuery() => state = state.copyWith(query: '');

  void setCategory(String? category) {
    state = category == null
        ? state.copyWith(clearCategory: true)
        : state.copyWith(category: category);
  }

  void toggleDiet(String diet) {
    final diets = Set<String>.from(state.selectedDiets);
    if (!diets.remove(diet)) {
      diets.add(diet);
    }
    state = state.copyWith(selectedDiets: diets);
  }

  void setMaxPrepMinutes(int? minutes) {
    state = minutes == null
        ? state.copyWith(clearMaxPrepMinutes: true)
        : state.copyWith(maxPrepMinutes: minutes);
  }

  void setMaxCalories(int calories) =>
      state = state.copyWith(maxCalories: calories);

  void setDifficulty(Difficulty? difficulty) {
    state = difficulty == null
        ? state.copyWith(clearDifficulty: true)
        : state.copyWith(difficulty: difficulty);
  }

  void setSort(RecipeSortOption sort) => state = state.copyWith(sort: sort);

  void rememberSearch(String term) {
    final clean = term.trim();
    if (clean.isEmpty) return;
    final searches = <String>{clean, ...state.recentSearches}.toList()..sort();
    state = state.copyWith(recentSearches: searches.take(5).toList());
  }

  void removeRecentSearch(String term) {
    state = state.copyWith(
      recentSearches: state.recentSearches
          .where((item) => item != term)
          .toList(),
    );
  }

  void clearRecentSearches() =>
      state = state.copyWith(recentSearches: const <String>[]);

  void reset() => state = const ExploreState();
}

final exploreControllerProvider =
    NotifierProvider<ExploreController, ExploreState>(ExploreController.new);

/// The search API client of the explorer.
final recipeApiProvider = Provider<RecipeApi>((ref) => const RecipeApi());

/// Recipes fetched from TheMealDB API for the current search query.
///
/// Returns an empty list when no query is typed by the user.
final searchRecipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final query = ref.watch(exploreControllerProvider).query.trim();
  if (query.isEmpty) return const <Recipe>[];
  final api = ref.watch(recipeApiProvider);
  return api.searchRecipes(query);
});

/// A single search suggestion shown under the search field.
class SearchSuggestion {
  const SearchSuggestion({
    required this.label,
    required this.type,
    this.recipeId,
  });

  final String label;
  final String type;
  final String? recipeId;
}

/// Recipes matching the current query and filters from the API, already sorted.
final filteredRecipesProvider = Provider<List<Recipe>>((ref) {
  final filters = ref.watch(exploreControllerProvider);
  final query = _normalize(filters.query.trim());
  if (query.isEmpty) return const <Recipe>[];

  final asyncResults = ref.watch(searchRecipesProvider);
  final apiRecipes = asyncResults.value ?? const <Recipe>[];
  if (apiRecipes.isEmpty) return const <Recipe>[];

  final recipes = apiRecipes.where((recipe) {
    final matchesQuery =
        query.isEmpty ||
        _normalize(recipe.title).contains(query) ||
        _normalize(recipe.description).contains(query) ||
        recipe.ingredients.any(
          (item) => _normalize(item.ingredient.name).contains(query),
        ) ||
        recipe.dietBadges.any((badge) => _normalize(badge).contains(query));
    if (!matchesQuery) return false;

    final category = filters.category;
    if (category != null &&
        category.isNotEmpty &&
        !_hasBadge(recipe, category)) {
      return false;
    }
    for (final diet in filters.selectedDiets) {
      if (!_hasBadge(recipe, diet)) return false;
    }
    final maxPrep = filters.maxPrepMinutes;
    if (maxPrep != null && recipe.totalTimeMinutes > maxPrep) return false;
    if (recipe.calories > filters.maxCalories) return false;
    final difficulty = filters.difficulty;
    if (difficulty != null && recipe.difficulty != difficulty) return false;
    return true;
  }).toList();

  switch (filters.sort) {
    case RecipeSortOption.relevance:
      recipes.sort(
        (a, b) => (b.matchPercentage ?? 0).compareTo(a.matchPercentage ?? 0),
      );
    case RecipeSortOption.popularity:
      recipes.sort((a, b) => b.rating.compareTo(a.rating));
    case RecipeSortOption.prepTime:
      recipes.sort((a, b) => a.totalTimeMinutes.compareTo(b.totalTimeMinutes));
    case RecipeSortOption.calories:
      recipes.sort((a, b) => a.calories.compareTo(b.calories));
  }
  return recipes;
});

/// Suggestions built from current search API results.
final searchSuggestionsProvider = Provider<List<SearchSuggestion>>((ref) {
  final query = _normalize(ref.watch(exploreControllerProvider).query.trim());
  if (query.isEmpty) return const <SearchSuggestion>[];

  final asyncResults = ref.watch(searchRecipesProvider);
  final apiRecipes = asyncResults.value ?? const <Recipe>[];

  final suggestions = <SearchSuggestion>[];
  for (final recipe in apiRecipes) {
    if (_normalize(recipe.title).contains(query)) {
      suggestions.add(
        SearchSuggestion(
          label: recipe.title,
          type: 'Recette',
          recipeId: recipe.id,
        ),
      );
    }
  }
  return suggestions.take(6).toList();
});

bool _hasBadge(Recipe recipe, String badge) =>
    recipe.dietBadges.any((value) => _normalize(value) == _normalize(badge));

String _normalize(String value) {
  const accents = <String, String>{
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'ô': 'o',
    'ö': 'o',
    'ù': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
  };
  var result = value.toLowerCase();
  for (final entry in accents.entries) {
    result = result.replaceAll(entry.key, entry.value);
  }
  return result;
}
