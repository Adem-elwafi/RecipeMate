import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipemate/core/data/mock_data.dart';
import 'package:recipemate/core/models/fridge_item.dart';
import 'package:recipemate/core/models/ingredient.dart';
import 'package:recipemate/core/models/recipe.dart';

/// Category filter tabs displayed on the Mon Frigo screen.
enum FridgeCategoryFilter {
  all('Tout'),
  vegetables('Légumes'),
  fruits('Fruits'),
  meatFish('Viandes & poissons'),
  dairy('Produits laitiers'),
  other('Autres');

  const FridgeCategoryFilter(this.label);

  final String label;
}

/// Maps an [IngredientCategory] to its corresponding [FridgeCategoryFilter].
FridgeCategoryFilter mapIngredientCategoryToFilter(IngredientCategory cat) {
  return switch (cat) {
    IngredientCategory.vegetables => FridgeCategoryFilter.vegetables,
    IngredientCategory.fruits => FridgeCategoryFilter.fruits,
    IngredientCategory.meat ||
    IngredientCategory.fish => FridgeCategoryFilter.meatFish,
    IngredientCategory.dairy => FridgeCategoryFilter.dairy,
    IngredientCategory.grains ||
    IngredientCategory.spices ||
    IngredientCategory.bakery ||
    IngredientCategory.other => FridgeCategoryFilter.other,
  };
}

/// Supported units in the fridge quick-add and edit controls.
const List<String> kFridgeUnitOptions = ['pièce', 'g', 'ml', 'boîte'];

/// Common ingredient suggestions for quick-adding to the fridge.
const List<Ingredient> kFridgeIngredientSuggestions = [
  Ingredient(
    id: 'sug_zucchini',
    name: 'Courgette',
    category: IngredientCategory.vegetables,
    defaultUnit: 'pièce',
  ),
  Ingredient(
    id: 'sug_butternut',
    name: 'Courge butternut',
    category: IngredientCategory.vegetables,
    defaultUnit: 'pièce',
  ),
  Ingredient(
    id: 'sug_tomatoes',
    name: 'Tomates',
    category: IngredientCategory.vegetables,
    defaultUnit: 'pièce',
  ),
  Ingredient(
    id: 'ing_cucumber',
    name: 'Concombre',
    category: IngredientCategory.vegetables,
    defaultUnit: 'pièce',
  ),
  Ingredient(
    id: 'ing_spinach',
    name: 'Épinards frais',
    category: IngredientCategory.vegetables,
  ),
  Ingredient(
    id: 'ing_carrots',
    name: 'Carottes',
    category: IngredientCategory.vegetables,
    defaultUnit: 'pièce',
  ),
  Ingredient(
    id: 'ing_lemons',
    name: 'Citrons',
    category: IngredientCategory.fruits,
    defaultUnit: 'pièce',
  ),
  Ingredient(
    id: 'ing_avocado',
    name: 'Avocat',
    category: IngredientCategory.fruits,
    defaultUnit: 'pièce',
  ),
  Ingredient(
    id: 'ing_chicken',
    name: 'Blanc de poulet',
    category: IngredientCategory.meat,
  ),
  Ingredient(
    id: 'ing_salmon',
    name: 'Pavé de saumon',
    category: IngredientCategory.fish,
  ),
  Ingredient(
    id: 'ing_greek_yogurt',
    name: 'Yaourt grec',
    category: IngredientCategory.dairy,
  ),
  Ingredient(
    id: 'ing_eggs',
    name: 'Œufs',
    category: IngredientCategory.dairy,
    defaultUnit: 'pièce',
  ),
  Ingredient(id: 'ing_feta', name: 'Feta', category: IngredientCategory.dairy),
  Ingredient(
    id: 'sug_bell_pepper',
    name: 'Poivron',
    category: IngredientCategory.vegetables,
    defaultUnit: 'pièce',
  ),
  Ingredient(
    id: 'ing_olive_oil',
    name: "Huile d'olive",
    category: IngredientCategory.spices,
    defaultUnit: 'ml',
  ),
  Ingredient(
    id: 'ing_chickpeas',
    name: 'Pois chiches',
    category: IngredientCategory.grains,
    defaultUnit: 'boîte',
  ),
  Ingredient(
    id: 'ing_rice',
    name: 'Riz basmati',
    category: IngredientCategory.grains,
  ),
  Ingredient(
    id: 'ing_coconut_milk',
    name: 'Lait de coco',
    category: IngredientCategory.other,
    defaultUnit: 'ml',
  ),
  Ingredient(
    id: 'ing_oats',
    name: "Flocons d'avoine",
    category: IngredientCategory.grains,
  ),
  Ingredient(
    id: 'ing_berries',
    name: 'Fruits rouges',
    category: IngredientCategory.fruits,
  ),
];

/// Formats a quantity and unit in French (pluralizing `pièce` and `boîte`).
String formatFridgeQuantity(double quantity, String unit) {
  final qtyText = quantity % 1 == 0
      ? quantity.toInt().toString()
      : quantity.toStringAsFixed(1);

  final normalized = unit.trim();
  if (normalized.isEmpty) {
    return qtyText;
  }

  final displayUnit = switch (normalized) {
    'pièce' when quantity > 1 => 'pièces',
    'boîte' when quantity > 1 => 'boîtes',
    _ => normalized,
  };

  return '$qtyText $displayUnit';
}

/// Computes the count of recipes in [recipes] with at least 50% ingredient match.
int computePossibleRecipesCount(
  List<FridgeItem> fridgeItems,
  List<Recipe> recipes,
) {
  if (fridgeItems.isEmpty || recipes.isEmpty) {
    return 0;
  }

  final fridgeIds = fridgeItems.map((item) => item.ingredient.id).toSet();
  final fridgeNames = fridgeItems
      .map((item) => normalizeIngredientName(item.ingredient.name))
      .where((name) => name.isNotEmpty)
      .toList();

  var count = 0;
  for (final recipe in recipes) {
    if (recipe.ingredients.isEmpty) {
      continue;
    }

    var matched = 0;
    for (final recipeIng in recipe.ingredients) {
      if (fridgeIds.contains(recipeIng.ingredient.id)) {
        matched++;
        continue;
      }

      final targetName = normalizeIngredientName(recipeIng.ingredient.name);
      if (targetName.isEmpty) {
        continue;
      }

      final hasNameMatch = fridgeNames.any(
        (fridgeName) =>
            fridgeName.contains(targetName) || targetName.contains(fridgeName),
      );
      if (hasNameMatch) {
        matched++;
      }
    }

    if (matched / recipe.ingredients.length >= 0.5) {
      count++;
    }
  }

  return count;
}

/// Normalizes French ingredient names for accent-insensitive search & matching.
String normalizeIngredientName(String raw) {
  return raw
      .trim()
      .toLowerCase()
      .replaceAll('œ', 'oe')
      .replaceAll('æ', 'ae')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[àâä]'), 'a')
      .replaceAll(RegExp('[îï]'), 'i')
      .replaceAll(RegExp('[ôö]'), 'o')
      .replaceAll(RegExp('[ùûü]'), 'u')
      .replaceAll('ç', 'c');
}

/// Immutable state for the fridge feature.
@immutable
class FridgeState {
  const FridgeState({
    this.items = const [],
    this.selectedCategory = FridgeCategoryFilter.all,
  });

  final List<FridgeItem> items;
  final FridgeCategoryFilter selectedCategory;

  /// Total number of items currently stored in the fridge.
  int get totalCount => items.length;

  /// Number of items expiring within 3 days (excluding already expired items).
  int get expiringSoonCount => items.where((i) => i.isExpiringSoon).length;

  /// Items matching [selectedCategory], sorted ascending by expiration date
  /// with items lacking an expiration date placed at the end.
  List<FridgeItem> get filteredItems {
    final filtered =
        (selectedCategory == FridgeCategoryFilter.all
              ? List<FridgeItem>.of(items)
              : items
                    .where(
                      (item) =>
                          mapIngredientCategoryToFilter(
                            item.ingredient.category,
                          ) ==
                          selectedCategory,
                    )
                    .toList())
          ..sort((a, b) {
            if (a.hasExpirationDate != b.hasExpirationDate) {
              return a.hasExpirationDate ? -1 : 1;
            }
            if (a.hasExpirationDate && b.hasExpirationDate) {
              final dateCompare = a.expirationDate.compareTo(b.expirationDate);
              if (dateCompare != 0) {
                return dateCompare;
              }
            }
            return a.ingredient.name.toLowerCase().compareTo(
              b.ingredient.name.toLowerCase(),
            );
          });

    return List<FridgeItem>.unmodifiable(filtered);
  }

  /// [filteredItems] grouped by [FridgeCategoryFilter] in enum order
  /// (excluding [FridgeCategoryFilter.all]), omitting empty groups.
  Map<FridgeCategoryFilter, List<FridgeItem>> get groupedItems {
    final sorted = filteredItems;
    final grouped = <FridgeCategoryFilter, List<FridgeItem>>{};

    for (final filter in FridgeCategoryFilter.values) {
      if (filter == FridgeCategoryFilter.all) {
        continue;
      }
      final matching = sorted
          .where(
            (item) =>
                mapIngredientCategoryToFilter(item.ingredient.category) ==
                filter,
          )
          .toList();
      if (matching.isNotEmpty) {
        grouped[filter] = List<FridgeItem>.unmodifiable(matching);
      }
    }

    return Map<FridgeCategoryFilter, List<FridgeItem>>.unmodifiable(grouped);
  }

  FridgeState copyWith({
    List<FridgeItem>? items,
    FridgeCategoryFilter? selectedCategory,
  }) {
    return FridgeState(
      items: items ?? this.items,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

/// Manages fridge inventory, category filtering, and item CRUD actions.
class FridgeNotifier extends Notifier<FridgeState> {
  static const _ingCarrots = Ingredient(
    id: 'ing_carrots',
    name: 'Carottes',
    category: IngredientCategory.vegetables,
    defaultUnit: 'pièce',
  );

  static const _ingLemons = Ingredient(
    id: 'ing_lemons',
    name: 'Citrons',
    category: IngredientCategory.fruits,
    defaultUnit: 'pièce',
  );

  @override
  FridgeState build() {
    final now = DateTime.now();
    DateTime dayOffset(int days) =>
        DateTime(now.year, now.month, now.day + days);
    final noDateFallback = dayOffset(30);

    return FridgeState(
      items: [
        FridgeItem(
          id: 'fi_spinach',
          ingredient: MockData.ingSpinach,
          quantity: 150,
          unit: 'g',
          expirationDate: dayOffset(1),
        ),
        FridgeItem(
          id: 'fi_feta',
          ingredient: MockData.ingFeta,
          quantity: 180,
          unit: 'g',
          expirationDate: dayOffset(2),
        ),
        FridgeItem(
          id: 'fi_avocado',
          ingredient: MockData.ingAvocado,
          quantity: 2,
          unit: 'pièce',
          expirationDate: dayOffset(2),
        ),
        FridgeItem(
          id: 'fi_salmon',
          ingredient: MockData.ingSalmon,
          quantity: 300,
          unit: 'g',
          expirationDate: dayOffset(3),
        ),
        FridgeItem(
          id: 'fi_cherry_tomatoes',
          ingredient: MockData.ingCherryTomatoes,
          quantity: 250,
          unit: 'g',
          expirationDate: dayOffset(3),
        ),
        FridgeItem(
          id: 'fi_chicken',
          ingredient: MockData.ingChicken,
          quantity: 350,
          unit: 'g',
          expirationDate: dayOffset(4),
        ),
        FridgeItem(
          id: 'fi_berries',
          ingredient: MockData.ingBerries,
          quantity: 150,
          unit: 'g',
          expirationDate: dayOffset(4),
        ),
        FridgeItem(
          id: 'fi_cucumber',
          ingredient: MockData.ingCucumber,
          quantity: 1,
          unit: 'pièce',
          expirationDate: dayOffset(5),
        ),
        FridgeItem(
          id: 'fi_greek_yogurt',
          ingredient: MockData.ingGreekYogurt,
          quantity: 400,
          unit: 'g',
          expirationDate: dayOffset(7),
        ),
        FridgeItem(
          id: 'fi_lemons',
          ingredient: _ingLemons,
          quantity: 3,
          unit: 'pièce',
          expirationDate: dayOffset(9),
        ),
        FridgeItem(
          id: 'fi_carrots',
          ingredient: _ingCarrots,
          quantity: 6,
          unit: 'pièce',
          expirationDate: dayOffset(12),
        ),
        FridgeItem(
          id: 'fi_eggs',
          ingredient: MockData.ingEggs,
          quantity: 6,
          unit: 'pièce',
          expirationDate: dayOffset(14),
        ),
        FridgeItem(
          id: 'fi_olive_oil',
          ingredient: MockData.ingOliveOil,
          quantity: 750,
          unit: 'ml',
          expirationDate: noDateFallback,
          hasExpirationDate: false,
        ),
        FridgeItem(
          id: 'fi_chickpeas',
          ingredient: MockData.ingChickpeas,
          quantity: 1,
          unit: 'boîte',
          expirationDate: noDateFallback,
          hasExpirationDate: false,
        ),
      ],
    );
  }

  /// Updates the active category filter tab.
  void selectCategory(FridgeCategoryFilter category) {
    if (state.selectedCategory == category) {
      return;
    }
    state = state.copyWith(selectedCategory: category);
  }

  /// Adds [item] to the fridge inventory.
  void addItem(FridgeItem item) {
    state = state.copyWith(items: [item, ...state.items]);
  }

  /// Replaces an existing item matching `updated.id`.
  void updateItem(FridgeItem updated) {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id == updated.id) updated else item,
      ],
    );
  }

  /// Removes the item with matching [id].
  void removeItem(String id) {
    state = state.copyWith(
      items: state.items.where((item) => item.id != id).toList(),
    );
  }

  /// Restores a previously removed [item] (used for snackbar undo).
  void restoreItem(FridgeItem item) {
    if (state.items.any((existing) => existing.id == item.id)) {
      return;
    }
    state = state.copyWith(items: [item, ...state.items]);
  }
}

/// Global provider for the user's fridge inventory and active category filter.
final fridgeProvider = NotifierProvider<FridgeNotifier, FridgeState>(
  FridgeNotifier.new,
);
