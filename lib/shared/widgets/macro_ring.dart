import 'package:flutter/material.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/core/theme/app_text_styles.dart';

/// Circular progress ring displaying nutritional macro intake vs daily target.
class MacroRing extends StatelessWidget {
  const MacroRing({
    required this.label,
    required this.current,
    required this.target,
    required this.unit,
    required this.color,
    super.key,
    this.size = 72.0,
    this.strokeWidth = 6.0,
  });

  final String label;
  final double current;
  final double target;
  final String unit;
  final Color color;
  final double size;
  final double strokeWidth;

  double get _fraction {
    if (target <= 0) return 0;
    return (current / target).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final cleanCurrent = current % 1 == 0
        ? current.toInt().toString()
        : current.toStringAsFixed(1);
    final cleanTarget = target % 1 == 0
        ? target.toInt().toString()
        : target.toStringAsFixed(0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: 1.0,
                strokeWidth: strokeWidth,
                color: color.withValues(alpha: 0.18),
              ),
              CircularProgressIndicator(
                value: _fraction,
                strokeWidth: strokeWidth,
                strokeCap: StrokeCap.round,
                color: color,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    cleanCurrent,
                    style: AppTextStyles.subtitle.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    unit,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.captionMedium.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '/ $cleanTarget $unit',
          style: AppTextStyles.caption.copyWith(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
