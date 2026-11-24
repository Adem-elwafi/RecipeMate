import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Progress bar indicating the percentage of recipe ingredients
/// available in the user's fridge.
/// Aligned with `docs/design/RecipeMate.html`:
/// - Track height 10px, radius 99px, background `#DDEBCB`
/// - Active fill radius 99px, background `#527C43`
/// - Percentage: Poppins 18px bold `#527C43` (or formatted label)
class MatchBar extends StatelessWidget {
  const MatchBar({
    required this.percentage,
    super.key,
    this.showLabel = true,
    this.height = 10.0,
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
    final colors = Theme.of(context).colorScheme;
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
                  style: GoogleFonts.poppins(
                    color: colors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.check_circle_rounded, size: 16, color: colors.primary),
            ],
          ),
          const SizedBox(height: 6),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: _clampedFraction,
            minHeight: height,
            backgroundColor: colors.primaryContainer,
            valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
          ),
        ),
      ],
    );
  }
}
