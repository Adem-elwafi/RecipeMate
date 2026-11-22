import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:recipemate/core/config/app_assets.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/core/theme/app_text_styles.dart';

/// Point C : en-tête commun aux cinq onglets racines de la navigation basse.
///
/// Affiche le vrai logo RecipeMate (SVG), le nom de l'application
/// et, à droite, les raccourcis Profil et Paramètres. Sur la page Profil on
/// masque le raccourci Profil pour éviter une redondance.
class RecipeMateAppBar extends StatelessWidget implements PreferredSizeWidget {
  const RecipeMateAppBar({
    super.key,
    this.showProfile = true,
    this.onProfileTap,
    this.onSettingsTap,
  });

  /// Mettre à `false` sur la page Profil, où l'icône serait inutile.
  final bool showProfile;

  /// Callbacks optionnels : facilitent les tests de widget et permettent de
  /// remplacer la navigation par un comportement spécifique si besoin.
  final VoidCallback? onProfileTap;
  final VoidCallback? onSettingsTap;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AppBar(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const RecipeMateLogo(size: 30),
          const SizedBox(width: 10),
          Text(
            'RecipeMate',
            style: AppTextStyles.subtitle.copyWith(color: colors.onSurface),
          ),
        ],
      ),
      actions: <Widget>[
        if (showProfile)
          IconButton(
            tooltip: 'Profil',
            icon: Icon(Icons.person_outline, color: colors.onSurface),
            onPressed: onProfileTap ?? () => context.go('/profile'),
          ),
        IconButton(
          tooltip: 'Paramètres',
          icon: Icon(Icons.settings_outlined, color: colors.onSurface),
          onPressed: onSettingsTap ?? () => context.push('/settings'),
        ),
      ],
    );
  }
}

/// Logo unique de l'application.
///
/// Le chemin du SVG est centralisé dans `app_assets.dart` : aucun écran ne
/// référence directement le fichier. Le fond crème garde le mark lisible en
/// mode sombre, où la surface de l'en-tête est sombre.
class RecipeMateLogo extends StatelessWidget {
  const RecipeMateLogo({super.key, this.size = 30});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SvgPicture.asset(
        appLogoAssetPath,
        fit: BoxFit.contain,
        semanticsLabel: 'Logo RecipeMate',
      ),
    );
  }
}
