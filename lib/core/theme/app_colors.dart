import 'package:flutter/material.dart';

/// Design tokens for RecipeMate colors.
///
/// Les couleurs ci-dessous sont celles de la palette de référence : aucun
/// code HEX approximatif ni couleur Material par défaut n'est utilisé pour les
/// écrans clairs. Les seules valeurs dérivées sont des transparences de ces
/// mêmes couleurs (ombres, bordures) ou les fonds du thème sombre, conservé
/// pour les écrans autres que l'authentification.
abstract final class AppColors {
  // Palette de référence (codes HEX imposés)
  static const Color primary = Color(0xFF527C43);
  static const Color sage = Color(0xFFA8C982);
  static const Color softGreen = Color(0xFFDDEBCB);
  static const Color cream = Color(0xFFF5F2E9);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF292D27);
  static const Color greyIcon = Color(0xFF858B7D);
  static const Color textSecondary = Color(0xFF5E6457);
  static const Color orangeAccent = Color(0xFFE9A65A);
  static const Color orangeText = Color(0xFF9A5A12);
  static const Color error = Color(0xFFB3261E);

  // Alias sémantiques : ils pointent tous vers la palette exacte.
  static const Color tonalGreenText = textPrimary;
  static const Color primaryDark = primary;
  static const Color primaryLight = primary;
  static const Color softGreenLight = softGreen;
  static const Color background = cream;
  static const Color scaffoldBackground = cream;
  static const Color surface = card;
  static const Color textMuted = greyIcon;
  static const Color iconGrey = greyIcon;
  static const Color success = primary;
  static const Color successContainer = softGreen;
  static const Color orangeContainer = cream;
  static const Color favoriteIcon = orangeAccent;
  static const Color errorContainer = card;
  static const Color info = textSecondary;
  static const Color infoContainer = cream;

  // Bordures : gris de la palette ou variante très claire autorisée.
  static const Color border = Color(0x1F292D27); // rgba(41, 45, 39, 0.12)
  static const Color borderSubtle = Color(0x1F858B7D); // gris #858B7D à 12 %

  // Ombres douces des cartes (transparences des couleurs de la palette).
  static const Color cardShadow = Color(0x14292D27); // rgba(41, 45, 39, 0.08)
  static const Color primaryShadow = Color(
    0x28527C43,
  ); // rgba(82, 124, 67, 0.16)

  // Nutri-Score : nuances de la palette de référence, sans couleur approximative.
  static const Color nutriScoreA = primary;
  static const Color nutriScoreB = sage;
  static const Color nutriScoreC = orangeAccent;
  static const Color nutriScoreD = orangeText;
  static const Color nutriScoreE = error;

  // Nutrition & Macros
  static const Color macroCalories = orangeAccent;
  static const Color macroProtein = sage;
  static const Color macroCarbs = orangeAccent;
  static const Color macroFat = greyIcon;

  // Thème sombre : conservé pour les écrans autres que l'authentification.
  static const Color darkBackground = Color(0xFF1C1F1A);
  static const Color darkBg = Color(0xFF1C1F1A);
  static const Color darkCard = Color(0xFF262A23);
}
