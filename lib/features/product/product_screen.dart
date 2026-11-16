import 'package:flutter/material.dart';
import 'package:recipemate/shared/widgets/feature_placeholder.dart';

/// Screen placeholder for Fiche Produit.
/// Owned by Adem (Phase 2).
class ProductScreen extends StatelessWidget {
  const ProductScreen({this.barcode, super.key});

  final String? barcode;

  @override
  Widget build(BuildContext context) {
    return FeaturePlaceholder(
      title: 'Fiche Produit',
      owner: 'Adem (Phase 2)',
      icon: Icons.inventory_2_outlined,
      description:
          'Détails OpenFoodFacts, Nutri-Score et ajout direct au frigo.',
      extraDetail: barcode != null ? 'Code-barres : $barcode' : null,
      showBackButton: true,
    );
  }
}
