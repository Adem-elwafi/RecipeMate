import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recipemate/core/models/difficulty.dart';
import 'package:recipemate/core/models/recipe.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/core/theme/app_text_styles.dart';
import 'package:recipemate/features/explore/controllers/explore_controller.dart';

const dietFilters = <String>[
  'Végétarien',
  'Vegan',
  'Sans gluten',
  'Sans lactose',
  'Keto',
  'Riche en protéines',
];

const popularSearches = <String>[
  'Petit-déjeuner protéiné',
  'Recettes 15 min',
  'Couscous léger',
  'Batch cooking',
];

const sortLabels = <RecipeSortOption, String>{
  RecipeSortOption.relevance: 'Pertinence',
  RecipeSortOption.popularity: 'Popularité',
  RecipeSortOption.prepTime: 'Temps de préparation',
  RecipeSortOption.calories: 'Calories',
};

/// Search, filters, sorting and empty states. Owned by Molka.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _searchController = TextEditingController();
  bool _advancedOpen = false;
  int _servings = 2;

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(exploreControllerProvider).query;
    _searchController.addListener(() {
      final query = _searchController.text;
      if (ref.read(exploreControllerProvider).query != query) {
        ref.read(exploreControllerProvider.notifier).setQuery(query);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(exploreControllerProvider);
    final results = ref.watch(searchRecipesProvider);
    final suggestions = ref.watch(searchSuggestionsProvider);
    final controller = ref.read(exploreControllerProvider.notifier);
    final hasQuery = filters.query.trim().isNotEmpty;
    final recipes = ref.watch(filteredRecipesProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Explorer', style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            _searchField(context, controller),
            if (hasQuery && suggestions.isNotEmpty) ...[
              const SizedBox(height: 10),
              _suggestions(context, suggestions, controller),
            ],
            if (!hasQuery) ...[
              const SizedBox(height: 24),
              _recentSearches(filters.recentSearches, controller),
              const SizedBox(height: 20),
              _popularSearches(controller),
            ],
            if (filters.category != null) ...[
              const SizedBox(height: 20),
              _activeCategory(filters.category!, controller),
            ],
            const SizedBox(height: 22),
            _dietFilters(filters.selectedDiets, controller),
            const SizedBox(height: 18),
            _advancedFilters(context, filters, controller),
            const SizedBox(height: 20),
            if (hasQuery) ...[
              if (results.isLoading) ...[
                const SizedBox(height: 32),
                const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ] else if (results.hasError) ...[
                const SizedBox(height: 20),
                Text(
                  'Erreur de connexion à TheMealDB API.',
                  style: AppTextStyles.bodySecondary,
                ),
              ] else ...[
                _resultsHeader(context, recipes.length, filters.sort, controller),
                const SizedBox(height: 14),
                if (recipes.isEmpty)
                  _emptyState(context, filters.query, controller)
                else
                  _resultsGrid(context, recipes),
              ],
            ] else
              _searchPrompt(),
          ],
        ),
      ),
    );
  }

  Widget _searchPrompt() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        'Recherchez une recette par son nom ou par un ingrédient pour afficher les résultats.',
        style: AppTextStyles.bodySecondary,
      ),
    );
  }

  Widget _searchField(BuildContext context, ExploreController controller) {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      style: AppTextStyles.body,
      onSubmitted: (value) {
        controller.rememberSearch(value);
        FocusScope.of(context).unfocus();
      },
      decoration: InputDecoration(
        hintText: 'Rechercher une recette ou un ingrédient…',
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textMuted,
                ),
                onPressed: () {
                  _searchController.clear();
                  controller.clearQuery();
                  FocusScope.of(context).unfocus();
                },
              ),
      ),
    );
  }

  Widget _suggestions(
    BuildContext context,
    List<SearchSuggestion> suggestions,
    ExploreController controller,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final suggestion in suggestions)
            InkWell(
              onTap: () {
                controller.rememberSearch(suggestion.label);
                if (suggestion.recipeId != null) {
                  context.push('/recipe/${suggestion.recipeId}');
                } else {
                  _searchController.text = suggestion.label;
                  controller.setQuery(suggestion.label);
                  FocusScope.of(context).unfocus();
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      suggestion.type == 'Recette'
                          ? Icons.restaurant_menu_rounded
                          : Icons.grass_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        suggestion.label,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    Text(suggestion.type, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _recentSearches(List<String> searches, ExploreController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Recherches récentes', style: AppTextStyles.sectionHeader),
            const Spacer(),
            TextButton(
              onPressed: controller.clearRecentSearches,
              child: Text(
                'Effacer',
                style: AppTextStyles.captionMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final term in searches)
              Chip(
                label: Text(term, style: AppTextStyles.captionMedium),
                onDeleted: () => controller.removeRecentSearch(term),
                deleteIcon: const Icon(Icons.close_rounded, size: 16),
                backgroundColor: AppColors.card,
                side: const BorderSide(color: AppColors.borderSubtle),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ],
    );
  }

  Widget _popularSearches(ExploreController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recherches populaires', style: AppTextStyles.sectionHeader),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final term in popularSearches)
              ActionChip(
                avatar: const Icon(
                  Icons.trending_up_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                label: Text(term, style: AppTextStyles.caption),
                onPressed: () {
                  _searchController.text = term;
                  controller
                    ..setQuery(term)
                    ..rememberSearch(term);
                },
                backgroundColor: AppColors.card,
                side: const BorderSide(color: AppColors.borderSubtle),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ],
    );
  }

  Widget _activeCategory(String category, ExploreController controller) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        avatar: const Icon(Icons.label_outline_rounded, size: 16),
        label: Text(category, style: AppTextStyles.captionMedium),
        onDeleted: () => controller.setCategory(null),
        backgroundColor: AppColors.softGreen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _dietFilters(Set<String> selected, ExploreController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Régimes', style: AppTextStyles.sectionHeader),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final diet in dietFilters)
              ChoiceChip(
                label: Text(
                  diet,
                  style: AppTextStyles.captionMedium.copyWith(
                    fontSize: 12,
                    color: selected.contains(diet)
                        ? AppColors.tonalGreenText
                        : AppColors.textSecondary,
                  ),
                ),
                selected: selected.contains(diet),
                showCheckmark: false,
                backgroundColor: AppColors.card,
                selectedColor: AppColors.softGreen,
                side: BorderSide(
                  color: selected.contains(diet)
                      ? AppColors.sage
                      : AppColors.borderSubtle,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                visualDensity: VisualDensity.compact,
                onSelected: (_) => controller.toggleDiet(diet),
              ),
          ],
        ),
      ],
    );
  }

  Widget _advancedFilters(
    BuildContext context,
    ExploreState filters,
    ExploreController controller,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _advancedOpen = !_advancedOpen),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Text('Filtres avancés', style: AppTextStyles.sectionHeader),
                  const Spacer(),
                  Icon(
                    _advancedOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_advancedOpen) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Temps de préparation',
                    style: AppTextStyles.captionMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final entry in <int?, String>{
                        15: '< 15 min',
                        30: '< 30 min',
                        45: '< 45 min',
                        null: 'Tous',
                      }.entries)
                        ChoiceChip(
                          label: Text(
                            entry.value,
                            style: AppTextStyles.caption,
                          ),
                          selected: filters.maxPrepMinutes == entry.key,
                          showCheckmark: false,
                          backgroundColor: AppColors.cream,
                          selectedColor: AppColors.softGreen,
                          side: const BorderSide(color: AppColors.borderSubtle),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) =>
                              controller.setMaxPrepMinutes(entry.key),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('Difficulté', style: AppTextStyles.captionMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final difficulty in Difficulty.values)
                        _DifficultyFilterChip(
                          label: difficulty.label,
                          isSelected: filters.difficulty == difficulty,
                          onSelected: (_) =>
                              controller.setDifficulty(difficulty),
                        ),
                      const SizedBox(width: 8),
                      _DifficultyFilterChip(
                        label: 'Tous',
                        isSelected: filters.difficulty == null,
                        onSelected: (_) => controller.setDifficulty(null),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text('Calories max', style: AppTextStyles.captionMedium),
                      const Spacer(),
                      Text(
                        '${filters.maxCalories} kcal',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                  Slider(
                    value: filters.maxCalories.toDouble(),
                    min: 200,
                    max: 1000,
                    divisions: 16,
                    onChanged: (value) =>
                        controller.setMaxCalories(value.round()),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('Portions', style: AppTextStyles.captionMedium),
                      const Spacer(),
                      IconButton(
                        onPressed: () => setState(
                          () => _servings = (_servings - 1).clamp(1, 12),
                        ),
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                        color: AppColors.primary,
                      ),
                      Text('$_servings', style: AppTextStyles.bodyMedium),
                      IconButton(
                        onPressed: () => setState(
                          () => _servings = (_servings + 1).clamp(1, 12),
                        ),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: OutlinedButton(
                      onPressed: controller.reset,
                      child: Text(
                        'Réinitialiser les filtres',
                        style: AppTextStyles.captionMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultsHeader(
    BuildContext context,
    int count,
    RecipeSortOption sort,
    ExploreController controller,
  ) {
    return Row(
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$count recettes',
                style: AppTextStyles.captionMedium.copyWith(fontSize: 14),
              ),
              TextSpan(text: ' trouvées', style: AppTextStyles.caption),
            ],
          ),
        ),
        const Spacer(),
        DropdownButton<RecipeSortOption>(
          value: sort,
          underline: const SizedBox.shrink(),
          icon: const Icon(Icons.sort_rounded, size: 18),
          style: AppTextStyles.captionMedium,
          onChanged: (value) {
            if (value != null) controller.setSort(value);
          },
          items: [
            for (final entry in sortLabels.entries)
              DropdownMenuItem<RecipeSortOption>(
                value: entry.key,
                child: Text(entry.value, style: AppTextStyles.caption),
              ),
          ],
        ),
      ],
    );
  }

  Widget _resultsGrid(BuildContext context, List<Recipe> results) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: results.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        final recipe = results[index];
        return _GridCard(
          recipe: recipe,
          onTap: () => context.push('/recipe/${recipe.id}'),
        );
      },
    );
  }

  Widget _emptyState(
    BuildContext context,
    String query,
    ExploreController controller,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.softGreenLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 30,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text('Aucune recette trouvée', style: AppTextStyles.subtitle),
          const SizedBox(height: 8),
          Text(
            'Aucune recette ne correspond à « $query » avec ces filtres. '
            'Essayez d’en retirer un.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySecondary,
          ),
          const SizedBox(height: 18),
          OutlinedButton(
            onPressed: () {
              controller.reset();
              _searchController.clear();
              setState(() => _advancedOpen = false);
            },
            child: const Text('Réinitialiser les filtres'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => context.push('/recommendations'),
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: const Text('Générer une recette avec l’IA'),
          ),
        ],
      ),
    );
  }
}

class _DifficultyFilterChip extends StatelessWidget {
  const _DifficultyFilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final bool isSelected;
  final ValueChanged<bool?> onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label, style: AppTextStyles.caption),
      selected: isSelected,
      showCheckmark: false,
      backgroundColor: AppColors.card,
      selectedColor: AppColors.softGreen,
      side: BorderSide(
        color: isSelected ? AppColors.sage : AppColors.borderSubtle,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      visualDensity: VisualDensity.compact,
      onSelected: onSelected,
    );
  }
}

class _GridCard extends StatelessWidget {
  const _GridCard({required this.recipe, required this.onTap});

  final Recipe recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14292D27),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 96,
                    width: double.infinity,
                    child: Image.network(
                      recipe.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: AppColors.softGreen),
                    ),
                  ),
                  if (recipe.dietBadges.isNotEmpty)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          recipe.dietBadges.first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.badge.copyWith(fontSize: 10),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.captionMedium.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${recipe.formattedTotalTime} · ${recipe.calories} kcal',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    if (recipe.matchPercentage != null) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value:
                              (recipe.matchPercentage! > 1
                                      ? recipe.matchPercentage! / 100
                                      : recipe.matchPercentage!)
                                  .clamp(0.0, 1.0),
                          minHeight: 5,
                          backgroundColor: AppColors.softGreen,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
