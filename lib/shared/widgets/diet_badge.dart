import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipemate/core/theme/app_colors.dart';

/// Styled badge chip used to display diets, categories or tags.
/// Aligned with `docs/design/RecipeMate.html`:
/// - Height: 26-28px
/// - Border radius: 8px (or 99px for pill style)
/// - Background: `#DDEBCB`
/// - Text: `#292D27`, font-size: 12px, font-weight: 600
class DietBadge extends StatelessWidget {
  const DietBadge({
    required this.label,
    super.key,
    this.backgroundColor = AppColors.softGreen,
    this.textColor = AppColors.textPrimary,
    this.isSmall = false,
    this.isPill = false,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final bool isSmall;
  final bool isPill;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final effectiveBackground = backgroundColor == AppColors.softGreen
        ? colors.primaryContainer
        : backgroundColor;
    final effectiveText = textColor == AppColors.textPrimary
        ? colors.onPrimaryContainer
        : textColor;
    return Container(
      height: isSmall ? 24.0 : 26.0,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: effectiveBackground,
        borderRadius: BorderRadius.circular(isPill ? 99 : 8),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: isSmall ? 11 : 12,
          fontWeight: FontWeight.w600,
          color: effectiveText,
        ),
      ),
    );
  }
}
