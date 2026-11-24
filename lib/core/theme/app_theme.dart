import 'package:flutter/material.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/core/theme/app_text_styles.dart';

/// Central Material 3 theme configuration for RecipeMate.
/// 100% aligned with `docs/design/RecipeMate.html`.
abstract final class AppTheme {
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.card,
      primaryContainer: AppColors.softGreen,
      onPrimaryContainer: AppColors.textPrimary,
      secondary: AppColors.sage,
      onSecondary: AppColors.textPrimary,
      secondaryContainer: AppColors.softGreen,
      onSecondaryContainer: AppColors.textPrimary,
      tertiary: AppColors.orangeAccent,
      onTertiary: AppColors.card,
      tertiaryContainer: AppColors.cream,
      onTertiaryContainer: AppColors.orangeText,
      error: AppColors.error,
      onError: AppColors.card,
      errorContainer: AppColors.card,
      onErrorContainer: AppColors.error,
      surface: AppColors.card,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      surfaceContainerHighest: AppColors.cream,
      outline: AppColors.border,
      outlineVariant: AppColors.borderSubtle,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.cream,
      fontFamily: 'Inter',
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.title,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.card,
        elevation: 2,
        shadowColor: AppColors.cardShadow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.card,
          elevation: 1,
          shadowColor: AppColors.primaryShadow,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(0, 52),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: AppTextStyles.button.copyWith(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.buttonSmall.copyWith(
            color: AppColors.primary,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      switchTheme: _switchTheme(colorScheme),
      checkboxTheme: _checkboxTheme(colorScheme),
      radioTheme: _radioTheme(colorScheme),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 8,
        indicatorColor: colorScheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.onPrimaryContainer);
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.captionMedium.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTextStyles.caption.copyWith(
            color: colorScheme.onSurfaceVariant,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Dark variant using the brand's nature palette already defined in
  /// AppColors. Selected by themeModeProvider and restored at startup.
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: AppColors.card,
      primaryContainer: AppColors.primary,
      onPrimaryContainer: AppColors.card,
      secondary: AppColors.sage,
      onSecondary: AppColors.textPrimary,
      secondaryContainer: AppColors.darkCard,
      onSecondaryContainer: AppColors.softGreen,
      tertiary: AppColors.orangeAccent,
      onTertiary: AppColors.textPrimary,
      tertiaryContainer: AppColors.cream,
      onTertiaryContainer: AppColors.orangeText,
      error: AppColors.error,
      onError: AppColors.card,
      errorContainer: AppColors.card,
      onErrorContainer: AppColors.error,
      surface: AppColors.darkCard,
      onSurface: AppColors.card,
      onSurfaceVariant: AppColors.textMuted,
      surfaceContainerHighest: AppColors.darkBackground,
      outline: AppColors.textSecondary,
      outlineVariant: AppColors.textMuted,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      fontFamily: 'Inter',
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.title.copyWith(color: AppColors.card),
        iconTheme: const IconThemeData(color: AppColors.card),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 2,
        shadowColor: AppColors.cardShadow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          side: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.35),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.card,
          elevation: 1,
          shadowColor: AppColors.primaryShadow,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.softGreen,
          minimumSize: const Size(0, 52),
          side: const BorderSide(color: AppColors.sage, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: AppTextStyles.button.copyWith(color: AppColors.softGreen),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.softGreen,
          textStyle: AppTextStyles.buttonSmall.copyWith(
            color: AppColors.softGreen,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.sage, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      switchTheme: _switchTheme(colorScheme),
      checkboxTheme: _checkboxTheme(colorScheme),
      radioTheme: _radioTheme(colorScheme),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 8,
        indicatorColor: colorScheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.onPrimaryContainer);
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.captionMedium.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTextStyles.caption.copyWith(
            color: colorScheme.onSurfaceVariant,
          );
        }),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.textSecondary.withValues(alpha: 0.35),
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Couleurs des Switch, avec états sélectionné/désactivé issus du thème.
  static SwitchThemeData _switchTheme(ColorScheme colors) {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.disabled)) {
          return colors.onSurface.withValues(alpha: 0.38);
        }
        if (states.contains(WidgetState.selected)) {
          return colors.primary;
        }
        return colors.surface;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.disabled)) {
          return colors.onSurface.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.selected)) {
          return colors.primaryContainer;
        }
        return colors.outlineVariant;
      }),
      overlayColor: WidgetStateProperty.all(
        colors.primary.withValues(alpha: 0.08),
      ),
    );
  }

  /// Couleurs des cases à cocher (collections, recettes, onboarding).
  static CheckboxThemeData _checkboxTheme(ColorScheme colors) {
    return CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.disabled)) {
          return colors.onSurface.withValues(alpha: 0.3);
        }
        if (states.contains(WidgetState.selected)) {
          return colors.primary;
        }
        return colors.surface;
      }),
      checkColor: WidgetStateProperty.all(AppColors.card),
      side: const BorderSide(color: AppColors.greyIcon, width: 1.5),
      overlayColor: WidgetStateProperty.all(
        colors.primary.withValues(alpha: 0.08),
      ),
    );
  }

  /// Couleurs des boutons radio (sélecteur de thème clair/sombre/système).
  static RadioThemeData _radioTheme(ColorScheme colors) {
    return RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.disabled)) {
          return colors.onSurface.withValues(alpha: 0.3);
        }
        return colors.primary;
      }),
      overlayColor: WidgetStateProperty.all(
        colors.primary.withValues(alpha: 0.08),
      ),
    );
  }
}
