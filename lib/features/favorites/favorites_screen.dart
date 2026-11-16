import 'package:flutter/material.dart';
import 'package:recipemate/shared/widgets/feature_placeholder.dart';

/// Screen placeholder for Mes Favoris.
/// Owned by Farah.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Mes Favoris',
      owner: 'Farah',
      icon: Icons.favorite_outline,
      description: 'Liste des recettes enregistrées en favoris.',
      showBackButton: true,
    );
  }
}
