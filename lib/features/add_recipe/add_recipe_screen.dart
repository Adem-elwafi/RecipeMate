import 'package:flutter/material.dart';
import 'package:recipemate/shared/widgets/feature_placeholder.dart';

/// Screen placeholder for Ajouter une recette.
/// Owned by Farah.
class AddRecipeScreen extends StatelessWidget {
  const AddRecipeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Ajouter une recette',
      owner: 'Farah',
      icon: Icons.add_circle_outline,
      description: 'Formulaire de création de recette personnalisée avec ingrédients et étapes.',
      showBackButton: true,
    );
  }
}
