import 'package:flutter/material.dart';
import 'package:recipemate/shared/widgets/feature_placeholder.dart';

/// Screen placeholder for Mon Frigo.
/// Owned by Adem (Phase 2).
class FridgeScreen extends StatelessWidget {
  const FridgeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Mon Frigo',
      owner: 'Adem (Phase 2)',
      icon: Icons.kitchen_outlined,
      description: 'Gestion des ingrédients, tri par péremption, indicateur anti-gaspillage.',
    );
  }
}
