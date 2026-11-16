import 'package:flutter/material.dart';
import 'package:recipemate/shared/widgets/feature_placeholder.dart';

/// Screen placeholder for Mes Collections.
/// Owned by Farah.
class CollectionsScreen extends StatelessWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Mes Collections',
      owner: 'Farah',
      icon: Icons.bookmark_outline,
      description: 'Dossiers personnalisés de recettes.',
      showBackButton: true,
    );
  }
}
