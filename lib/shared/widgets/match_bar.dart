import 'package:flutter/material.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/core/theme/app_text_styles.dart';

/// Progress bar indicating the percentage of recipe ingredients
/// available in the user's fridge.
class MatchBar extends StatelessWidget {
  const MatchBar({
    required this.percentage,
    super.key,
    this.showLabel = true,
    this.height = 7.0,
  });

  /// Percentage value between 0.0 and 1.0 (or 0 to 100)
  final double percentage;
  final bool showLabel;
  final double height;

  double get _clampedFraction {
    final val = percentage > 1.0 ? percentage / 100.0 : percentage;
    return val.clamp(0.0, 1.0);
  }

  int get _percentInt => (_clampedFraction * 100).round();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$_percentInt% d’ingrédients disponibles',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionMedium.copyWith(
                    color: AppColors.primaryDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.check_circle_rounded,
                size: 14,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 5),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: _clampedFraction,
            minHeight: height,
            backgroundColor: AppColors.softGreen,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}
