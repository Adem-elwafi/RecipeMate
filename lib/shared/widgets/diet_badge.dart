import 'package:flutter/material.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/core/theme/app_text_styles.dart';

/// Styled badge chip used to display diets, categories or tags.
class DietBadge extends StatelessWidget {
  const DietBadge({
    required this.label,
    super.key,
    this.backgroundColor = AppColors.softGreenLight,
    this.textColor = AppColors.primaryDark,
    this.isSmall = false,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final bool isSmall;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 10,
        vertical: isSmall ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: textColor.withValues(alpha: 0.2), width: 0.8),
      ),
      child: Text(
        label,
        style: (isSmall ? AppTextStyles.label : AppTextStyles.badge).copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
