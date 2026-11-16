import 'package:flutter/material.dart';
import 'package:recipemate/shared/widgets/feature_placeholder.dart';

/// Screen placeholder for Explorer.
/// Owned by Molka.
class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Explorer',
      owner: 'Molka',
      icon: Icons.search_outlined,
      description:
          'Recherche de recettes, filtres par catégorie et par régime, tri.',
    );
  }
}
