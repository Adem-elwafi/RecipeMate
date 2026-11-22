import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/features/product/providers/product_provider.dart';
import 'package:recipemate/features/product/services/open_food_facts_service.dart';
import 'package:recipemate/features/scanner/scanner_screen.dart';
import 'package:recipemate/shared/widgets/app_text_field.dart';

void main() {
  group('ScannerScreen Widget Tests', () {
    void setPhoneViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    Widget buildScannerTestApp({
      String initialLocation = '/scanner',
      List<Override> overrides = const <Override>[],
      GoRouter? customRouter,
    }) {
      final router =
          customRouter ??
          GoRouter(
            initialLocation: initialLocation,
            routes: [
              GoRoute(
                path: '/fridge',
                builder: (context, state) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () => context.push('/scanner'),
                      child: const Text('FridgeScreenStub'),
                    ),
                  ),
                ),
              ),
              GoRoute(
                path: '/scanner',
                builder: (context, state) =>
                    const ScannerScreen(useLiveCamera: false),
              ),
              GoRoute(
                path: '/product/:barcode',
                builder: (context, state) {
                  final barcode = state.pathParameters['barcode'] ?? '';
                  return Scaffold(
                    body: Center(child: Text('ProductRoute:$barcode')),
                  );
                },
              ),
            ],
          );
      if (customRouter == null) {
        addTearDown(router.dispose);
      }

      return ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets(
      'Renders French title, instructions, viewfinder, and seeded product card',
      (tester) async {
        setPhoneViewport(tester);
        await tester.pumpWidget(buildScannerTestApp());
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Scanner'), findsOneWidget);
        expect(
          find.text("Scannez le code-barres d'un produit"),
          findsOneWidget,
        );
        expect(
          find.text(
            'Centrez le code dans le cadre, il sera détecté automatiquement.',
          ),
          findsOneWidget,
        );
        expect(find.text('Produit détecté'), findsOneWidget);
        expect(find.text('Yaourt grec nature 0 %'), findsOneWidget);
        expect(find.text('Ferme des Oliviers · 500 g'), findsOneWidget);
        expect(find.text('A'), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('Nutri-Score A')), findsOneWidget);
        expect(find.text('Saisir le code manuellement'), findsOneWidget);
        expect(find.text('Données produits : Open Food Facts'), findsOneWidget);

        // Advance animation slightly to ensure laser animation ticks cleanly.
        await tester.pump(const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Renders without overflow on compact 800x600 viewport', (
      tester,
    ) async {
      await tester.pumpWidget(buildScannerTestApp());
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Scanner'), findsOneWidget);
      expect(find.text('Yaourt grec nature 0 %'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Torch toggle updates button state and highlight color', (
      tester,
    ) async {
      setPhoneViewport(tester);
      await tester.pumpWidget(buildScannerTestApp());
      await tester.pump();

      final torchFinder = find.byTooltip('Lampe torche');
      expect(torchFinder, findsOneWidget);
      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
      expect(find.byIcon(Icons.flash_on_rounded), findsNothing);

      final offMaterial = tester.widget<Material>(
        find.descendant(of: torchFinder, matching: find.byType(Material)).first,
      );
      expect(offMaterial.color, isNot(AppColors.orangeAccent));

      await tester.tap(torchFinder);
      await tester.pump();

      expect(find.byIcon(Icons.flash_on_rounded), findsOneWidget);
      expect(find.byIcon(Icons.bolt_rounded), findsNothing);
      final onMaterial = tester.widget<Material>(
        find.descendant(of: torchFinder, matching: find.byType(Material)).first,
      );
      expect(onMaterial.color, AppColors.orangeAccent);

      await tester.tap(torchFinder);
      await tester.pump();

      expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
      expect(find.byIcon(Icons.flash_on_rounded), findsNothing);
    });

    testWidgets(
      'Tapping detected product card navigates to /product/:barcode',
      (tester) async {
        setPhoneViewport(tester);
        await tester.pumpWidget(buildScannerTestApp());
        await tester.pump();

        await tester.tap(find.text('Yaourt grec nature 0 %'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.text('ProductRoute:3760123456789'), findsOneWidget);
      },
    );

    testWidgets('Close button navigates back or falls back to /fridge', (
      tester,
    ) async {
      setPhoneViewport(tester);

      // Case 1: cannot pop -> falls back to /fridge.
      await tester.pumpWidget(buildScannerTestApp());
      await tester.pump();

      await tester.tap(find.byTooltip('Fermer'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('FridgeScreenStub'), findsOneWidget);

      // Case 2: pushed onto stack -> pops cleanly back to /fridge.
      await tester.tap(find.text('FridgeScreenStub'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Scanner'), findsOneWidget);

      await tester.tap(find.byTooltip('Fermer'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('FridgeScreenStub'), findsOneWidget);
    });

    testWidgets(
      'Manual entry sheet renders input, validation, and 4 demo chips',
      (tester) async {
        setPhoneViewport(tester);
        await tester.pumpWidget(buildScannerTestApp());
        await tester.pump();

        await tester.tap(find.text('Saisir le code manuellement'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.text('Saisir un code-barres'), findsOneWidget);
        expect(find.byType(AppTextField), findsOneWidget);
        expect(find.text('Ex : 3760123456789'), findsOneWidget);
        expect(find.text('Rechercher'), findsOneWidget);
        expect(
          find.text("Ou tester un code-barres d'exemple :"),
          findsOneWidget,
        );

        for (final demo in OpenFoodFactsService.demoProducts) {
          expect(
            find.descendant(
              of: find.byType(BottomSheet),
              matching: find.text(demo.name),
            ),
            findsOneWidget,
          );
        }

        // Empty submission triggers French validation feedback.
        await tester.tap(find.text('Rechercher'));
        await tester.pump();
        expect(find.text('Veuillez saisir un code-barres.'), findsOneWidget);

        // Non-numeric submission triggers French numeric validation.
        await tester.enterText(find.byType(TextFormField), 'abc123');
        await tester.tap(find.text('Rechercher'));
        await tester.pump();
        expect(
          find.text('Le code-barres doit contenir uniquement des chiffres.'),
          findsOneWidget,
        );

        // Valid numeric code closes sheet and navigates to /product/:barcode.
        await tester.enterText(find.byType(TextFormField), '3017620422003');
        await tester.tap(find.text('Rechercher'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.text('Saisir un code-barres'), findsNothing);
        expect(find.text('ProductRoute:3017620422003'), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping a demo chip in manual sheet closes sheet and navigates to product',
      (tester) async {
        setPhoneViewport(tester);
        await tester.pumpWidget(buildScannerTestApp());
        await tester.pump();

        await tester.tap(find.text('Saisir le code manuellement'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        final targetDemo = OpenFoodFactsService.demoProducts[2];
        await tester.tap(
          find.descendant(
            of: find.byType(BottomSheet),
            matching: find.text(targetDemo.name),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.text('Saisir un code-barres'), findsNothing);
        expect(find.text('ProductRoute:${targetDemo.barcode}'), findsOneWidget);
      },
    );

    testWidgets(
      'handleBarcodeCapture fetches product, debounces duplicates, and handles errors',
      (tester) async {
        setPhoneViewport(tester);
        var requestCount = 0;
        final pendingResponse = Completer<http.Response>();

        final mockClient = MockClient((request) async {
          requestCount++;
          if (request.url.path.contains('3017620422003')) {
            return pendingResponse.future;
          }
          return http.Response(jsonEncode(<String, Object?>{'status': 0}), 200);
        });

        await tester.pumpWidget(
          buildScannerTestApp(
            overrides: [
              openFoodFactsServiceProvider.overrideWithValue(
                OpenFoodFactsService(client: mockClient),
              ),
            ],
          ),
        );
        await tester.pump();

        final state = tester.state<ScannerScreenState>(
          find.byType(ScannerScreen),
        );

        // Start async barcode fetch and verify loading label.
        final firstScan = state.handleBarcodeCapture(
          const BarcodeCapture(
            barcodes: <Barcode>[Barcode(rawValue: '3017620422003')],
          ),
        );
        await tester.pump();
        expect(find.text('Recherche en cours...'), findsOneWidget);

        // Duplicate capture while loading or inside debounce window is ignored.
        await state.handleBarcodeCapture(
          const BarcodeCapture(
            barcodes: <Barcode>[Barcode(rawValue: '3017620422003')],
          ),
        );

        pendingResponse.complete(
          http.Response(
            jsonEncode(<String, Object?>{
              'status': 1,
              'product': <String, Object?>{
                'product_name_fr': 'Pâte à tartiner aux noisettes',
                'brands': 'Ferrero',
                'quantity': '400 g',
                'nutriscore_grade': 'e',
              },
            }),
            200,
            headers: const <String, String>{
              'content-type': 'application/json; charset=utf-8',
            },
          ),
        );
        await firstScan;
        await tester.pump();

        expect(find.text('Produit détecté'), findsOneWidget);
        expect(find.text('Pâte à tartiner aux noisettes'), findsOneWidget);
        expect(find.text('Ferrero · 400 g'), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp('Nutri-Score E')), findsOneWidget);
        expect(requestCount, equals(1));

        // Same barcode immediately afterward is debounced.
        await state.handleBarcodeCapture(
          const BarcodeCapture(
            barcodes: <Barcode>[Barcode(rawValue: '3017620422003')],
          ),
        );
        expect(requestCount, equals(1));

        // Unknown barcode shows French error SnackBar and keeps previous preview.
        await state.handleBarcodeCapture(
          const BarcodeCapture(
            barcodes: <Barcode>[Barcode(rawValue: '9999999999999')],
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(
          find.text('Aucun produit trouvé pour le code-barres 9999999999999.'),
          findsOneWidget,
        );
        expect(find.text('Pâte à tartiner aux noisettes'), findsOneWidget);
      },
    );
  });
}
