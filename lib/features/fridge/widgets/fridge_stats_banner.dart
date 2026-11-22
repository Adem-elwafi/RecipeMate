import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipemate/core/theme/app_colors.dart';

/// Green hero banner displaying fridge totals, expiring items, and recipe matches.
class FridgeStatsBanner extends StatelessWidget {
  const FridgeStatsBanner({
    required this.totalCount,
    required this.expiringSoonCount,
    required this.possibleRecipesCount,
    super.key,
  });

  final int totalCount;
  final int expiringSoonCount;
  final int possibleRecipesCount;

  @override
  Widget build(BuildContext context) {
    final dividerColor = AppColors.softGreen.withValues(alpha: 0.3);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _StatColumn(
                value: '$totalCount',
                label: 'ingrédients',
                valueColor: Colors.white,
              ),
            ),
            Container(width: 1, color: dividerColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 14),
                child: _StatColumn(
                  value: '$expiringSoonCount',
                  label: 'expirent bientôt',
                  valueColor: AppColors.orangeSoft,
                ),
              ),
            ),
            Container(width: 1, color: dividerColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 14),
                child: _StatColumn(
                  value: '$possibleRecipesCount',
                  label: 'recettes possibles',
                  valueColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.15,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 1.25,
            color: AppColors.softGreen,
          ),
        ),
      ],
    );
  }
}
