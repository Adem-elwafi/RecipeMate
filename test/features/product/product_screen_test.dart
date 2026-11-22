import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/intl.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/features/fridge/providers/fridge_provider.dart';
import 'package:recipemate/features/product/product_screen.dart';
import 'package:recipemate/features/product/providers/product_provider.dart';
import 'package:recipemate/features/product/services/open_food_facts_service.dart';

void main() {
  group('ProductScreen Widget Tests', () {
    void setPhoneViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    Widget buildProductTestApp({
      String initialLocation = '/product/3760123456789',
      List<Override> overrides = const <Override>[],
      List<String>? userAllergies,
      void Function(ProviderContainer container)? onFridgeRouteBuilt,
    }) {
      final router = GoRouter(
        initialLocation: initialLocation,
        routes: [
          GoRoute(
            path: '/scanner',
            builder: (context, state) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => context.push('/product/3760123456789'),
                  child: const Text('ScannerStub'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/fridge',
            builder: (context, state) => Consumer(
              builder: (context, ref, child) {
                onFridgeRouteBuilt?.call(ProviderScope.containerOf(context));
                final items = ref.watch(fridgeProvider).items;
                return Scaffold(
                  body: Center(
                    child: Text('FridgeStub:${items.first.ingredient.name}'),
                  ),
                );
              },
            ),
          ),
          GoRoute(
            path: '/product/:barcode',
            builder: (context, state) {
              final barcode = state.pathParameters['barcode'] ?? '';
              return ProductScreen(
                barcode: barcode,
                userAllergies: userAllergies,
              );
            },
          ),
        ],
      );
      addTearDown(router.dispose);

      return ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets(
      'Renders Yaourt grec nature 0 % details, Nutri-Score A, nutrition, allergens, ingredients, and attribution',
      (tester) async {
        setPhoneViewport(tester);
        await tester.pumpWidget(buildProductTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Ferme des Oliviers'), findsOneWidget);
        expect(find.text('Yaourt grec nature 0 %'), findsOneWidget);
        expect(find.text('500 g · EAN 3 760 123 456 789'), findsOneWidget);

        // Nutri-Score card
        expect(find.text('Nutri-Score'), findsOneWidget);
        expect(find.text('Très bonne qualité nutritionnelle'), findsOneWidget);
        expect(find.bySemanticsLabel('Nutri-Score A'), findsOneWidget);
        for (final grade in const <String>['A', 'B', 'C', 'D', 'E']) {
          expect(find.text(grade), findsOneWidget);
        }

        // Nutritional values card
        expect(find.text('Valeurs nutritionnelles'), findsOneWidget);
        expect(find.text('pour 100 g'), findsOneWidget);
        expect(find.text('Énergie'), findsOneWidget);
        expect(find.text('57 kcal'), findsOneWidget);
        expect(find.text('Protéines'), findsOneWidget);
        expect(find.text('10,3 g'), findsOneWidget);
        expect(find.text('Glucides'), findsOneWidget);
        expect(find.text('dont sucres'), findsOneWidget);
        expect(find.text('3,6 g'), findsNWidgets(2));
        expect(find.text('Lipides'), findsOneWidget);
        expect(find.text('0,2 g'), findsOneWidget);
        expect(find.text('Sel'), findsOneWidget);
        expect(find.text('0,09 g'), findsOneWidget);

        // Allergens card
        expect(find.text('Allergènes'), findsOneWidget);
        expect(find.text('Lait'), findsOneWidget);
        expect(
          find.text('Compatible avec vos allergies déclarées'),
          findsOneWidget,
        );

        // Ingredients card (preserves plain text while bolding allergens)
        expect(find.text('Ingrédients'), findsOneWidget);
        expect(
          find.text(
            'Lait écrémé pasteurisé, protéines de lait, ferments lactiques '
            '(dont Lactobacillus bulgaricus et Streptococcus thermophilus).',
          ),
          findsOneWidget,
        );

        // Quantity & expiration card
        final expectedDate = DateFormat('dd/MM/yyyy').format(
          DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          ).add(const Duration(days: 12)),
        );
        expect(find.text('Quantité'), findsOneWidget);
        expect(find.text('1 × 500 g'), findsOneWidget);
        expect(find.text('À consommer avant'), findsOneWidget);
        expect(find.text(expectedDate), findsOneWidget);

        // Attribution & sticky bottom CTA
        expect(
          find.text('Source : base collaborative Open Food Facts.'),
          findsOneWidget,
        );
        expect(find.text('Ajouter à mon frigo'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Displays loading indicator and French label while fetching product',
      (tester) async {
        setPhoneViewport(tester);
        final completer = Completer<http.Response>();

        final mockClient = MockClient((request) => completer.future);

        await tester.pumpWidget(
          buildProductTestApp(
            initialLocation: '/product/3123456789012',
            overrides: [
              openFoodFactsServiceProvider.overrideWithValue(
                OpenFoodFactsService(client: mockClient),
              ),
            ],
          ),
        );
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        final indicator = tester.widget<CircularProgressIndicator>(
          find.byType(CircularProgressIndicator),
        );
        expect(indicator.color, AppColors.primary);
        expect(find.text('Recherche sur Open Food Facts...'), findsOneWidget);

        completer.complete(
          http.Response(
            jsonEncode(<String, Object?>{
              'status': 1,
              'product': <String, Object?>{
                'product_name_fr': 'Skyr nature',
                'brands': 'Siggi',
                'quantity': '450 g',
                'nutriscore_grade': 'a',
              },
            }),
            200,
            headers: const <String, String>{
              'content-type': 'application/json; charset=utf-8',
            },
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Skyr nature'), findsOneWidget);
      },
    );

    testWidgets(
      'Stepper updates quantity, date picker updates date, and Ajouter à mon frigo adds FridgeItem and navigates to /fridge',
      (tester) async {
        setPhoneViewport(tester);
        late ProviderContainer capturedContainer;

        await tester.pumpWidget(
          buildProductTestApp(
            onFridgeRouteBuilt: (container) {
              capturedContainer = container;
            },
          ),
        );
        await tester.pumpAndSettle();

        // Stepper interaction: 1 -> 2 -> 1 -> 2
        final incrementButton = find.byTooltip('Augmenter la quantité');
        final decrementButton = find.byTooltip('Diminuer la quantité');
        await tester.ensureVisible(incrementButton);
        await tester.tap(incrementButton);
        await tester.pump();
        expect(find.text('2 × 500 g'), findsOneWidget);

        await tester.tap(decrementButton);
        await tester.pump();
        expect(find.text('1 × 500 g'), findsOneWidget);

        await tester.tap(incrementButton);
        await tester.pump();
        expect(find.text('2 × 500 g'), findsOneWidget);

        // Date picker interaction
        final initialDate = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        ).add(const Duration(days: 12));
        final initialFormatted = DateFormat('dd/MM/yyyy').format(initialDate);

        await tester.ensureVisible(find.text(initialFormatted));
        await tester.tap(find.text(initialFormatted));
        await tester.pumpAndSettle();

        expect(find.text('À consommer avant'), findsWidgets);
        await tester.tap(find.text('Valider'));
        await tester.pumpAndSettle();

        // Tap sticky CTA
        await tester.tap(find.text('Ajouter à mon frigo'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.text('FridgeStub:Yaourt grec nature 0 %'), findsOneWidget);
        expect(
          find.text('Yaourt grec nature 0 % ajouté à votre frigo'),
          findsOneWidget,
        );

        final fridgeItems = capturedContainer.read(fridgeProvider).items;
        final added = fridgeItems.first;
        expect(added.id, startsWith('fi_3760123456789_'));
        expect(added.ingredient.id, equals('off_3760123456789'));
        expect(added.ingredient.name, equals('Yaourt grec nature 0 %'));
        expect(added.quantity, equals(1000.0));
        expect(added.unit, equals('g'));
        expect(added.expirationDate, equals(initialDate));
      },
    );

    testWidgets(
      'Renders French error state for unknown barcode and retries successfully',
      (tester) async {
        setPhoneViewport(tester);
        var callCount = 0;

        final mockClient = MockClient((request) async {
          callCount++;
          if (callCount == 1) {
            return http.Response(
              jsonEncode(<String, Object?>{'status': 0}),
              200,
            );
          }
          return http.Response(
            jsonEncode(<String, Object?>{
              'status': 1,
              'product': <String, Object?>{
                'product_name_fr': 'Compote pomme sans sucre',
                'brands': 'Andros',
                'quantity': '400 g',
                'nutriscore_grade': 'a',
              },
            }),
            200,
            headers: const <String, String>{
              'content-type': 'application/json; charset=utf-8',
            },
          );
        });

        await tester.pumpWidget(
          buildProductTestApp(
            initialLocation: '/product/9999999999999',
            overrides: [
              openFoodFactsServiceProvider.overrideWithValue(
                OpenFoodFactsService(client: mockClient),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Produit introuvable'), findsOneWidget);
        expect(
          find.text('Aucun produit trouvé pour le code-barres 9999999999999.'),
          findsOneWidget,
        );
        expect(find.text('Réessayer'), findsOneWidget);
        expect(find.text('Retour'), findsOneWidget);

        await tester.tap(find.text('Réessayer'));
        await tester.pumpAndSettle();

        expect(callCount, equals(2));
        expect(find.text('Compote pomme sans sucre'), findsOneWidget);
        expect(find.text('Andros'), findsOneWidget);
      },
    );

    testWidgets(
      'Shows allergy conflict warning when user allergies match product allergens',
      (tester) async {
        setPhoneViewport(tester);
        await tester.pumpWidget(
          buildProductTestApp(userAllergies: const <String>['Lait']),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Attention : contient un allergène de votre profil'),
          findsOneWidget,
        );
        expect(
          find.text('Compatible avec vos allergies déclarées'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'Renders empty allergens chip, Nutri-Score C, missing nutrients dash, image fallback, and offline demo badge',
      (tester) async {
        setPhoneViewport(tester);
        final mockClient = MockClient((request) async {
          if (request.url.path.contains('3017620422003')) {
            throw const SocketException('offline');
          }
          return http.Response(
            jsonEncode(<String, Object?>{
              'status': 1,
              'product': <String, Object?>{
                'product_name_fr': 'Soupe de légumes',
                'brands': 'Maison Bio',
                'quantity': '1 L',
                'nutriscore_grade': 'c',
                'image_front_url': 'https://example.com/soup.png',
                'allergens_tags': <Object?>[],
                'nutriments': <String, Object?>{'energy-kcal_100g': 38},
              },
            }),
            200,
            headers: const <String, String>{
              'content-type': 'application/json; charset=utf-8',
            },
          );
        });

        await tester.pumpWidget(
          buildProductTestApp(
            initialLocation: '/product/3210000000001',
            overrides: [
              openFoodFactsServiceProvider.overrideWithValue(
                OpenFoodFactsService(client: mockClient),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Soupe de légumes'), findsOneWidget);
        expect(find.text('Qualité nutritionnelle moyenne'), findsOneWidget);
        expect(find.bySemanticsLabel('Nutri-Score C'), findsOneWidget);
        expect(find.text('Aucun allergène déclaré'), findsOneWidget);
        expect(find.text('38 kcal'), findsOneWidget);
        expect(find.text('—'), findsNWidgets(5));
        expect(tester.takeException(), isNull);

        // Verify offline demo fallback badge on Ferrero demo product.
        await tester.pumpWidget(
          buildProductTestApp(
            initialLocation: '/product/3017620422003',
            overrides: [
              openFoodFactsServiceProvider.overrideWithValue(
                OpenFoodFactsService(client: mockClient),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('Données de démonstration hors ligne'),
          findsOneWidget,
        );
        expect(find.text('Pâte à tartiner aux noisettes'), findsOneWidget);
      },
    );

    testWidgets(
      'Back button navigates to /scanner when stack cannot pop and pops when pushed',
      (tester) async {
        setPhoneViewport(tester);
        await tester.pumpWidget(buildProductTestApp());
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Retour'));
        await tester.pumpAndSettle();

        expect(find.text('ScannerStub'), findsOneWidget);

        await tester.tap(find.text('ScannerStub'));
        await tester.pumpAndSettle();
        expect(find.text('Yaourt grec nature 0 %'), findsOneWidget);

        await tester.tap(find.byTooltip('Retour'));
        await tester.pumpAndSettle();
        expect(find.text('ScannerStub'), findsOneWidget);
      },
    );
  });
}
