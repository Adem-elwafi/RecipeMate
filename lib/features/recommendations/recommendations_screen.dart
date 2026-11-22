import 'package:flutter/material.dart';
import 'package:recipemate/shared/widgets/feature_placeholder.dart';
import 'package:recipemate/shared/widgets/recipemate_app_bar.dart';

/// Screen placeholder for Recettes IA.
/// Owned by Adem (Phase 2).
class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Recettes IA',
      owner: 'Adem (Phase 2)',
      icon: Icons.auto_awesome_outlined,
      description: 'Suggestions intelligentes basées sur les ingrédients du frigo et score de correspondance.',
      // Point C : en-tête commun aux onglets racines.
      appBar: RecipeMateAppBar(),
    );
  }
}
