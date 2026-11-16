import 'package:flutter/material.dart';
import 'package:recipemate/shared/widgets/feature_placeholder.dart';

/// Screen placeholder for Connexion & Inscription.
/// Owned by Farah.
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Connexion & Inscription',
      owner: 'Farah',
      icon: Icons.login_outlined,
      description: 'Authentification Firebase Auth & Google Sign-In.',
      showBackButton: true,
    );
  }
}
