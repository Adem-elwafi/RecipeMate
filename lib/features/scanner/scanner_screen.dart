import 'package:flutter/material.dart';
import 'package:recipemate/shared/widgets/feature_placeholder.dart';

/// Screen placeholder for Scanner code-barres.
/// Owned by Adem (Phase 2).
class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Scanner code-barres',
      owner: 'Adem (Phase 2)',
      icon: Icons.qr_code_scanner_outlined,
      description:
          'Scanner caméra mobile_scanner avec détection et saisie manuelle.',
      showBackButton: true,
    );
  }
}
