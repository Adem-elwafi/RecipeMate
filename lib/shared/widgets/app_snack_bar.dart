import 'package:flutter/material.dart';
import 'package:recipemate/core/theme/app_text_styles.dart';

/// Point A4 : un seul style de message éphémère pour toute l'application.
///
/// Le SnackBar Material standard est utilisé (pas de widget maison), avec le
/// thème courant, une durée courte et une marge qui le place au-dessus de la
/// barre de navigation pour éviter tout chevauchement sur téléphone.
abstract final class AppSnackBar {
  static const Duration defaultDuration = Duration(seconds: 3);

  static void show(
    BuildContext context,
    String message, {
    Duration duration = defaultDuration,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final colors = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AppTextStyles.bodySecondary.copyWith(
              color: colors.onPrimary,
            ),
          ),
          backgroundColor: colors.primary,
          duration: duration,
          behavior: SnackBarBehavior.floating,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          // 56 px de hauteur de navigation + 16 px de marge + safe area.
          margin: EdgeInsets.fromLTRB(16, 16, 16, 88 + bottomPadding),
          action: SnackBarAction(
            label: 'Fermer',
            textColor: colors.onPrimary,
            onPressed: messenger.hideCurrentSnackBar,
          ),
        ),
      );
  }
}
