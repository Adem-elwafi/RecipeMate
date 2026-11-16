import 'package:flutter/material.dart';
import 'package:recipemate/shared/widgets/feature_placeholder.dart';

/// Screen placeholder for Onboarding.
/// Owned by Farah.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Onboarding',
      owner: 'Farah',
      icon: Icons.view_carousel_outlined,
      description: 'Carrousel de bienvenue en 3 étapes.',
      showBackButton: true,
    );
  }
}
