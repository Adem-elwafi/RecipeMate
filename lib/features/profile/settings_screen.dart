import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:recipemate/core/providers/app_providers.dart';
import 'package:recipemate/core/providers/theme_provider.dart';
import 'package:recipemate/core/services/auth_error_mapper.dart';
import 'package:recipemate/core/services/preferences_service.dart';
import 'package:recipemate/core/theme/app_text_styles.dart';
import 'package:recipemate/shared/widgets/app_snack_bar.dart';
import 'package:recipemate/shared/widgets/secondary_app_bar.dart';

/// Page Paramètres distincte du Profil (point 8).
///
/// Regroupe l'apparence, la sécurité et le mot de passe, les rappels, la
/// déconnexion et la suppression de compte.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer mon compte ?'),
        content: const Text(
          'Cette action est définitive : votre compte, votre profil, vos '
          'favoris, vos collections et vos recettes seront supprimés. '
          'Firebase peut demander une reconnexion récente pour confirmer.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) {
      return;
    }
    try {
      // Le compte Auth est supprimé en premier : si Firebase refuse (par
      // exemple suite à une connexion trop ancienne), rien n'est perdu.
      await ref.read(authServiceProvider).deleteAccount();
    } on Object catch (error) {
      if (context.mounted) {
        AppSnackBar.show(context, AuthErrorMapper.message(error));
      }
      return;
    }

    try {
      await ref.read(firestoreServiceProvider).deleteUserData(uid);
    } on Object {
      // Les documents orphelins ne bloquent pas la suppression utilisateur.
    }

    await PreferencesService.resetOnboarding();
    if (context.mounted) {
      context.go('/auth');
    }
  }

  /// Point 8 : permet de changer le mot de passe via Firebase Auth.
  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (user == null || user.email == null) {
      _showMessage(
        context,
        'Connectez-vous avec un e-mail pour modifier votre mot de passe.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Modifier le mot de passe'),
        content: const Text(
          'Un e-mail de réinitialisation va être envoyé à votre adresse '
          'actuelle. Suivez le lien reçu pour choisir un nouveau mot de passe.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Envoyer le lien'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      if (context.mounted) {
        _showMessage(
          context,
          'Un e-mail de réinitialisation a été envoyé à ${user.email}.',
        );
      }
    } on Object catch (error) {
      if (context.mounted) {
        _showMessage(context, AuthErrorMapper.message(error));
      }
    }
  }

  void _showMessage(BuildContext context, String message) {
    // Point A4 : style unique, durée courte, au-dessus de la navigation.
    AppSnackBar.show(context, message);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      // Point B : page secondaire, flèche retour vers le Profil.
      appBar: const SecondaryAppBar(title: 'Paramètres'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          // Point A7 : chaque section porte un libellé visible et une courte
          // description, avec des couleurs issues du thème (clair et sombre).
          const _SectionLabel(
            title: 'Compte',
            description: 'Vos identifiants et vos informations personnelles.',
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Informations du compte'),
              subtitle: Text(user?.email ?? 'Non connecté'),
              onTap: () => context.go('/profile'),
            ),
          ),
          const SizedBox(height: 16),
          const _SectionLabel(
            title: 'Apparence',
            description:
                'Choisissez le thème utilisé dans toute l’application.',
          ),
          // Point A7 : RadioGroup rend les trois choix lisibles dans les deux
          // thèmes et évite les API dépréciées groupValue/onChanged.
          RadioGroup<ThemeMode>(
            groupValue: themeMode,
            onChanged: (mode) {
              if (mode != null) {
                ref.read(themeModeProvider.notifier).setThemeMode(mode);
              }
            },
            child: const Card(
              child: Column(
                children: <Widget>[
                  RadioListTile<ThemeMode>(
                    title: Text('Mode clair'),
                    value: ThemeMode.light,
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text('Mode sombre'),
                    value: ThemeMode.dark,
                  ),
                  RadioListTile<ThemeMode>(
                    title: Text('Suivre le système'),
                    value: ThemeMode.system,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _SectionLabel(
            title: 'Sécurité et mot de passe',
            description: 'Modifiez votre mot de passe et gérez vos rappels.',
          ),
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.lock_outline, color: colors.primary),
                  title: const Text('Modifier le mot de passe'),
                  subtitle: const Text('Envoi d’un lien de réinitialisation'),
                  onTap: () => _changePassword(context, ref),
                ),
                ListTile(
                  leading: Icon(Icons.alarm_outlined, color: colors.primary),
                  title: const Text('Mes rappels'),
                  subtitle: const Text('Repas et péremptions'),
                  // Point B : on empile la page pour pouvoir revenir ici.
                  onTap: () => context.push('/reminders'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SectionLabel(
            title: 'Préférences',
            description: 'Langue de l’interface et parcours d’accueil.',
          ),
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.language_outlined, color: colors.primary),
                  title: const Text('Langue'),
                  subtitle: const Text('Français'),
                  onTap: () => _showMessage(
                    context,
                    'L’interface est actuellement en français.',
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.replay_outlined, color: colors.primary),
                  title: const Text('Revoir l’onboarding'),
                  onTap: () async {
                    await PreferencesService.resetOnboarding();
                    if (context.mounted) {
                      context.go('/onboarding');
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SectionLabel(
            title: 'Session',
            description:
                'Se déconnecter ou supprimer définitivement le compte.',
          ),
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.logout, color: colors.error),
                  title: const Text('Se déconnecter'),
                  onTap: () async {
                    await ref.read(authServiceProvider).signOut();
                    if (context.mounted) {
                      context.go('/auth');
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete_forever, color: colors.error),
                  title: const Text('Supprimer mon compte'),
                  onTap: () => _confirmDelete(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'RecipeMate — Cuisinez malin, gaspillez moins.',
              style: AppTextStyles.caption.copyWith(
                color: colors.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Point A7 : libellé de section et description courte, lisibles en mode clair
/// comme en mode sombre grâce aux couleurs du [ColorScheme] courant.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: AppTextStyles.sectionHeader.copyWith(
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: AppTextStyles.caption.copyWith(
              color: colors.onSurface.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }
}
