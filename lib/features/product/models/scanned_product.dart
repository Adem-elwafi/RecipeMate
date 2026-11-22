import 'package:flutter/foundation.dart';
import 'package:recipemate/core/models/ingredient.dart';

/// Food product retrieved from Open Food Facts or the offline demo catalog.
@immutable
class ScannedProduct {
  const ScannedProduct({
    required this.barcode,
    required this.name,
    required this.brand,
    required this.quantityLabel,
    required this.numericQuantity,
    required this.unit,
    this.imageUrl,
    this.nutriScoreGrade = 'unknown',
    this.energyKcal,
    this.proteins,
    this.carbs,
    this.sugars,
    this.fat,
    this.salt,
    this.allergens = const <String>[],
    this.ingredientsText = 'Liste des ingrédients non disponible.',
    this.suggestedCategory = IngredientCategory.other,
    this.estimatedShelfLifeDays = 14,
    this.isFromDemoFallback = false,
  });

  /// Parses an Open Food Facts API v2 `product` JSON payload into a [ScannedProduct].
  factory ScannedProduct.fromOpenFoodFactsJson(
    String barcode,
    Map<String, dynamic> productJson, {
    bool isFromDemoFallback = false,
  }) {
    final name =
        _readNonEmptyString(productJson['product_name_fr']) ??
        _readNonEmptyString(productJson['product_name']) ??
        'Produit inconnu';

    final brand =
        _readNonEmptyString(productJson['brands']) ?? 'Marque inconnue';

    final parsedQty = _parseQuantity(productJson['quantity']);

    final rawGrade = _readNonEmptyString(productJson['nutriscore_grade'])
        ?.toLowerCase();
    final nutriScoreGrade =
        (rawGrade != null && _validNutriScoreGrades.contains(rawGrade))
        ? rawGrade
        : 'unknown';

    final rawNutriments = productJson['nutriments'];
    final nutriments = rawNutriments is Map<Object?, Object?>
        ? rawNutriments
        : null;

    final category = _mapCategory(productJson['categories_tags']);
    final shelfLifeDays = defaultShelfLifeForCategory(category);

    final imageUrl =
        _readNonEmptyString(productJson['image_front_url']) ??
        _readNonEmptyString(productJson['image_url']);

    final ingredientsText =
        _readNonEmptyString(productJson['ingredients_text_fr']) ??
        _readNonEmptyString(productJson['ingredients_text']) ??
        'Liste des ingrédients non disponible.';

    return ScannedProduct(
      barcode: barcode,
      name: name,
      brand: brand,
      quantityLabel: parsedQty.quantityLabel,
      numericQuantity: parsedQty.numericQuantity,
      unit: parsedQty.unit,
      imageUrl: imageUrl,
      nutriScoreGrade: nutriScoreGrade,
      energyKcal: _parseDouble(nutriments?['energy-kcal_100g']),
      proteins: _parseDouble(nutriments?['proteins_100g']),
      carbs: _parseDouble(nutriments?['carbohydrates_100g']),
      sugars: _parseDouble(nutriments?['sugars_100g']),
      fat: _parseDouble(nutriments?['fat_100g']),
      salt: _parseDouble(nutriments?['salt_100g']),
      allergens: _parseAllergens(productJson['allergens_tags']),
      ingredientsText: ingredientsText,
      suggestedCategory: category,
      estimatedShelfLifeDays: shelfLifeDays,
      isFromDemoFallback: isFromDemoFallback,
    );
  }

  final String barcode;
  final String name;
  final String brand;
  final String quantityLabel;
  final double numericQuantity;
  final String unit;
  final String? imageUrl;
  final String nutriScoreGrade;
  final double? energyKcal;
  final double? proteins;
  final double? carbs;
  final double? sugars;
  final double? fat;
  final double? salt;
  final List<String> allergens;
  final String ingredientsText;
  final IngredientCategory suggestedCategory;
  final int estimatedShelfLifeDays;
  final bool isFromDemoFallback;

  static const Set<String> _validNutriScoreGrades = <String>{
    'a',
    'b',
    'c',
    'd',
    'e',
  };

  static const Map<String, String> _allergenTranslations = <String, String>{
    'en:milk': 'Lait',
    'fr:lait': 'Lait',
    'en:gluten': 'Gluten',
    'fr:gluten': 'Gluten',
    'en:peanuts': 'Arachides',
    'fr:arachides': 'Arachides',
    'en:eggs': 'Œufs',
    'fr:oeufs': 'Œufs',
    'fr:œufs': 'Œufs',
    'en:nuts': 'Fruits à coque',
    'fr:fruits-a-coque': 'Fruits à coque',
    'en:soybeans': 'Soja',
    'fr:soja': 'Soja',
    'en:fish': 'Poisson',
    'fr:poisson': 'Poisson',
    'fr:poissons': 'Poisson',
    'en:crustaceans': 'Crustacés',
    'fr:crustaces': 'Crustacés',
    'fr:crustacés': 'Crustacés',
    'en:sesame-seeds': 'Sésame',
    'fr:graines-de-sesame': 'Sésame',
    'fr:sesame': 'Sésame',
    'en:mustard': 'Moutarde',
    'fr:moutarde': 'Moutarde',
    'en:celery': 'Céleri',
    'fr:celeri': 'Céleri',
    'fr:céleri': 'Céleri',
    'en:lupin': 'Lupin',
    'fr:lupin': 'Lupin',
    'en:molluscs': 'Mollusques',
    'fr:mollusques': 'Mollusques',
    'en:sulphur-dioxide-and-sulphites': 'Sulfites',
    'fr:anhydride-sulfureux-et-sulfites': 'Sulfites',
    'fr:sulfites': 'Sulfites',
  };

  /// Groups 13-digit EAN codes cleanly (e.g. `EAN 3 760 123 456 789`).
  String get formattedEan {
    if (RegExp(r'^\d{13}$').hasMatch(barcode)) {
      return 'EAN ${barcode[0]} ${barcode.substring(1, 4)} '
          '${barcode.substring(4, 7)} ${barcode.substring(7, 10)} '
          '${barcode.substring(10, 13)}';
    }
    return 'EAN $barcode';
  }

  /// French nutritional quality description corresponding to [nutriScoreGrade].
  String get nutriScoreDescription {
    return switch (nutriScoreGrade.toLowerCase()) {
      'a' => 'Très bonne qualité nutritionnelle',
      'b' => 'Bonne qualité nutritionnelle',
      'c' => 'Qualité nutritionnelle moyenne',
      'd' => 'Qualité nutritionnelle faible',
      'e' => 'Qualité nutritionnelle limitée',
      _ => 'Nutri-Score non renseigné',
    };
  }

  /// Converts this scanned product into a shared [Ingredient] model.
  Ingredient toIngredient() {
    return Ingredient(
      id: 'off_$barcode',
      name: name,
      category: suggestedCategory,
      defaultUnit: unit,
      imageUrl: imageUrl,
    );
  }

  /// Returns a copy of this [ScannedProduct] with updated fields.
  ScannedProduct copyWith({
    String? barcode,
    String? name,
    String? brand,
    String? quantityLabel,
    double? numericQuantity,
    String? unit,
    String? imageUrl,
    String? nutriScoreGrade,
    double? energyKcal,
    double? proteins,
    double? carbs,
    double? sugars,
    double? fat,
    double? salt,
    List<String>? allergens,
    String? ingredientsText,
    IngredientCategory? suggestedCategory,
    int? estimatedShelfLifeDays,
    bool? isFromDemoFallback,
  }) {
    return ScannedProduct(
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      quantityLabel: quantityLabel ?? this.quantityLabel,
      numericQuantity: numericQuantity ?? this.numericQuantity,
      unit: unit ?? this.unit,
      imageUrl: imageUrl ?? this.imageUrl,
      nutriScoreGrade: nutriScoreGrade ?? this.nutriScoreGrade,
      energyKcal: energyKcal ?? this.energyKcal,
      proteins: proteins ?? this.proteins,
      carbs: carbs ?? this.carbs,
      sugars: sugars ?? this.sugars,
      fat: fat ?? this.fat,
      salt: salt ?? this.salt,
      allergens: allergens ?? this.allergens,
      ingredientsText: ingredientsText ?? this.ingredientsText,
      suggestedCategory: suggestedCategory ?? this.suggestedCategory,
      estimatedShelfLifeDays:
          estimatedShelfLifeDays ?? this.estimatedShelfLifeDays,
      isFromDemoFallback: isFromDemoFallback ?? this.isFromDemoFallback,
    );
  }

  /// Default estimated shelf life in days for a given [IngredientCategory].
  static int defaultShelfLifeForCategory(IngredientCategory category) {
    return switch (category) {
      IngredientCategory.dairy => 10,
      IngredientCategory.meat || IngredientCategory.fish => 3,
      IngredientCategory.vegetables => 5,
      IngredientCategory.fruits => 7,
      IngredientCategory.bakery => 5,
      IngredientCategory.grains || IngredientCategory.spices => 60,
      IngredientCategory.other => 14,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScannedProduct &&
          runtimeType == other.runtimeType &&
          barcode == other.barcode;

  @override
  int get hashCode => barcode.hashCode;

  static String? _readNonEmptyString(Object? value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static double? _parseDouble(Object? value) {
    if (value is num) {
      final doubleVal = value.toDouble();
      return doubleVal.isFinite ? doubleVal : null;
    }
    if (value is String) {
      final normalized = value.trim().replaceAll(',', '.');
      if (normalized.isEmpty) {
        return null;
      }
      final parsed = double.tryParse(normalized);
      return (parsed != null && parsed.isFinite) ? parsed : null;
    }
    return null;
  }

  static ({String quantityLabel, double numericQuantity, String unit})
  _parseQuantity(Object? rawQuantity) {
    final raw = _readNonEmptyString(rawQuantity);
    if (raw == null) {
      return (quantityLabel: '1 pièce', numericQuantity: 1.0, unit: 'pièce');
    }

    final multiMatch = RegExp(
      r'^(\d+)\s*[xX×]\s*(\d+(?:[.,]\d+)?)\s*([a-zA-ZÀ-ÿ]+)?',
    ).firstMatch(raw);
    if (multiMatch != null) {
      final count = int.tryParse(multiMatch.group(1) ?? '');
      final perItem = double.tryParse(
        (multiMatch.group(2) ?? '').replaceAll(',', '.'),
      );
      if (count != null && count > 0 && perItem != null && perItem > 0) {
        return (
          quantityLabel: raw,
          numericQuantity: count * perItem,
          unit: _normalizeUnit(multiMatch.group(3)),
        );
      }
    }

    final singleMatch = RegExp(r'^(\d+(?:[.,]\d+)?)\s*([a-zA-ZÀ-ÿ]+)?')
        .firstMatch(raw);
    if (singleMatch != null) {
      final number = double.tryParse(
        (singleMatch.group(1) ?? '').replaceAll(',', '.'),
      );
      if (number != null && number > 0) {
        return (
          quantityLabel: raw,
          numericQuantity: number,
          unit: _normalizeUnit(singleMatch.group(2)),
        );
      }
    }

    return (quantityLabel: raw, numericQuantity: 1.0, unit: 'pièce');
  }

  static String _normalizeUnit(String? rawUnit) {
    if (rawUnit == null || rawUnit.trim().isEmpty) {
      return 'pièce';
    }
    final trimmed = rawUnit.trim();
    return switch (trimmed.toLowerCase()) {
      'g' || 'gr' || 'gramme' || 'grammes' => 'g',
      'kg' || 'kilo' || 'kilos' || 'kilogramme' || 'kilogrammes' => 'kg',
      'mg' => 'mg',
      'l' || 'lt' || 'litre' || 'litres' => 'L',
      'ml' || 'millilitre' || 'millilitres' => 'ml',
      'cl' || 'centilitre' || 'centilitres' => 'cl',
      'dl' => 'dl',
      'pièce' ||
      'pièces' ||
      'piece' ||
      'pieces' ||
      'pce' ||
      'pcs' ||
      'unité' ||
      'unités' ||
      'unite' ||
      'unites' => 'pièce',
      'pot' || 'pots' => 'pot',
      'tranche' || 'tranches' => 'tranche',
      'sachet' || 'sachets' => 'sachet',
      _ => trimmed,
    };
  }

  static List<String> _parseAllergens(Object? rawAllergens) {
    if (rawAllergens is! List<Object?>) {
      return const <String>[];
    }

    final seen = <String>{};
    final result = <String>[];

    for (final entry in rawAllergens) {
      final tag = _readNonEmptyString(entry)?.toLowerCase();
      if (tag == null) {
        continue;
      }

      final translated = _allergenTranslations[tag] ?? _formatUnknownTag(tag);
      if (translated.isNotEmpty && seen.add(translated)) {
        result.add(translated);
      }
    }

    return result;
  }

  static final RegExp _langPrefixRegex = RegExp('^[a-z]{2}:');

  static String _formatUnknownTag(String tag) {
    final stripped = tag
        .replaceFirst(_langPrefixRegex, '')
        .replaceAll(RegExp('[-_]+'), ' ')
        .trim();
    if (stripped.isEmpty) {
      return '';
    }
    return stripped[0].toUpperCase() + stripped.substring(1);
  }

  static IngredientCategory _mapCategory(Object? rawCategories) {
    if (rawCategories is! List<Object?>) {
      return IngredientCategory.other;
    }

    final tags = <String>[];
    for (final entry in rawCategories) {
      final tag = _readNonEmptyString(entry)?.toLowerCase();
      if (tag != null) {
        tags.add(tag);
      }
    }

    // Iterate from leaf categories (most specific) to root categories.
    for (final rawTag in tags.reversed) {
      final isFrenchTag = rawTag.startsWith('fr:');
      final tag = rawTag.replaceFirst(_langPrefixRegex, '');

      if (_isAmbiguousOrSubstituteTag(tag)) {
        continue;
      }

      final segments = tag.split('-').toSet();

      if (_matchesFish(tag, segments)) {
        return IngredientCategory.fish;
      }
      if (_matchesMeat(segments)) {
        return IngredientCategory.meat;
      }
      if (_matchesBakery(segments)) {
        return IngredientCategory.bakery;
      }
      if (_matchesDairy(tag, segments)) {
        return IngredientCategory.dairy;
      }
      if (_matchesVegetables(tag, segments, isFrenchTag: isFrenchTag)) {
        return IngredientCategory.vegetables;
      }
      if (_matchesFruits(segments)) {
        return IngredientCategory.fruits;
      }
      if (_matchesSpices(segments)) {
        return IngredientCategory.spices;
      }
      if (_matchesGrains(tag, segments)) {
        return IngredientCategory.grains;
      }
    }

    return IngredientCategory.other;
  }

  static bool _isAmbiguousOrSubstituteTag(String tag) {
    return tag.contains('fruits-and-vegetables') ||
        tag.contains('fruits-et-legumes') ||
        tag.contains('cereals-and-potatoes') ||
        tag.contains('substitutes') ||
        tag.contains('alternatives') ||
        tag.contains('analogues');
  }

  static bool _matchesFish(String tag, Set<String> segments) {
    if (tag.contains('fruits-de-mer')) {
      return true;
    }
    return segments.any(
      (s) => const <String>{
        'fish',
        'fishes',
        'seafood',
        'poisson',
        'poissons',
        'salmon',
        'salmons',
        'saumon',
        'tuna',
        'thon',
        'shrimp',
        'shrimps',
        'crevette',
        'crevettes',
        'crustacean',
        'crustaceans',
        'crustace',
        'crustaces',
      }.contains(s),
    );
  }

  static bool _matchesMeat(Set<String> segments) {
    return segments.any(
      (s) => const <String>{
        'meat',
        'meats',
        'viande',
        'viandes',
        'poultry',
        'poultries',
        'volaille',
        'volailles',
        'chicken',
        'chickens',
        'poulet',
        'beef',
        'boeuf',
        'bœuf',
        'pork',
        'porc',
        'ham',
        'jambon',
        'turkey',
        'dinde',
        'lamb',
        'agneau',
        'sausage',
        'sausages',
        'saucisse',
        'saucisses',
      }.contains(s),
    );
  }

  static bool _matchesBakery(Set<String> segments) {
    return segments.any(
      (s) => const <String>{
        'bakery',
        'bakeries',
        'boulangerie',
        'bread',
        'breads',
        'pain',
        'pains',
        'viennoiserie',
        'viennoiseries',
        'brioche',
        'brioches',
        'croissant',
        'croissants',
        'baguette',
        'baguettes',
        'biscotte',
        'biscottes',
      }.contains(s),
    );
  }

  static bool _matchesDairy(String tag, Set<String> segments) {
    final hasNonDairyModifier =
        tag.contains('plant') ||
        tag.contains('vegetal') ||
        tag.contains('soy') ||
        tag.contains('soja') ||
        tag.contains('oat') ||
        tag.contains('avoine') ||
        tag.contains('almond') ||
        tag.contains('amande') ||
        tag.contains('coconut') ||
        tag.contains('coco') ||
        tag.contains('chocolate') ||
        tag.contains('chocolat');
    if (hasNonDairyModifier) {
      return false;
    }
    return segments.any(
      (s) => const <String>{
        'dairy',
        'dairies',
        'laitier',
        'laitiers',
        'yogurt',
        'yogurts',
        'yoghurt',
        'yoghurts',
        'yaourt',
        'yaourts',
        'cheese',
        'cheeses',
        'fromage',
        'fromages',
        'butter',
        'beurre',
        'cream',
        'creams',
        'creme',
        'crème',
        'milk',
        'milks',
        'lait',
        'laits',
        'egg',
        'eggs',
        'oeuf',
        'oeufs',
        'œuf',
        'œufs',
      }.contains(s),
    );
  }

  static bool _matchesVegetables(
    String tag,
    Set<String> segments, {
    required bool isFrenchTag,
  }) {
    if (tag.contains('pomme-de-terre') || tag.contains('pommes-de-terre')) {
      return true;
    }
    if (isFrenchTag &&
        (segments.contains('legume') || segments.contains('legumes'))) {
      return true;
    }
    return segments.any(
      (s) => const <String>{
        'vegetable',
        'vegetables',
        'légume',
        'légumes',
        'tomato',
        'tomatoes',
        'tomate',
        'tomates',
        'spinach',
        'spinaches',
        'epinard',
        'epinards',
        'épinard',
        'épinards',
        'carrot',
        'carrots',
        'carotte',
        'carottes',
        'cucumber',
        'cucumbers',
        'concombre',
        'concombres',
        'onion',
        'onions',
        'oignon',
        'oignons',
        'zucchini',
        'courgette',
        'courgettes',
        'salad',
        'salads',
        'salade',
        'salades',
        'potato',
        'potatoes',
        'broccoli',
        'brocoli',
        'mushroom',
        'mushrooms',
        'champignon',
        'champignons',
      }.contains(s),
    );
  }

  static bool _matchesFruits(Set<String> segments) {
    return segments.any(
      (s) => const <String>{
        'fruit',
        'fruits',
        'apple',
        'apples',
        'pomme',
        'pommes',
        'banana',
        'bananas',
        'banane',
        'bananes',
        'berry',
        'berries',
        'fraise',
        'fraises',
        'orange',
        'oranges',
        'lemon',
        'lemons',
        'citron',
        'citrons',
        'pear',
        'pears',
        'poire',
        'poires',
        'peach',
        'peaches',
        'peche',
        'pêche',
        'grape',
        'grapes',
        'raisin',
        'raisins',
        'mango',
        'mangue',
        'kiwi',
      }.contains(s),
    );
  }

  static bool _matchesSpices(Set<String> segments) {
    return segments.any(
      (s) => const <String>{
        'spice',
        'spices',
        'epice',
        'epices',
        'épice',
        'épices',
        'condiment',
        'condiments',
        'herb',
        'herbs',
        'herbe',
        'herbes',
        'mustard',
        'mustards',
        'moutarde',
        'moutardes',
        'vinegar',
        'vinegars',
        'vinaigre',
        'vinaigres',
        'oil',
        'oils',
        'huile',
        'huiles',
        'salt',
        'sel',
        'sauce',
        'sauces',
        'seasoning',
        'seasonings',
        'assaisonnement',
      }.contains(s),
    );
  }

  static bool _matchesGrains(String tag, Set<String> segments) {
    if (tag.contains('pois-chiche')) {
      return true;
    }
    return segments.any(
      (s) => const <String>{
        'grain',
        'grains',
        'cereal',
        'cereals',
        'cereale',
        'cereales',
        'céréale',
        'céréales',
        'pasta',
        'pastas',
        'pate',
        'pates',
        'pâtes',
        'rice',
        'rices',
        'riz',
        'oat',
        'oats',
        'avoine',
        'flour',
        'flours',
        'farine',
        'farines',
        'legumes',
        'leguminous',
        'legumineuses',
        'légumineuses',
        'lentil',
        'lentils',
        'lentille',
        'lentilles',
        'chickpea',
        'chickpeas',
        'quinoa',
        'wheat',
        'ble',
        'blé',
        'couscous',
        'semolina',
        'semoule',
      }.contains(s),
    );
  }
}
