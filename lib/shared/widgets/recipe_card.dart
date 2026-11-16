import 'package:flutter/material.dart';
import 'package:recipemate/core/models/recipe.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/core/theme/app_text_styles.dart';
import 'package:recipemate/shared/widgets/diet_badge.dart';
import 'package:recipemate/shared/widgets/match_bar.dart';

/// High-fidelity recipe card widget matching `docs/design/RecipeMate.html`.
class RecipeCard extends StatelessWidget {
  const RecipeCard({
    required this.recipe,
    super.key,
    this.onTap,
    this.onFavoriteToggle,
    this.showMatchBar = true,
    this.width,
  });

  final Recipe recipe;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final bool showMatchBar;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A292D27),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Recipe Header with Image & Badges
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: SizedBox(
                      height: 140,
                      width: double.infinity,
                      child: Image.network(
                        recipe.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const ColoredBox(
                              color: AppColors.softGreen,
                              child: Center(
                                child: Icon(
                                  Icons.restaurant_rounded,
                                  size: 44,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const ColoredBox(
                            color: AppColors.softGreenLight,
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Top Diet Badges
                  if (recipe.dietBadges.isNotEmpty)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: DietBadge(
                        label: recipe.dietBadges.first,
                        isSmall: true,
                        backgroundColor: Colors.white.withValues(alpha: 0.92),
                        textColor: AppColors.primaryDark,
                      ),
                    ),

                  // Favorite Button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onFavoriteToggle,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            recipe.isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 20,
                            color: recipe.isFavorite
                                ? AppColors.error
                                : AppColors.greyIcon,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Recipe Body Details
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subtitle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Metrics: Time & Calories
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
                          style: AppTextStyles.captionMedium.copyWith(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.local_fire_department_rounded,
                          size: 15,
                          color: AppColors.orangeAccent,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${recipe.calories} kcal',
                          style: AppTextStyles.captionMedium.copyWith(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    // Optional Match Bar for Fridge Matching
                    if (showMatchBar && recipe.matchPercentage != null) ...[
                      const SizedBox(height: 12),
                      MatchBar(percentage: recipe.matchPercentage!, height: 6),
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
