import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Point B : AppBar standard des pages secondaires (toutes sauf les cinq
/// onglets racines). Elle garantit une flèche de retour et un titre visible.
///
/// Le retour utilise `context.pop()` quand la pile le permet. En secours, on
/// revient à l'onglet Profil pour ne jamais laisser l'utilisateur bloqué.
/// Aucun `pushReplacement`/`pushAndRemoveUntil` n'est utilisé ici.
class SecondaryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SecondaryAppBar({required this.title, super.key, this.onBack});

  final String title;

  /// Permet à un écran interne (ex. détail d'une collection) de définir son
  /// propre retour, et aux tests de vérifier le tap sans GoRouter.
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      leading: IconButton(
        tooltip: 'Retour',
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed:
            onBack ??
            () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/profile');
              }
            },
      ),
    );
  }
}
