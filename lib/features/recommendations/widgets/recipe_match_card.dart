import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/features/recommendations/models/recipe_match_result.dart';
import 'package:recipemate/features/recommendations/widgets/match_donut.dart';

/// Recipe recommendation card matching `07 · Recettes IA` in `RecipeMate.html`.
class RecipeMatchCard extends StatelessWidget {
  const RecipeMatchCard({
    required this.result,
    required this.onViewRecipe,
    super.key,
  });

  final RecipeMatchResult result;
  final VoidCallback onViewRecipe;

  @override
  Widget build(BuildContext context) {
    final recipe = result.recipe;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.09),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 184,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        recipe.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }
                          return const ColoredBox(
                            color: AppColors.softGreenLight,
                            child: Center(
                              child: Icon(
                                Icons.restaurant_menu_rounded,
                                size: 36,
                                color: AppColors.sage,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const ColoredBox(
                            color: AppColors.softGreen,
                            child: Center(
                              child: Icon(
                                Icons.restaurant_menu_rounded,
                                size: 42,
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        },
                      ),
                      if (result.hasAllergyConflict)
                        const Positioned(
                          left: 12,
                          top: 12,
                          child: _TopImageBadge(
                            icon: Icons.warning_amber_rounded,
                            label: 'Allergène',
                            backgroundColor: AppColors.errorContainer,
                            textColor: AppColors.error,
                          ),
                        )
                      else if (result.usesExpiringSoonIngredient)
                        const Positioned(
                          left: 12,
                          top: 12,
                          child: _TopImageBadge(
                            icon: Icons.schedule_rounded,
                            label: 'Anti-gaspi',
                            backgroundColor: AppColors.orangeContainer,
                            textColor: AppColors.orangeText,
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 84),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipe.title,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${recipe.formattedTotalTime} • '
                              '${recipe.calories} kcal • '
                              '${result.difficultyLabel}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: result.matchPercentage.clamp(0, 100) / 100.0,
                          minHeight: 8,
                          backgroundColor: AppColors.softGreen,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (result.matchedIngredients.isNotEmpty) ...[
                        Text(
                          'Vous avez',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.tonalGreenText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final ing in result.matchedIngredients)
                              _MatchedIngredientChip(label: ing),
                          ],
                        ),
                      ],
                      if (result.missingIngredients.isNotEmpty) ...[
                        if (result.matchedIngredients.isNotEmpty)
                          const SizedBox(height: 10),
                        Text(
                          'Il manque',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.orangeText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final ing in result.missingIngredients)
                              _MissingIngredientChip(label: ing),
                          ],
                        ),
                      ] else ...[
                        if (result.matchedIngredients.isNotEmpty)
                          const SizedBox(height: 10),
                        const _AllIngredientsAvailablePill(),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final badge in recipe.dietBadges)
                                  _CardDietTag(label: badge),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Material(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: onViewRecipe,
                              child: SizedBox(
                                height: 46,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Voir la recette',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              right: 14,
              top: 140,
              child: MatchDonut(percentage: result.matchPercentage),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopImageBadge extends StatelessWidget {
  const _TopImageBadge({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchedIngredientChip extends StatelessWidget {
  const _MatchedIngredientChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.freshBadgeBg,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_rounded,
            size: 12,
            color: AppColors.tonalGreenText,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.tonalGreenText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingIngredientChip extends StatelessWidget {
  const _MissingIngredientChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: const _DashedRRectBorderPainter(
        color: AppColors.orangeAccent,
        radius: 9,
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 28),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.orangeContainer,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          '+ $label',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.orangeText,
          ),
        ),
      ),
    );
  }
}

class _AllIngredientsAvailablePill extends StatelessWidget {
  const _AllIngredientsAvailablePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.freshBadgeBg,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 14,
            color: AppColors.tonalGreenText,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              'Tous les ingrédients disponibles !',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.tonalGreenText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardDietTag extends StatelessWidget {
  const _CardDietTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _DashedRRectBorderPainter extends CustomPainter {
  const _DashedRRectBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const double _strokeWidth = 1.0;
  static const double _dashWidth = 4.0;
  static const double _dashSpace = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_strokeWidth / 2);
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = math.min(distance + _dashWidth, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance += _dashWidth + _dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
