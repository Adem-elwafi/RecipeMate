import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:recipemate/core/data/mock_data.dart';
import 'package:recipemate/core/data/recipe_database.dart';
import 'package:recipemate/core/models/fridge_item.dart';
import 'package:recipemate/core/models/recipe.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/core/theme/app_text_styles.dart';
import 'package:recipemate/features/explore/controllers/explore_controller.dart';
import 'package:recipemate/features/home/controllers/home_controller.dart';
import 'package:recipemate/features/recipe_details/controllers/recipe_details_controller.dart';
import 'package:recipemate/shared/widgets/match_bar.dart';

/// Dashboard: greeting, daily macros, recipe of the day, suggestions and
/// anti-waste banner. Owned by Molka.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(homeControllerProvider).selectedCategory;
    final popular = ref.watch(popularRecipesProvider);
    final firstName = MockData.defaultUser.name.split(' ').first;
    final recipes = MockData.recipes;
    final recipeOfDay = recipes.first;
    final expiringItems = MockData.initialFridgeItems
        .where((item) => item.isExpiringSoon)
        .toList();
    final recommended = <Recipe>[...recipes]
      ..sort(
        (a, b) => (b.matchPercentage ?? 0).compareTo(a.matchPercentage ?? 0),
      );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context, firstName),
            const SizedBox(height: 18),
            _searchBar(context),
            const SizedBox(height: 14),
            _categories(context, ref, selectedCategory),
            const SizedBox(height: 26),
            _sectionHeader('Recette du jour'),
            const SizedBox(height: 12),
            _recipeOfDayCard(context, ref, recipeOfDay),
            const SizedBox(height: 26),
            _sectionHeader(
              'Ma nutrition du jour',
              action: 'Objectifs',
              onAction: () => context.push('/profile'),
            ),
            const SizedBox(height: 12),
            _nutritionCard(ref),
            const SizedBox(height: 26),
            _sectionHeader(
              'Recommandé pour vous',
              subtitle: 'Selon les ingrédients de votre frigo.',
              action: 'Tout voir',
              onAction: () => context.push('/recommendations'),
              icon: Icons.auto_awesome_rounded,
            ),
            const SizedBox(height: 12),
            _recommendations(context, recommended.take(3).toList()),
            const SizedBox(height: 26),
            _sectionHeader(
              'Recettes populaires',
              action: 'Tout voir',
              onAction: () => context.push('/explore'),
            ),
            const SizedBox(height: 12),
            _popular(context, popular),
            const SizedBox(height: 26),
            _antiWasteBanner(context, expiringItems),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, String firstName) {
    final initials = firstName.isEmpty ? '?' : firstName[0].toUpperCase();
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bonjour, $firstName !', style: AppTextStyles.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Que voulez-vous cuisiner aujourd’hui ?',
                style: AppTextStyles.bodySecondary,
              ),
            ],
          ),
        ),
        Stack(
          children: [
            IconButton(
              onPressed: () =>
                  _showMessage(context, 'Vous avez 2 nouvelles notifications.'),
              icon: const Icon(Icons.notifications_none_rounded),
              style: IconButton.styleFrom(backgroundColor: AppColors.card),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.orangeAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          backgroundColor: AppColors.softGreen,
          foregroundColor: AppColors.tonalGreenText,
          child: Text(initials, style: AppTextStyles.captionMedium),
        ),
      ],
    );
  }

  Widget _searchBar(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/explore'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Rechercher recettes ou ingrédients…',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ),
            const Icon(
              Icons.tune_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _categories(
    BuildContext context,
    WidgetRef ref,
    String? selectedCategory,
  ) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: homeCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final label = homeCategories[index];
          final isSelected = selectedCategory == label;
          return ChoiceChip(
            label: Text(
              label,
              style: AppTextStyles.captionMedium.copyWith(
                fontSize: 12,
                color: isSelected
                    ? AppColors.tonalGreenText
                    : AppColors.textSecondary,
              ),
            ),
            selected: isSelected,
            showCheckmark: false,
            backgroundColor: AppColors.card,
            selectedColor: AppColors.softGreen,
            side: BorderSide(
              color: isSelected ? AppColors.sage : AppColors.borderSubtle,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            visualDensity: VisualDensity.compact,
            onSelected: (_) {
              ref.read(homeControllerProvider.notifier).selectCategory(label);
              ref.read(exploreControllerProvider.notifier).setCategory(label);
              context.push('/explore');
            },
          );
        },
      ),
    );
  }

  Widget _sectionHeader(
    String title, {
    String? subtitle,
    String? action,
    VoidCallback? onAction,
    IconData? icon,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(title, style: AppTextStyles.sectionHeader),
                  if (icon != null) ...[
                    const SizedBox(width: 6),
                    Icon(icon, size: 18, color: AppColors.primary),
                  ],
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ],
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              action,
              style: AppTextStyles.captionMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _recipeOfDayCard(BuildContext context, WidgetRef ref, Recipe recipe) {
    final isFavorite = ref
        .watch(recipeDetailsControllerProvider(recipe.id))
        .isFavorite;
    return Container(
      decoration: _cardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: SizedBox(
                  height: 170,
                  width: double.infinity,
                  child: Image.network(
                    recipe.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: AppColors.softGreen,
                      child: Center(
                        child: Icon(
                          Icons.restaurant_rounded,
                          size: 46,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Recette du jour',
                    style: AppTextStyles.badge.copyWith(fontSize: 11),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => ref
                        .read(
                          recipeDetailsControllerProvider(recipe.id).notifier,
                        )
                        .toggleFavorite(),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.favorite_rounded,
                        size: 18,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(recipe.title, style: AppTextStyles.subtitle),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      recipe.formattedTotalTime,
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.local_fire_department_outlined,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${recipe.calories} kcal',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.star_rounded,
                      size: 15,
                      color: AppColors.orangeAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _rating(recipe.rating),
                      style: AppTextStyles.captionMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (isFavorite)
                  Text(
                    'Dans vos favoris',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/recipe/${recipe.id}'),
                    child: Text(
                      'Voir la recette',
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
      ),
    );
  }

  Widget _nutritionCard(WidgetRef ref) {
    final nutrition = ref.watch(recipeDatabaseProvider).today;
    const profile = MockData.defaultUser;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _CalorieRing(
                current: nutrition.calories.round(),
                target: profile.calorieGoal,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    _macroRow(
                      'Protéines',
                      nutrition.proteinGrams,
                      profile.proteinGoal,
                      'g',
                      AppColors.macroProtein,
                    ),
                    const SizedBox(height: 12),
                    _macroRow(
                      'Glucides',
                      nutrition.carbsGrams,
                      profile.carbsGoal,
                      'g',
                      AppColors.macroCarbs,
                    ),
                    const SizedBox(height: 12),
                    _macroRow(
                      'Lipides',
                      nutrition.fatGrams,
                      profile.fatGoal,
                      'g',
                      AppColors.macroFat,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Statistiques du jour — ${_number(nutrition.calories.round())} kcal '
            '· ${_number(nutrition.proteinGrams.round())} g de protéines '
            '· ${_number(nutrition.carbsGrams.round())} g de glucides '
            '· ${_number(nutrition.fatGrams.round())} g de lipides '
            '· ${_number(nutrition.completedRecipes)} repas terminés',
            style: AppTextStyles.caption.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Valeurs indicatives — RecipeMate n’est pas un outil médical.',
            style: AppTextStyles.caption.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _macroRow(
    String label,
    double current,
    double target,
    String unit,
    Color color,
  ) {
    final fraction = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: AppTextStyles.captionMedium),
            const Spacer(),
            Text(
              '${current.toInt()} / ${target.toInt()} $unit',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 8,
            backgroundColor: AppColors.softGreen,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _recommendations(BuildContext context, List<Recipe> recipes) {
    if (recipes.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 216,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: recipes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return _RecommendationTile(
            recipe: recipe,
            onTap: () => context.push('/recipe/${recipe.id}'),
          );
        },
      ),
    );
  }

  Widget _popular(BuildContext context, List<Recipe> recipes) {
    return SizedBox(
      height: 230,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: recipes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return SizedBox(
            width: 200,
            child: _PopularCard(
              recipe: recipe,
              onTap: () => context.push('/recipe/${recipe.id}'),
            ),
          );
        },
      ),
    );
  }

  Widget _antiWasteBanner(
    BuildContext context,
    List<FridgeItem> expiringItems,
  ) {
    final names = expiringItems
        .map((item) => item.ingredient.name.toLowerCase())
        .take(3)
        .join(', ');
    return InkWell(
      onTap: () => context.push('/fridge'),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.kitchen_outlined,
                color: AppColors.softGreen,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${expiringItems.length} ingrédients expirent bientôt',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$names — cuisinez-les d’abord.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.softGreen,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.softGreen),
          ],
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: AppColors.borderSubtle),
    boxShadow: const [
      BoxShadow(color: Color(0x14292D27), blurRadius: 20, offset: Offset(0, 6)),
    ],
  );
}

String _rating(double value) => value.toStringAsFixed(1).replaceAll('.', ',');

String _number(int value) => NumberFormat.decimalPattern('fr_FR').format(value);

List<String> _missingIngredients(Recipe recipe) {
  final fridge = MockData.initialFridgeItems
      .map((item) => item.ingredient.id)
      .toSet();
  return recipe.ingredients
      .where((item) => !fridge.contains(item.ingredient.id))
      .map((item) => item.ingredient.name)
      .toList();
}

class _CalorieRing extends StatelessWidget {
  const _CalorieRing({required this.current, required this.target});

  final int current;
  final int target;

  @override
  Widget build(BuildContext context) {
    final fraction = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const SizedBox(
            width: 104,
            height: 104,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 10,
              color: AppColors.borderSubtle,
            ),
          ),
          SizedBox(
            width: 104,
            height: 104,
            child: CircularProgressIndicator(
              value: fraction,
              strokeWidth: 10,
              strokeCap: StrokeCap.round,
              color: AppColors.macroCalories,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _number(current),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text('/ ${_number(target)} kcal', style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile({required this.recipe, required this.onTap});

  final Recipe recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final missing = _missingIngredients(recipe);
    return SizedBox(
      width: 200,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 92,
                    width: double.infinity,
                    child: Image.network(
                      recipe.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: AppColors.softGreen),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        '${((recipe.matchPercentage ?? 0) * 100).round()}% match',
                        style: AppTextStyles.captionMedium.copyWith(
                          color: Colors.white,
                          fontSize: 11,
                        ),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.captionMedium.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    MatchBar(
                      percentage: recipe.matchPercentage ?? 0,
                      height: 6,
                      showLabel: false,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      missing.isEmpty
                          ? 'Tous les ingrédients sont là'
                          : 'Manque : ${missing.take(2).join(', ')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        fontSize: 11,
                        color: missing.isEmpty
                            ? AppColors.primary
                            : AppColors.orangeText,
                      ),
                    ),
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

class _PopularCard extends StatelessWidget {
  const _PopularCard({required this.recipe, required this.onTap});

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
              SizedBox(
                height: 112,
                width: double.infinity,
                child: Image.network(
                  recipe.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const ColoredBox(color: AppColors.softGreen),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (recipe.dietBadges.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.softGreen,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          recipe.dietBadges.first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.badge.copyWith(fontSize: 10),
                        ),
                      ),
                    const SizedBox(height: 6),
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
