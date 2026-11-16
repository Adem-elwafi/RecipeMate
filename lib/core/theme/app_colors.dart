import 'package:flutter/material.dart';

/// Design tokens for RecipeMate colors based on Material 3 specifications.
/// Extracted directly from `docs/design/RecipeMate.html`.
abstract final class AppColors {
  // Brand colors
  static const Color primary = Color(0xFF527C43);
  static const Color sage = Color(0xFFA8C982);
  static const Color softGreen = Color(0xFFDDEBCB);
  static const Color tonalGreenText = Color(0xFF3F6233);
  static const Color primaryDark = Color(0xFF3F6233);
  static const Color primaryLight = Color(0xFF6A9B57);
  static const Color softGreenLight = Color(0xFFEFF6E6);

  // Surface & Background
  static const Color cream = Color(0xFFF5F2E9);
  static const Color background = Color(0xFFF5F2E9);
  static const Color scaffoldBackground = Color(0xFFF5F2E9);
  static const Color card = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color darkBackground = Color(0xFF1C1F1A);
  static const Color darkBg = Color(0xFF1C1F1A);
  static const Color darkCard = Color(0xFF262A23);

  // Typography & Neutral
  static const Color textPrimary = Color(0xFF292D27);
  static const Color textSecondary = Color(0xFF5E6457);
  static const Color textMuted = Color(0xFF858B7D);
  static const Color greyIcon = Color(0xFF858B7D);
  static const Color iconGrey = Color(0xFF858B7D);
  static const Color border = Color(0x1F292D27); // rgba(41, 45, 39, 0.12)
  static const Color borderSubtle = Color(0xFFEEE9DD);

  // Accents & Alerts (Anti-gaspi, Expiration)
  static const Color orangeAccent = Color(0xFFE9A65A);
  static const Color orangeText = Color(0xFF9A5A12);
  static const Color orangeContainer = Color(0xFFFCEFDF);

  // Semantic Status
  static const Color error = Color(0xFFB3261E);
  static const Color errorContainer = Color(0xFFFBEDEB);
  static const Color success = Color(0xFF527C43);
  static const Color successContainer = Color(0xFFDDEBCB);
  static const Color info = Color(0xFF3D7EAA);
  static const Color infoContainer = Color(0xFFE5F1F9);

  // Nutri-Score colors
  static const Color nutriScoreA = Color(0xFF038141);
  static const Color nutriScoreB = Color(0xFF85BB2F);
  static const Color nutriScoreC = Color(0xFFFECB02);
  static const Color nutriScoreD = Color(0xFFEE8100);
  static const Color nutriScoreE = Color(0xFFE63E11);

  // Nutrition & Macros
  static const Color macroCalories = Color(0xFFE9A65A);
  static const Color macroProtein = Color(0xFFA8C982);
  static const Color macroCarbs = Color(0xFFE9A65A);
  static const Color macroFat = Color(0xFF858B7D);
}
