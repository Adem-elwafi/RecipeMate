import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography tokens for RecipeMate directly aligned with `docs/design/RecipeMate.html`.
/// Poppins for headings & display titles.
/// Inter for body, captions, labels, and buttons.
///
/// Les couleurs de texte ne sont PAS fixées ici : elles viennent du
/// `ColorScheme` courant. C'est ce qui permet au thème sombre de s'appliquer à
/// toute l'application au lieu de seulement la page Paramètres. Les rares
/// couleurs sémantiques (erreur, badge sur fond coloré) sont appliquées par le
/// widget qui connaît son contexte.
abstract final class AppTextStyles {
  // Headings & Titles (Poppins)
  static TextStyle get display => GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.02 * 32,
    height: 1.15,
  );

  static TextStyle get titleLarge => GoogleFonts.poppins(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.02 * 26,
  );

  static TextStyle get title => GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static TextStyle get subtitle => GoogleFonts.poppins(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static TextStyle get sectionHeader => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  // Body & Content (Inter)
  static TextStyle get body =>
      GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, height: 1.5);

  static TextStyle get bodyMedium =>
      GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, height: 1.5);

  static TextStyle get bodySecondary =>
      GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, height: 1.5);

  static TextStyle get caption =>
      GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, height: 1.4);

  static TextStyle get captionMedium =>
      GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, height: 1.4);

  // Buttons & Interactive
  static TextStyle get button =>
      GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, height: 1.2);

  static TextStyle get buttonSmall =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, height: 1.2);

  static TextStyle get tonalButton =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, height: 1.2);

  // Labels & Tags
  static TextStyle get label => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.08 * 12,
  );

  static TextStyle get badge =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, height: 1.2);
}
