import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipemate/core/config/app_assets.dart';
import 'package:recipemate/features/onboarding/onboarding_screen.dart';

import '../../helpers/svg_asset_finder.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDownAll(() => GoogleFonts.config.allowRuntimeFetching = true);

  Future<void> persist() async {}

  testWidgets('affiche la premiere page et le badge de la deuxieme', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: OnboardingScreen(persistCompletion: persist)),
    );

    expect(find.text('Bienvenue sur RecipeMate'), findsOneWidget);
    expect(findSvgAsset(appLogoAssetPath), findsOneWidget);
    expect(find.text('Mangez sainement. Cuisinez malin.'), findsOneWidget);
    expect(find.text('Suivant'), findsOneWidget);
    expect(find.text('Commencer'), findsNothing);

    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();

    expect(find.text('Des recettes pensées pour vous'), findsOneWidget);
    expect(find.text('Végétarien – Sans gluten'), findsOneWidget);
    expect(find.text('Retour'), findsOneWidget);
  });

  testWidgets('Retour revient a la page precedente', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: OnboardingScreen(persistCompletion: persist)),
    );

    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retour'));
    await tester.pumpAndSettle();

    expect(find.text('Bienvenue sur RecipeMate'), findsOneWidget);
    expect(find.text('Retour'), findsNothing);
  });

  testWidgets('Commencer enregistre la fin et appelle onFinished', (
    tester,
  ) async {
    var finished = false;
    var persisted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          persistCompletion: () async => persisted = true,
          onFinished: () => finished = true,
        ),
      ),
    );

    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();

    expect(find.text('Cuisinez avec ce que vous avez déjà'), findsOneWidget);
    expect(find.text('Commencer'), findsOneWidget);

    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    expect(persisted, isTrue);
    expect(finished, isTrue);
  });

  testWidgets('Passer appelle onSkip et enregistre la fin', (tester) async {
    var skipped = false;
    var persisted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          persistCompletion: () async => persisted = true,
          onSkip: () => skipped = true,
        ),
      ),
    );

    await tester.tap(find.text('Passer'));
    await tester.pumpAndSettle();

    expect(persisted, isTrue);
    expect(skipped, isTrue);
  });
}
