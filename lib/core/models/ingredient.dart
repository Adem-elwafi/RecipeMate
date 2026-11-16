import 'package:flutter/foundation.dart';

/// Food category for ingredients.
enum IngredientCategory {
  vegetables('Légumes'),
  fruits('Fruits'),
  dairy('Produits laitiers'),
  meat('Viandes & Volailles'),
  fish('Poissons & Fruits de mer'),
  grains('Céréales & Légumineuses'),
  spices('Épices & Condiments'),
  bakery('Boulangerie'),
  other('Autre');

  const IngredientCategory(this.label);
  final String label;
}

/// Base food ingredient definition.
@immutable
class Ingredient {
  const Ingredient({
    required this.id,
    required this.name,
    required this.category,
    this.defaultUnit = 'g',
    this.imageUrl,
  });

  final String id;
  final String name;
  final IngredientCategory category;
  final String defaultUnit;
  final String? imageUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Ingredient && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// An ingredient with a specific quantity and unit required for a recipe.
@immutable
class RecipeIngredient {
  const RecipeIngredient({
    required this.ingredient,
    required this.quantity,
    required this.unit,
    this.notes,
  });

  final Ingredient ingredient;
  final double quantity;
  final String unit;
  final String? notes;

  String get displayText {
    final cleanQty = quantity % 1 == 0
        ? quantity.toInt().toString()
        : quantity.toStringAsFixed(1);
    if (unit.isEmpty) {
      return '$cleanQty ${ingredient.name}';
    }
    return '$cleanQty $unit ${ingredient.name}';
  }
}
