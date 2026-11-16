import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:recipemate/core/data/mock_data.dart';
import 'package:recipemate/core/models/recipe.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/core/theme/app_text_styles.dart';
import 'package:recipemate/shared/widgets/app_buttons.dart';
import 'package:recipemate/shared/widgets/diet_badge.dart';

/// Full recipe details screen (Owner: Molka).
class RecipeDetailsScreen extends StatefulWidget {
  const RecipeDetailsScreen({required this.recipeId, super.key});

  final String recipeId;

  @override
  State<RecipeDetailsScreen> createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends State<RecipeDetailsScreen> {
  late bool _isFavorite;
  int _servings = 2;

  @override
  void initState() {
    super.initState();
    final recipe = _findRecipe();
    _isFavorite = recipe?.isFavorite ?? false;
    _servings = recipe?.servings ?? 2;
  }

  Recipe? _findRecipe() {
    try {
      return MockData.recipes.firstWhere((r) => r.id == widget.recipeId);
    } catch (_) {
      return MockData.recipes.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = _findRecipe();

    if (recipe == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recette introuvable')),
        body: const Center(child: Text('Cette recette n’existe pas.')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image & Favorite Button
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    recipe.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const ColoredBox(
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
                          Colors.black38,
                          Colors.transparent,
                          Colors.black45,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textPrimary,
                  ),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: FavoriteButton(
                  isFavorite: _isFavorite,
                  onToggle: () {
                    setState(() {
                      _isFavorite = !_isFavorite;
                    });
                  },
                ),
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges
                  Wrap(
                    spacing: 8,
                    children: recipe.dietBadges
                        .map((b) => DietBadge(label: b))
                        .toList(),
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(recipe.title, style: AppTextStyles.titleLarge),
                  const SizedBox(height: 8),

                  // Description
                  Text(recipe.description, style: AppTextStyles.bodySecondary),
                  const SizedBox(height: 20),

                  // Metrics Cards
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _metricItem(
                          Icons.timer_outlined,
                          'Préparation',
                          '${recipe.prepTimeMinutes} min',
                        ),
                        _metricItem(
                          Icons.soup_kitchen_outlined,
                          'Cuisson',
                          '${recipe.cookTimeMinutes} min',
                        ),
                        _metricItem(
                          Icons.local_fire_department_outlined,
                          'Énergie',
                          '${recipe.calories} kcal',
                        ),
                        _metricItem(
                          Icons.star_rounded,
                          'Note',
                          '${recipe.rating}/5',
                          iconColor: Colors.amber,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Servings Counter
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Ingrédients', style: AppTextStyles.title),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: _servings > 1
                                ? () => setState(() => _servings--)
                                : null,
                          ),
                          Text(
                            '$_servings portions',
                            style: AppTextStyles.bodyMedium,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => setState(() => _servings++),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Ingredients List
                  ...recipe.ingredients.map((ri) {
                    final multiplier = _servings / recipe.servings;
                    final calculatedQty = ri.quantity * multiplier;
                    final cleanQty = calculatedQty % 1 == 0
                        ? calculatedQty.toInt().toString()
                        : calculatedQty.toStringAsFixed(1);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              ri.ingredient.name,
                              style: AppTextStyles.body,
                            ),
                          ),
                          Text(
                            ri.unit.isEmpty ? cleanQty : '$cleanQty ${ri.unit}',
                            style: AppTextStyles.captionMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 28),

                  // Instructions
                  Text(
                    'Préparation étape par étape',
                    style: AppTextStyles.title,
                  ),
                  const SizedBox(height: 14),
                  ...recipe.instructions.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final step = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.softGreen,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$index',
                              style: AppTextStyles.captionMedium.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(step, style: AppTextStyles.body),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 32),

                  // Start Cooking Mode Button
                  PrimaryButton(
                    label: 'Lancer le mode cuisine',
                    icon: Icons.play_arrow_rounded,
                    isFullWidth: true,
                    onPressed: () => context.push('/cooking/${recipe.id}'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricItem(
    IconData icon,
    String label,
    String value, {
    Color? iconColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: iconColor ?? AppColors.primary),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.captionMedium),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
