import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipemate/core/models/recipe.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/core/theme/app_text_styles.dart';
import 'package:recipemate/features/cooking_mode/step_durations.dart';
import 'package:recipemate/features/recipe_details/controllers/recipe_details_controller.dart';
import 'package:recipemate/features/recipe_details/recipe_lookup.dart';
import 'package:recipemate/shared/widgets/app_buttons.dart';
import 'package:recipemate/shared/widgets/diet_badge.dart';
import 'package:recipemate/shared/widgets/match_bar.dart';

/// Full recipe sheet with scalable ingredients, checklist and steps.
/// Owned by Molka.
class RecipeDetailsScreen extends ConsumerWidget {
  const RecipeDetailsScreen({this.recipeId, super.key});

  final String? recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipe = findRecipeById(recipeId ?? 'rec_1');
    final state = ref.watch(recipeDetailsControllerProvider(recipe.id));
    final controller = ref.read(
      recipeDetailsControllerProvider(recipe.id).notifier,
    );
    final missing = recipe.ingredients
        .where(
          (item) => !state.checkedIngredientIds.contains(item.ingredient.id),
        )
        .map((item) => item.ingredient.name)
        .toList();
    final durations = buildStepDurations(recipe);
    final matchPercentage = recipeMatchPercentage(
      recipe,
      state.checkedIngredientIds,
    );

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.cream,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    recipe.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: AppColors.softGreen,
                      child: Icon(
                        Icons.restaurant_rounded,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x33000000),
                          Colors.transparent,
                          Color(0x33000000),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: _circleButton(
              Icons.arrow_back_rounded,
              () => context.pop(),
            ),
            actions: [
              _circleButton(
                Icons.share_outlined,
                () => _share(context, recipe),
              ),
              _circleButton(
                state.isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                controller.toggleFavorite,
                color: AppColors.error,
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderSubtle,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final badge in recipe.dietBadges)
                        DietBadge(label: badge, isSmall: true),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(recipe.title, style: AppTextStyles.titleLarge),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (var i = 0; i < 5; i++)
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: AppColors.orangeAccent,
                        ),
                      const SizedBox(width: 6),
                      Text(
                        '${_rating(recipe.rating)} (1 248 avis)',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(recipe.description, style: AppTextStyles.bodySecondary),
                  const SizedBox(height: 14),
                  _infoRow(recipe, state.servings),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: _cardDecoration(),
                    child: MatchBar(percentage: matchPercentage),
                  ),
                  const SizedBox(height: 16),
                  _nutritionSection(recipe),
                  const SizedBox(height: 16),
                  _ingredientsSection(
                    context,
                    recipe,
                    state,
                    controller,
                    missing,
                  ),
                  const SizedBox(height: 16),
                  _stepsSection(recipe, durations),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlineButtonWidget(
                          label: 'Dans mes favoris',
                          icon: state.isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          isFullWidth: true,
                          onPressed: controller.toggleFavorite,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlineButtonWidget(
                          label: 'Liste de courses',
                          icon: Icons.shopping_bag_outlined,
                          isFullWidth: true,
                          onPressed: () =>
                              _shoppingList(context, missing.length),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: const BoxDecoration(
          color: AppColors.card,
          border: Border(top: BorderSide(color: AppColors.borderSubtle)),
        ),
        child: SafeArea(
          top: false,
          child: PrimaryButton(
            label: 'Commencer à cuisiner',
            icon: Icons.play_arrow_rounded,
            isFullWidth: true,
            onPressed: () => context.push('/cooking/${recipe.id}'),
          ),
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onPressed, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.white.withValues(alpha: 0.92),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: color ?? AppColors.textPrimary, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(Recipe recipe, int servings) {
    final items = <MapEntry<String, String>>[
      MapEntry('Préparation', '${recipe.prepTimeMinutes} min'),
      MapEntry('Cuisson', '${recipe.cookTimeMinutes} min'),
      MapEntry('Difficulté', recipe.difficulty.label),
      MapEntry('Portions', '$servings'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: Column(
                children: [
                  Text(
                    item.value,
                    style: AppTextStyles.subtitle.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(item.key, style: AppTextStyles.caption),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _nutritionSection(Recipe recipe) {
    final tiles = <MapEntry<String, String>>[
      MapEntry(recipe.calories.toString(), 'kcal'),
      MapEntry('${recipe.proteinGrams.toInt()} g', 'Protéines'),
      MapEntry('${recipe.carbsGrams.toInt()} g', 'Glucides'),
      MapEntry('${recipe.fatGrams.toInt()} g', 'Lipides'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Nutrition', style: AppTextStyles.sectionHeader),
            const SizedBox(width: 8),
            Text('par portion', style: AppTextStyles.caption),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final tile in tiles)
              Expanded(
                child: _NutritionCircle(value: tile.key, label: tile.value),
              ),
          ],
        ),
      ],
    );
  }

  Widget _ingredientsSection(
    BuildContext context,
    Recipe recipe,
    RecipeDetailsState state,
    RecipeDetailsController controller,
    List<String> missing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Ingrédients', style: AppTextStyles.sectionHeader),
            const Spacer(),
            IconButton(
              onPressed: () => controller.changeServings(-1),
              icon: const Icon(Icons.remove_circle_outline_rounded),
              color: AppColors.primary,
            ),
            Text(
              '${state.servings} portions',
              style: AppTextStyles.captionMedium,
            ),
            IconButton(
              onPressed: () => controller.changeServings(1),
              icon: const Icon(Icons.add_circle_outline_rounded),
              color: AppColors.primary,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (missing.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.orangeContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.orangeText,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${missing.length} ingrédient${missing.length > 1 ? 's' : ''} '
                    'manquant${missing.length > 1 ? 's' : ''} — '
                    '${missing.join(', ')}.',
                    style: AppTextStyles.captionMedium.copyWith(
                      color: AppColors.orangeText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Container(
          decoration: _cardDecoration(),
          child: Column(
            children: [
              for (final item in recipe.ingredients)
                _IngredientRow(
                  name: item.ingredient.name,
                  quantity: scaledQuantity(
                    item.quantity,
                    item.unit,
                    state.servings,
                    recipe.servings,
                  ),
                  isChecked: state.checkedIngredientIds.contains(
                    item.ingredient.id,
                  ),
                  onChanged: (_) =>
                      controller.toggleIngredient(item.ingredient.id),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stepsSection(Recipe recipe, List<int> durations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Préparation', style: AppTextStyles.sectionHeader),
        const SizedBox(height: 12),
        for (var i = 0; i < recipe.instructions.length; i++)
          _StepTile(
            number: i + 1,
            title: stepTitle(recipe.instructions[i]),
            description: recipe.instructions[i],
            durationSeconds: durations[i],
          ),
      ],
    );
  }

  Future<void> _share(BuildContext context, Recipe recipe) async {
    await Clipboard.setData(
      ClipboardData(text: 'recipemate://recipe/${recipe.id}'),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Lien de la recette copié')));
  }

  void _shoppingList(BuildContext context, int count) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            count == 0
                ? 'Tous les ingrédients sont déjà dans votre frigo.'
                : '$count ingrédient${count > 1 ? 's' : ''} ajouté${count > 1 ? 's' : ''} à la liste de courses.',
          ),
        ),
      );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: AppColors.borderSubtle),
  );
}

String _rating(double value) => value.toStringAsFixed(1).replaceAll('.', ',');

class _NutritionCircle extends StatelessWidget {
  const _NutritionCircle({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: AppColors.softGreenLight,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.tonalGreenText,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.name,
    required this.quantity,
    required this.isChecked,
    required this.onChanged,
  });

  final String name;
  final String quantity;
  final bool isChecked;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Checkbox(value: isChecked, onChanged: onChanged),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isChecked
                  ? AppColors.softGreen
                  : AppColors.orangeContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isChecked
                  ? Icons.check_circle_outline_rounded
                  : Icons.shopping_basket_outlined,
              size: 18,
              color: isChecked ? AppColors.primary : AppColors.orangeText,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTextStyles.bodyMedium),
                Text(
                  isChecked ? 'Dans votre frigo' : 'Manquant',
                  style: AppTextStyles.caption.copyWith(
                    color: isChecked ? AppColors.primary : AppColors.orangeText,
                  ),
                ),
              ],
            ),
          ),
          Text(quantity, style: AppTextStyles.captionMedium),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.number,
    required this.title,
    required this.description,
    required this.durationSeconds,
  });

  final int number;
  final String title;
  final String description;
  final int durationSeconds;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: AppTextStyles.captionMedium.copyWith(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(description, style: AppTextStyles.bodySecondary),
                if (durationSeconds > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.softGreenLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${durationSeconds ~/ 60} min',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
