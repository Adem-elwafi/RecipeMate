import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipemate/core/config/app_assets.dart';
import 'package:recipemate/core/services/startup_resolver.dart';
import 'package:recipemate/features/splash/splash_screen.dart';
import '../../helpers/svg_asset_finder.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDownAll(() => GoogleFonts.config.allowRuntimeFetching = true);

  testWidgets('affiche le branding puis envoie la destination', (tester) async {
    SplashDestination? destination;
    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          duration: const Duration(milliseconds: 200),
          resolveDestination: () async => SplashDestination.auth,
          onDestination: (value) => destination = value,
        ),
      ),
    );

    expect(find.text('RecipeMate'), findsOneWidget);
    // Point 9 : plus aucun texte anglais, le logo SVG est affiché au centre.
    expect(find.text('Eat healthy. Cook smarter.'), findsNothing);
    expect(find.text('Mangez sainement. Cuisinez malin.'), findsOneWidget);
    expect(findSvgAsset(appSplashLogoAssetPath), findsOneWidget);
    expect(destination, isNull);

    await tester.pump(const Duration(milliseconds: 250));

    expect(destination, SplashDestination.auth);
  });
}
