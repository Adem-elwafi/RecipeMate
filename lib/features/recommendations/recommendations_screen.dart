import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:recipemate/core/data/mock_data.dart';
import 'package:recipemate/core/models/recipe.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/core/theme/app_text_styles.dart';
import 'package:recipemate/shared/widgets/recipe_card.dart';

/// AI Anti-Waste Recipe Recommendations screen (Owner: Adem).
class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sort recipes by match percentage descending
    final recommendations = List<Recipe>.from(MockData.recipes)
      ..sort(
        (a, b) =>
            (b.matchPercentage ?? 0.0).compareTo(a.matchPercentage ?? 0.0),
      );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Recettes IA Anti-Gaspi',
          style: AppTextStyles.title.copyWith(fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Anti-Waste Explanatory Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.softGreenLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.softGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primaryDark,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suggestions intelligentes',
                        style: AppTextStyles.subtitle.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ces recettes exploitent en priorité les aliments de votre frigo pour zéro déchet.',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Meilleurs matches (${recommendations.length} recettes)',
            style: AppTextStyles.subtitle.copyWith(fontSize: 17),
          ),
          const SizedBox(height: 12),

          ...recommendations.map((recipe) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: RecipeCard(
                recipe: recipe,
                showMatchBar: true,
                onTap: () => context.push('/recipe/${recipe.id}'),
              ),
            );
          }),
        ],
      ),
    );
  }
}
