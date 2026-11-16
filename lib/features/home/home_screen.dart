import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:recipemate/core/data/mock_data.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/core/theme/app_text_styles.dart';
import 'package:recipemate/shared/widgets/macro_ring.dart';
import 'package:recipemate/shared/widgets/recipe_card.dart';

/// Home screen dashboard (Owner: Molka).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expiringCount = MockData.initialFridgeItems
        .where((item) => item.isExpiringSoon)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour, ${MockData.defaultUser.name} 👋',
              style: AppTextStyles.subtitle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Que cuisinons-nous aujourd’hui ?',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border_rounded),
            onPressed: () => context.push('/favorites'),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () => context.push('/scanner'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Anti-waste Expiration Alert Banner
          if (expiringCount > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.orangeContainer,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.orangeAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.orangeAccent.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.orangeText,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Anti-gaspillage : $expiringCount aliments à consommer',
                          style: AppTextStyles.subtitle.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.orangeText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Découvrez des recettes adaptées pour vos ingrédients.',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 12,
                            color: AppColors.orangeText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Daily Nutrition Macro Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Objectifs nutritionnels',
                      style: AppTextStyles.subtitle.copyWith(fontSize: 16),
                    ),
                    Text(
                      "Aujourd'hui",
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    MacroRing(
                      label: 'Calories',
                      current: 1450,
                      target: 2100,
                      unit: 'kcal',
                      color: AppColors.macroCalories,
                    ),
                    MacroRing(
                      label: 'Protéines',
                      current: 95,
                      target: 135,
                      unit: 'g',
                      color: AppColors.macroProtein,
                    ),
                    MacroRing(
                      label: 'Glucides',
                      current: 140,
                      target: 210,
                      unit: 'g',
                      color: AppColors.macroCarbs,
                    ),
                    MacroRing(
                      label: 'Lipides',
                      current: 42,
                      target: 65,
                      unit: 'g',
                      color: AppColors.macroFat,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Recommended Recipes Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Suggestions pour vous',
                style: AppTextStyles.title.copyWith(fontSize: 19),
              ),
              TextButton(
                onPressed: () => context.go('/explore'),
                child: const Text('Voir tout'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: MockData.recipes.length,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final recipe = MockData.recipes[index];
                return SizedBox(
                  width: 260,
                  child: RecipeCard(
                    recipe: recipe,
                    onTap: () => context.push('/recipe/${recipe.id}'),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 28),

          // Team Member Badge
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.softGreenLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Module Accueil développé par Molka',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
