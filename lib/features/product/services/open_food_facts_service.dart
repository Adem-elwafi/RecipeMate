import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:recipemate/core/models/ingredient.dart';
import 'package:recipemate/features/product/models/scanned_product.dart';

/// Exception thrown when a product cannot be retrieved from Open Food Facts.
class ProductNotFoundException implements Exception {
  const ProductNotFoundException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Client for querying Open Food Facts API v2 with offline French demo fallback.
class OpenFoodFactsService {
  OpenFoodFactsService({http.Client? client})
    : _client = client ?? http.Client();

  static const String baseUrl =
      'https://world.openfoodfacts.org/api/v2/product';

  static const String _fieldsQuery =
      'product_name,product_name_fr,brands,quantity,nutriscore_grade,'
      'nutriments,allergens_tags,ingredients_text_fr,ingredients_text,'
      'image_front_url,categories_tags';

  final http.Client _client;

  /// Built-in French demo catalog used for mockup fidelity and offline fallback.
  static List<ScannedProduct> get demoProducts => const <ScannedProduct>[
    ScannedProduct(
      barcode: '3760123456789',
      name: 'Yaourt grec nature 0 %',
      brand: 'Ferme des Oliviers',
      quantityLabel: '500 g',
      numericQuantity: 500,
      unit: 'g',
      nutriScoreGrade: 'a',
      energyKcal: 57,
      proteins: 10.3,
      carbs: 3.6,
      sugars: 3.6,
      fat: 0.2,
      salt: 0.09,
      allergens: <String>['Lait'],
      ingredientsText:
          'Lait écrémé pasteurisé, protéines de lait, ferments lactiques '
          '(dont Lactobacillus bulgaricus et Streptococcus thermophilus).',
      suggestedCategory: IngredientCategory.dairy,
      estimatedShelfLifeDays: 12,
    ),
    ScannedProduct(
      barcode: '3017620422003',
      name: 'Pâte à tartiner aux noisettes',
      brand: 'Ferrero',
      quantityLabel: '400 g',
      numericQuantity: 400,
      unit: 'g',
      nutriScoreGrade: 'e',
      energyKcal: 539,
      proteins: 6.3,
      carbs: 57.5,
      sugars: 56.3,
      fat: 30.9,
      salt: 0.11,
      allergens: <String>['Fruits à coque', 'Lait', 'Soja'],
      ingredientsText:
          'Sucre, huile de palme, noisettes (13 %), lait écrémé en poudre '
          '(8,7 %), cacao maigre (7,4 %), émulsifiants : lécithines [soja], '
          'vanilline.',
      suggestedCategory: IngredientCategory.other,
      estimatedShelfLifeDays: 90,
    ),
    ScannedProduct(
      barcode: '3228857000166',
      name: 'Pain de mie complet',
      brand: "Harry's",
      quantityLabel: '500 g',
      numericQuantity: 500,
      unit: 'g',
      nutriScoreGrade: 'a',
      energyKcal: 255,
      proteins: 9.0,
      carbs: 42.0,
      sugars: 4.5,
      fat: 4.0,
      salt: 1.1,
      allergens: <String>['Gluten'],
      ingredientsText:
          'Farine complète de blé (64 %), eau, huile de colza, levure, sucre, '
          'sel, gluten de blé, vinaigre d’alcool, farine de fèves.',
      suggestedCategory: IngredientCategory.bakery,
      estimatedShelfLifeDays: 7,
    ),
    ScannedProduct(
      barcode: '3560070472888',
      name: 'Tomates pelées bio',
      brand: 'Carrefour Bio',
      quantityLabel: '400 g',
      numericQuantity: 400,
      unit: 'g',
      nutriScoreGrade: 'a',
      energyKcal: 22,
      proteins: 1.2,
      carbs: 3.5,
      sugars: 3.0,
      fat: 0.2,
      salt: 0.05,
      allergens: <String>[],
      ingredientsText:
          'Tomates pelées bio, jus de tomate bio, correcteur d’acidité : '
          'acide citrique.',
      suggestedCategory: IngredientCategory.vegetables,
      estimatedShelfLifeDays: 180,
    ),
  ];

  /// Fetches product details for [rawBarcode] from Open Food Facts API v2.
  Future<ScannedProduct> fetchProductByBarcode(String rawBarcode) async {
    final barcode = rawBarcode.trim();
    if (barcode.isEmpty) {
      throw const ProductNotFoundException('Code-barres invalide.');
    }

    // Return the HTML mockup's synthetic EAN immediately for consistent design demos.
    if (barcode == '3760123456789') {
      return demoProducts.first;
    }

    final uri = Uri.parse('$baseUrl/$barcode.json?fields=$_fieldsQuery');

    try {
      final response = await _client
          .get(
            uri,
            headers: const <String, String>{
              'User-Agent': 'RecipeMate/1.0 (Flutter)',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(_decodeResponseBody(response));
        if (decoded is Map<String, dynamic> &&
            decoded['status'] == 1 &&
            decoded['product'] is Map<String, dynamic>) {
          return ScannedProduct.fromOpenFoodFactsJson(
            barcode,
            decoded['product'] as Map<String, dynamic>,
          );
        }
      }

      final fallback = _findDemoProduct(barcode);
      if (fallback != null) {
        return fallback.copyWith(isFromDemoFallback: true);
      }

      throw ProductNotFoundException(
        'Aucun produit trouvé pour le code-barres $barcode.',
      );
    } on SocketException {
      return _demoFallbackOrThrow(barcode);
    } on TimeoutException {
      return _demoFallbackOrThrow(barcode);
    } on http.ClientException {
      return _demoFallbackOrThrow(barcode);
    } on FormatException {
      final fallback = _findDemoProduct(barcode);
      if (fallback != null) {
        return fallback.copyWith(isFromDemoFallback: true);
      }
      throw ProductNotFoundException(
        'Aucun produit trouvé pour le code-barres $barcode.',
      );
    }
  }

  /// Releases resources held by the underlying HTTP client.
  void dispose() {
    _client.close();
  }

  ScannedProduct _demoFallbackOrThrow(String barcode) {
    final fallback = _findDemoProduct(barcode);
    if (fallback != null) {
      return fallback.copyWith(isFromDemoFallback: true);
    }
    throw const ProductNotFoundException(
      'Impossible de joindre Open Food Facts. '
      'Vérifiez votre connexion internet.',
    );
  }

  ScannedProduct? _findDemoProduct(String barcode) {
    for (final product in demoProducts) {
      if (product.barcode == barcode) {
        return product;
      }
    }
    return null;
  }

  String _decodeResponseBody(http.Response response) {
    final contentType = response.headers['content-type']?.toLowerCase() ?? '';
    if (contentType.contains('charset=')) {
      return response.body;
    }
    try {
      return utf8.decode(response.bodyBytes);
    } on FormatException {
      return response.body;
    }
  }
}
