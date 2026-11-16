import 'package:flutter/material.dart';
import 'package:recipemate/shared/widgets/feature_placeholder.dart';

/// Screen placeholder for Détail de la recette.
/// Owned by Molka.
class RecipeDetailsScreen extends StatelessWidget {
  const RecipeDetailsScreen({this.recipeId, super.key});

  final String? recipeId;

  @override
  Widget build(BuildContext context) {
    return FeaturePlaceholder(
      title: 'Détail de la recette',
      owner: 'Molka',
      icon: Icons.restaurant_outlined,
      description: 'Fiche complète, ingrédients, calcul des portions, étapes de préparation.',
      extraDetail: recipeId != null ? 'Recette ID : $recipeId' : null,
      showBackButton: true,
    );
  }
}
