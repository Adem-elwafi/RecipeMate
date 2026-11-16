import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipemate/core/theme/app_colors.dart';

/// Circular progress ring displaying nutritional macro intake vs daily target.
/// Aligned with `docs/design/RecipeMate.html`:
/// - 64px diameter ring with 48px inner circle (8px stroke)
/// - Track: `#EEE9DD`
/// - Center percentage text: Inter 13px bold `#292D27`
/// - Underneath label: Inter 12px `#5E6457`
class MacroRing extends StatelessWidget {
  const MacroRing({
    required this.label,
    required this.current,
    required this.target,
    required this.unit,
    required this.color,
    super.key,
    this.size = 64.0,
    this.strokeWidth = 8.0,
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

  int get _percentInt => (_fraction * 100).round();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Track background #EEE9DD
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: strokeWidth,
                  color: AppColors.borderSubtle,
                ),
              ),
              // Active progress
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: _fraction,
                  strokeWidth: strokeWidth,
                  strokeCap: StrokeCap.round,
                  color: color,
                ),
              ),
              // Inner 48px white circle with center text
              Container(
                width: size - (strokeWidth * 2),
                height: size - (strokeWidth * 2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$_percentInt%',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
