import 'dart:convert';

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
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark
        ? AppColors.softGreen
        : AppColors.textSecondary;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colors.onSurface.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
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
                        child: _RecipeImage(
                          imageUrl: recipe.imageUrl,
                          fallbackColor: colors.primaryContainer,
                          foregroundColor: colors.onPrimaryContainer,
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
                        color: colors.surface.withValues(alpha: 0.92),
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
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),

                  // Top-right Favorite Toggle Button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      color: colors.surface.withValues(alpha: 0.9),
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
                                : AppColors.favoriteIcon,
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
                        color: colors.onSurface,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Metrics: Time & Calories
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: secondaryText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          recipe.formattedTotalTime,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: secondaryText,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '·',
                          style: TextStyle(
                            color: secondaryText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${recipe.calories} kcal',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: secondaryText,
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

/// Affiche une URL ImgBB/Firebase Storage, une vignette Base64 historique ou
/// une image de remplacement si l'URL est vide/invalide.
class _RecipeImage extends StatelessWidget {
  const _RecipeImage({
    required this.imageUrl,
    required this.fallbackColor,
    required this.foregroundColor,
  });

  final String imageUrl;
  final Color fallbackColor;
  final Color foregroundColor;

  ImageProvider? _provider(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (trimmed.startsWith('data:')) {
      final commaIndex = trimmed.indexOf(',');
      if (commaIndex == -1) {
        return null;
      }
      try {
        return MemoryImage(base64Decode(trimmed.substring(commaIndex + 1)));
      } on Object {
        return null;
      }
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }
    return NetworkImage(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final provider = _provider(imageUrl);
    if (provider == null) {
      return _placeholder();
    }
    return Image(
      image: provider,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return ColoredBox(
          color: fallbackColor,
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: foregroundColor,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: fallbackColor,
      child: Center(
        child: Icon(Icons.restaurant_rounded, size: 40, color: foregroundColor),
      ),
    );
  }
}
