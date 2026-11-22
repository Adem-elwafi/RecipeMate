import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:recipemate/core/models/ingredient.dart';
import 'package:recipemate/features/product/models/scanned_product.dart';
import 'package:recipemate/features/product/providers/product_provider.dart';
import 'package:recipemate/features/product/services/open_food_facts_service.dart';

void main() {
  group('ScannedProduct model', () {
    test('parses a realistic OpenFoodFacts v2 JSON payload', () {
      final productJson = <String, dynamic>{
        'product_name_fr': 'Skyr nature islandais',
        'product_name': 'Icelandic Skyr',
        'brands': 'Siggi’s',
        'quantity': '450 g',
        'nutriscore_grade': 'A',
        'image_front_url': 'https://images.openfoodfacts.org/skyr.jpg',
        'ingredients_text_fr': 'Lait écrémé pasteurisé, ferments lactiques.',
        'ingredients_text': 'Pasteurized skim milk, lactic cultures.',
        'allergens_tags': <dynamic>[
          'en:milk',
          'fr:lait',
          'en:gluten',
          'en:milk',
          'fr:avoine-entiere',
        ],
        'categories_tags': <dynamic>[
          'en:dairies',
          'en:fermented-foods',
          'en:fermented-milk-products',
          'en:yogurts',
        ],
        'nutriments': <String, dynamic>{
          'energy-kcal_100g': 62,
          'proteins_100g': 10.6,
          'carbohydrates_100g': '3.8',
          'sugars_100g': '3,5',
          'fat_100g': 0.2,
          'salt_100g': 0.1,
        },
      };

      final product = ScannedProduct.fromOpenFoodFactsJson(
        '3123456789012',
        productJson,
      );

      expect(product.barcode, equals('3123456789012'));
      expect(product.name, equals('Skyr nature islandais'));
      expect(product.brand, equals('Siggi’s'));
      expect(product.quantityLabel, equals('450 g'));
      expect(product.numericQuantity, equals(450.0));
      expect(product.unit, equals('g'));
      expect(
        product.imageUrl,
        equals('https://images.openfoodfacts.org/skyr.jpg'),
      );
      expect(product.nutriScoreGrade, equals('a'));
      expect(
        product.nutriScoreDescription,
        equals('Très bonne qualité nutritionnelle'),
      );
      expect(product.energyKcal, equals(62.0));
      expect(product.proteins, equals(10.6));
      expect(product.carbs, equals(3.8));
      expect(product.sugars, equals(3.5));
      expect(product.fat, equals(0.2));
      expect(product.salt, equals(0.1));
      expect(
        product.allergens,
        equals(<String>['Lait', 'Gluten', 'Avoine entiere']),
      );
      expect(
        product.ingredientsText,
        equals('Lait écrémé pasteurisé, ferments lactiques.'),
      );
      expect(product.suggestedCategory, equals(IngredientCategory.dairy));
      expect(product.estimatedShelfLifeDays, equals(10));
      expect(product.isFromDemoFallback, isFalse);
      expect(product.formattedEan, equals('EAN 3 123 456 789 012'));

      final ingredient = product.toIngredient();
      expect(ingredient.id, equals('off_3123456789012'));
      expect(ingredient.name, equals('Skyr nature islandais'));
      expect(ingredient.category, equals(IngredientCategory.dairy));
      expect(ingredient.defaultUnit, equals('g'));
      expect(
        ingredient.imageUrl,
        equals('https://images.openfoodfacts.org/skyr.jpg'),
      );
    });

    test('falls back safely when optional fields are missing or invalid', () {
      final product = ScannedProduct.fromOpenFoodFactsJson(
        '12345678',
        const <String, dynamic>{
          'product_name_fr': '   ',
          'product_name': 'Produit générique',
          'nutriscore_grade': 'not-applicable',
        },
      );

      expect(product.name, equals('Produit générique'));
      expect(product.brand, equals('Marque inconnue'));
      expect(product.quantityLabel, equals('1 pièce'));
      expect(product.numericQuantity, equals(1.0));
      expect(product.unit, equals('pièce'));
      expect(product.nutriScoreGrade, equals('unknown'));
      expect(
        product.nutriScoreDescription,
        equals('Nutri-Score non renseigné'),
      );
      expect(product.allergens, isEmpty);
      expect(
        product.ingredientsText,
        equals('Liste des ingrédients non disponible.'),
      );
      expect(product.suggestedCategory, equals(IngredientCategory.other));
      expect(product.estimatedShelfLifeDays, equals(14));
      expect(product.formattedEan, equals('EAN 12345678'));
    });

    test('parses diverse quantity strings accurately', () {
      final liter = ScannedProduct.fromOpenFoodFactsJson(
        '1',
        const <String, dynamic>{'quantity': '1 L'},
      );
      expect(liter.quantityLabel, equals('1 L'));
      expect(liter.numericQuantity, equals(1.0));
      expect(liter.unit, equals('L'));

      final ml = ScannedProduct.fromOpenFoodFactsJson(
        '2',
        const <String, dynamic>{'quantity': '250 ml'},
      );
      expect(ml.quantityLabel, equals('250 ml'));
      expect(ml.numericQuantity, equals(250.0));
      expect(ml.unit, equals('ml'));

      final pieces = ScannedProduct.fromOpenFoodFactsJson(
        '3',
        const <String, dynamic>{'quantity': '6 pièces'},
      );
      expect(pieces.quantityLabel, equals('6 pièces'));
      expect(pieces.numericQuantity, equals(6.0));
      expect(pieces.unit, equals('pièce'));

      final multipack = ScannedProduct.fromOpenFoodFactsJson(
        '4',
        const <String, dynamic>{'quantity': '4 x 125 g'},
      );
      expect(multipack.quantityLabel, equals('4 x 125 g'));
      expect(multipack.numericQuantity, equals(500.0));
      expect(multipack.unit, equals('g'));
    });

    test(
      'translates all standard EU allergen tags to French and deduplicates',
      () {
        final product = ScannedProduct.fromOpenFoodFactsJson(
          '9999999999999',
          const <String, dynamic>{
            'allergens_tags': <dynamic>[
              'en:milk',
              'en:gluten',
              'en:peanuts',
              'en:eggs',
              'en:nuts',
              'en:soybeans',
              'en:fish',
              'en:crustaceans',
              'en:sesame-seeds',
              'en:mustard',
              'en:milk',
            ],
          },
        );

        expect(
          product.allergens,
          equals(<String>[
            'Lait',
            'Gluten',
            'Arachides',
            'Œufs',
            'Fruits à coque',
            'Soja',
            'Poisson',
            'Crustacés',
            'Sésame',
            'Moutarde',
          ]),
        );
      },
    );

    test('maps categories to IngredientCategory and shelf life days', () {
      const cases =
          <({List<String> tags, IngredientCategory category, int days})>[
            (
              tags: <String>['en:dairies', 'en:cheeses'],
              category: IngredientCategory.dairy,
              days: 10,
            ),
            (
              tags: <String>['en:meats', 'en:poultries'],
              category: IngredientCategory.meat,
              days: 3,
            ),
            (
              tags: <String>['en:seafood', 'en:salmons'],
              category: IngredientCategory.fish,
              days: 3,
            ),
            (
              tags: <String>[
                'en:fruits-and-vegetables-based-foods',
                'en:vegetables-based-foods',
                'en:tomatoes',
              ],
              category: IngredientCategory.vegetables,
              days: 5,
            ),
            (
              tags: <String>['en:fruits-based-foods', 'en:apples'],
              category: IngredientCategory.fruits,
              days: 7,
            ),
            (
              tags: <String>['en:cereals-and-potatoes', 'en:breads'],
              category: IngredientCategory.bakery,
              days: 5,
            ),
            (
              tags: <String>['en:cereals-and-their-products', 'en:pastas'],
              category: IngredientCategory.grains,
              days: 60,
            ),
            (
              tags: <String>['en:condiments', 'en:spices'],
              category: IngredientCategory.spices,
              days: 60,
            ),
            (
              tags: <String>['en:chocolate-spreads'],
              category: IngredientCategory.other,
              days: 14,
            ),
          ];

      for (final entry in cases) {
        final product = ScannedProduct.fromOpenFoodFactsJson(
          '1111111111111',
          <String, dynamic>{'categories_tags': entry.tags},
        );
        expect(product.suggestedCategory, equals(entry.category));
        expect(product.estimatedShelfLifeDays, equals(entry.days));
      }
    });

    test('maps all Nutri-Score grades to French descriptions', () {
      const expected = <String, String>{
        'a': 'Très bonne qualité nutritionnelle',
        'b': 'Bonne qualité nutritionnelle',
        'c': 'Qualité nutritionnelle moyenne',
        'd': 'Qualité nutritionnelle faible',
        'e': 'Qualité nutritionnelle limitée',
        'unknown': 'Nutri-Score non renseigné',
      };

      for (final entry in expected.entries) {
        final product = ScannedProduct(
          barcode: '1',
          name: 'Test',
          brand: 'Test',
          quantityLabel: '100 g',
          numericQuantity: 100,
          unit: 'g',
          nutriScoreGrade: entry.key,
        );
        expect(product.nutriScoreDescription, equals(entry.value));
      }
    });

    test('implements value equality by barcode', () {
      const p1 = ScannedProduct(
        barcode: '3760123456789',
        name: 'Produit A',
        brand: 'Marque A',
        quantityLabel: '500 g',
        numericQuantity: 500,
        unit: 'g',
      );
      const p2 = ScannedProduct(
        barcode: '3760123456789',
        name: 'Produit B',
        brand: 'Marque B',
        quantityLabel: '250 g',
        numericQuantity: 250,
        unit: 'g',
      );
      const p3 = ScannedProduct(
        barcode: '3017620422003',
        name: 'Produit A',
        brand: 'Marque A',
        quantityLabel: '500 g',
        numericQuantity: 500,
        unit: 'g',
      );

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1, isNot(equals(p3)));
    });
  });

  group('OpenFoodFactsService', () {
    test(
      'returns HTML mockup Yaourt grec nature 0 % for barcode 3760123456789',
      () async {
        var networkCalled = false;
        final mockClient = MockClient((request) async {
          networkCalled = true;
          return http.Response('{}', 500);
        });

        final service = OpenFoodFactsService(client: mockClient);
        final product = await service.fetchProductByBarcode('3760123456789');

        expect(networkCalled, isFalse);
        expect(product.barcode, equals('3760123456789'));
        expect(product.name, equals('Yaourt grec nature 0 %'));
        expect(product.brand, equals('Ferme des Oliviers'));
        expect(product.quantityLabel, equals('500 g'));
        expect(product.numericQuantity, equals(500.0));
        expect(product.unit, equals('g'));
        expect(product.nutriScoreGrade, equals('a'));
        expect(product.energyKcal, equals(57));
        expect(product.proteins, equals(10.3));
        expect(product.carbs, equals(3.6));
        expect(product.sugars, equals(3.6));
        expect(product.fat, equals(0.2));
        expect(product.salt, equals(0.09));
        expect(product.allergens, equals(<String>['Lait']));
        expect(product.suggestedCategory, equals(IngredientCategory.dairy));
        expect(product.estimatedShelfLifeDays, equals(12));
        expect(product.formattedEan, equals('EAN 3 760 123 456 789'));
      },
    );

    test(
      'fetches and parses realistic API v2 payload with expected headers',
      () async {
        late Uri requestedUri;
        late Map<String, String> requestedHeaders;

        final mockClient = MockClient((request) async {
          requestedUri = request.url;
          requestedHeaders = request.headers;
          return http.Response(
            jsonEncode(<String, Object?>{
              'status': 1,
              'product': <String, Object?>{
                'product_name_fr': 'Lait demi-écrémé UHT',
                'brands': 'Lactel',
                'quantity': '1 L',
                'nutriscore_grade': 'b',
                'image_front_url': 'https://images.openfoodfacts.org/lait.jpg',
                'ingredients_text_fr': 'Lait demi-écrémé de vache.',
                'allergens_tags': <String>['en:milk'],
                'categories_tags': <String>['en:dairies', 'en:milks'],
                'nutriments': <String, Object?>{
                  'energy-kcal_100g': 46,
                  'proteins_100g': 3.2,
                  'carbohydrates_100g': 4.8,
                  'sugars_100g': 4.8,
                  'fat_100g': 1.5,
                  'salt_100g': 0.1,
                },
              },
            }),
            200,
            headers: const <String, String>{
              'content-type': 'application/json; charset=utf-8',
            },
          );
        });

        final service = OpenFoodFactsService(client: mockClient);
        final product = await service.fetchProductByBarcode(' 3428273660015 ');

        expect(
          requestedUri.toString(),
          startsWith(
            'https://world.openfoodfacts.org/api/v2/product/3428273660015.json',
          ),
        );
        expect(
          requestedUri.queryParameters['fields'],
          contains('ingredients_text_fr'),
        );
        expect(
          requestedHeaders['User-Agent'],
          equals('RecipeMate/1.0 (Flutter)'),
        );
        expect(product.name, equals('Lait demi-écrémé UHT'));
        expect(product.brand, equals('Lactel'));
        expect(product.quantityLabel, equals('1 L'));
        expect(product.numericQuantity, equals(1.0));
        expect(product.unit, equals('L'));
        expect(product.nutriScoreGrade, equals('b'));
        expect(product.allergens, equals(<String>['Lait']));
        expect(product.suggestedCategory, equals(IngredientCategory.dairy));
        expect(product.isFromDemoFallback, isFalse);
      },
    );

    test('throws ProductNotFoundException on empty barcode', () async {
      final service = OpenFoodFactsService(
        client: MockClient((_) async => http.Response('{}', 200)),
      );

      await expectLater(
        service.fetchProductByBarcode('   '),
        throwsA(
          isA<ProductNotFoundException>().having(
            (e) => e.message,
            'message',
            equals('Code-barres invalide.'),
          ),
        ),
      );
    });

    test('throws ProductNotFoundException when status is 0', () async {
      final service = OpenFoodFactsService(
        client: MockClient(
          (_) async =>
              http.Response(jsonEncode(<String, Object?>{'status': 0}), 200),
        ),
      );

      await expectLater(
        service.fetchProductByBarcode('9999999999999'),
        throwsA(
          isA<ProductNotFoundException>().having(
            (e) => e.message,
            'message',
            equals('Aucun produit trouvé pour le code-barres 9999999999999.'),
          ),
        ),
      );
    });

    test(
      'throws ProductNotFoundException on HTTP 404 for unknown barcode',
      () async {
        final service = OpenFoodFactsService(
          client: MockClient((_) async => http.Response('Not Found', 404)),
        );

        await expectLater(
          service.fetchProductByBarcode('8888888888888'),
          throwsA(
            isA<ProductNotFoundException>().having(
              (e) => e.message,
              'message',
              equals('Aucun produit trouvé pour le code-barres 8888888888888.'),
            ),
          ),
        );
      },
    );

    test(
      'falls back cleanly to demo catalog on network error for 3017620422003',
      () async {
        final service = OpenFoodFactsService(
          client: MockClient(
            (_) async => throw const SocketException('Aucune connexion'),
          ),
        );

        final product = await service.fetchProductByBarcode('3017620422003');

        expect(product.barcode, equals('3017620422003'));
        expect(product.name, equals('Pâte à tartiner aux noisettes'));
        expect(product.brand, equals('Ferrero'));
        expect(product.nutriScoreGrade, equals('e'));
        expect(
          product.allergens,
          equals(<String>['Fruits à coque', 'Lait', 'Soja']),
        );
        expect(product.isFromDemoFallback, isTrue);
      },
    );

    test(
      'falls back on TimeoutException and ClientException for demo barcodes',
      () async {
        final timeoutService = OpenFoodFactsService(
          client: MockClient(
            (_) async => throw TimeoutException('Délai dépassé'),
          ),
        );
        final bread = await timeoutService.fetchProductByBarcode(
          '3228857000166',
        );
        expect(bread.name, equals('Pain de mie complet'));
        expect(bread.suggestedCategory, equals(IngredientCategory.bakery));
        expect(bread.isFromDemoFallback, isTrue);

        final clientErrorService = OpenFoodFactsService(
          client: MockClient(
            (_) async => throw http.ClientException('Erreur réseau'),
          ),
        );
        final tomatoes = await clientErrorService.fetchProductByBarcode(
          '3560070472888',
        );
        expect(tomatoes.name, equals('Tomates pelées bio'));
        expect(
          tomatoes.suggestedCategory,
          equals(IngredientCategory.vegetables),
        );
        expect(tomatoes.isFromDemoFallback, isTrue);
      },
    );

    test(
      'throws ProductNotFoundException on network error for unknown barcode',
      () async {
        final service = OpenFoodFactsService(
          client: MockClient(
            (_) async => throw const SocketException('Hors ligne'),
          ),
        );

        await expectLater(
          service.fetchProductByBarcode('7777777777777'),
          throwsA(
            isA<ProductNotFoundException>().having(
              (e) => e.message,
              'message',
              equals(
                'Impossible de joindre Open Food Facts. '
                'Vérifiez votre connexion internet.',
              ),
            ),
          ),
        );
      },
    );

    test('demoProducts contains all 4 rich French demo items', () {
      expect(OpenFoodFactsService.demoProducts, hasLength(4));
      expect(
        OpenFoodFactsService.demoProducts.map((p) => p.barcode),
        containsAll(<String>[
          '3760123456789',
          '3017620422003',
          '3228857000166',
          '3560070472888',
        ]),
      );
    });
  });

  group('product_provider', () {
    test(
      'productByBarcodeProvider delegates to OpenFoodFactsService',
      () async {
        final mockClient = MockClient(
          (_) async => http.Response(
            jsonEncode(<String, Object?>{
              'status': 1,
              'product': <String, Object?>{
                'product_name_fr': "Jus d'orange pressé",
                'brands': 'Tropicana',
                'quantity': '1 L',
                'nutriscore_grade': 'c',
                'categories_tags': <String>['en:fruits'],
              },
            }),
            200,
            headers: const <String, String>{
              'content-type': 'application/json; charset=utf-8',
            },
          ),
        );

        final container = ProviderContainer(
          overrides: <Override>[
            openFoodFactsServiceProvider.overrideWithValue(
              OpenFoodFactsService(client: mockClient),
            ),
          ],
        );
        addTearDown(container.dispose);

        final product = await container.read(
          productByBarcodeProvider('3502110009449').future,
        );

        expect(product.name, equals("Jus d'orange pressé"));
        expect(product.brand, equals('Tropicana'));
        expect(product.nutriScoreGrade, equals('c'));
      },
    );
  });
}
