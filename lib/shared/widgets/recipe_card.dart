import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipemate/core/models/recipe.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/shared/widgets/match_bar.dart';

/// Reusable recipe card widget matching `docs/design/RecipeMate.html`:
/// - 18px border-radius, white background, shadow `rgba(41,45,39,.08)`
/// - Image container with 14px radius
/// - "Healthy" badge in top-left (rgba(255,255,255,0.92), text `#3F6233`, 11px font-weight 600, radius 7px)
/// - Poppins 14px title
/// - Time and kcal in Inter 12px `#5E6457`
/// - Optional MatchBar below
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14292D27), // rgba(41, 45, 39, 0.08)
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Recipe Header with Image & Badges
              Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        height: 120,
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
                                    size: 40,
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
                  ),

                  // Top-left "Healthy" badge
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      height: 22,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        recipe.dietBadges.isNotEmpty
                            ? recipe.dietBadges.first
                            : 'Healthy',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.tonalGreenText,
                        ),
                      ),
                    ),
                  ),

                  // Top-right Favorite Toggle Button
                  Positioned(
                    top: 12,
                    right: 12,
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
                            size: 18,
                            color: recipe.isFavorite
                                ? AppColors.error
                                : const Color(0xFFC97A22),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Recipe Body Details
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Metrics: Time & Calories
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          recipe.formattedTotalTime,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          '·',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${recipe.calories} kcal',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    // Optional Match Bar for Fridge Matching
                    if (showMatchBar && recipe.matchPercentage != null) ...[
                      const SizedBox(height: 10),
                      MatchBar(
                        percentage: recipe.matchPercentage!,
                        height: 6,
                        showLabel: false,
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
