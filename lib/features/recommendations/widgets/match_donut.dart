import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipemate/core/theme/app_colors.dart';

/// Circular 78×78 match percentage donut matching `07 · Recettes IA`.
class MatchDonut extends StatelessWidget {
  const MatchDonut({required this.percentage, super.key});

  final int percentage;

  @override
  Widget build(BuildContext context) {
    final clamped = percentage.clamp(0, 100);

    return Semantics(
      image: true,
      label: '$clamped% de correspondance',
      child: Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size(78, 78),
              painter: _MatchDonutPainter(percentage: clamped),
            ),
            Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$clamped%',
                    style: GoogleFonts.poppins(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      color: AppColors.tonalGreenText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'MATCH',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      height: 1,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchDonutPainter extends CustomPainter {
  const _MatchDonutPainter({required this.percentage});

  final int percentage;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 8.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = AppColors.softGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    if (percentage <= 0) {
      return;
    }

    final activePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final sweepAngle = 2 * math.pi * (percentage / 100.0);
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, activePaint);
  }

  @override
  bool shouldRepaint(covariant _MatchDonutPainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}
