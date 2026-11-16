import 'package:flutter/material.dart';
import 'package:recipemate/shared/widgets/feature_placeholder.dart';

/// Screen placeholder for Mon Profil & Réglages.
/// Owned by Farah.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Mon Profil & Réglages',
      owner: 'Farah',
      icon: Icons.person_outline,
      description: 'Objectifs nutritionnels, régimes alimentaires, allergies et préférences.',
    );
  }
}
