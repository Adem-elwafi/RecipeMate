import 'package:flutter/material.dart';
import 'package:recipemate/shared/widgets/feature_placeholder.dart';

/// Screen placeholder for Accueil (Home).
/// Owned by Molka.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Accueil',
      owner: 'Molka',
      icon: Icons.home_outlined,
      description: 'Tableau de bord, suivi des macros, recettes rapides et alerte anti-gaspillage.',
    );
  }
}
