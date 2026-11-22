import 'package:flutter/material.dart';
import 'package:recipemate/shared/widgets/feature_placeholder.dart';
import 'package:recipemate/shared/widgets/secondary_app_bar.dart';

/// Screen placeholder for Mode cuisine.
/// Owned by Molka.
class CookingModeScreen extends StatelessWidget {
  const CookingModeScreen({this.recipeId, super.key});

  final String? recipeId;

  @override
  Widget build(BuildContext context) {
    return FeaturePlaceholder(
      title: 'Mode cuisine',
      owner: 'Molka',
      icon: Icons.timer_outlined,
      description: 'Mode pas-à-pas immersif avec minuteurs par étape.',
      extraDetail: recipeId != null ? 'Recette ID : $recipeId' : null,
      // Point B : page secondaire avec flèche retour et titre explicite.
      appBar: const SecondaryAppBar(title: 'Mode cuisine'),
    );
  }
}
