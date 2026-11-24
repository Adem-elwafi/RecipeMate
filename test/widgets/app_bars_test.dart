import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipemate/core/config/app_assets.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/core/theme/app_theme.dart';
import 'package:recipemate/shared/widgets/recipemate_app_bar.dart';
import 'package:recipemate/shared/widgets/secondary_app_bar.dart';
import '../helpers/svg_asset_finder.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDownAll(() => GoogleFonts.config.allowRuntimeFetching = true);

  testWidgets(
    'RecipeMateAppBar affiche le nom, le logo et les deux raccourcis',
    (tester) async {
      var profileTaps = 0;
      var settingsTaps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: RecipeMateAppBar(
              onProfileTap: () => profileTaps++,
              onSettingsTap: () => settingsTaps++,
            ),
            body: const SizedBox.shrink(),
          ),
        ),
      );

      expect(find.text('RecipeMate'), findsOneWidget);
      expect(findSvgAsset(appLogoAssetPath), findsOneWidget);
      expect(find.byTooltip('Profil'), findsOneWidget);
      expect(find.byTooltip('Paramètres'), findsOneWidget);

      await tester.tap(find.byTooltip('Profil'));
      await tester.tap(find.byTooltip('Paramètres'));
      await tester.pump();

      expect(profileTaps, 1);
      expect(settingsTaps, 1);
    },
  );

  testWidgets(
    'RecipeMateAppBar masque le raccourci Profil sur la page Profil',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: RecipeMateAppBar(showProfile: false),
            body: SizedBox.shrink(),
          ),
        ),
      );

      expect(find.byTooltip('Profil'), findsNothing);
      expect(find.byTooltip('Paramètres'), findsOneWidget);
    },
  );

  testWidgets('RecipeMateAppBar reste lisible en thème sombre', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          appBar: RecipeMateAppBar(showProfile: false),
          body: SizedBox.shrink(),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('RecipeMate'), findsOneWidget);
    expect(findSvgAsset(appLogoAssetPath), findsOneWidget);
    // Le mark transparent est posé sur du crème : contraste conservé la nuit.
    expect(
      find.ancestor(
        of: findSvgAsset(appLogoAssetPath),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is DecoratedBox &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color == AppColors.cream,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('SecondaryAppBar affiche un titre et une flèche retour', (
    tester,
  ) async {
    var backTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: SecondaryAppBar(
            title: 'Paramètres',
            onBack: () => backTaps++,
          ),
          body: const SizedBox.shrink(),
        ),
      ),
    );

    expect(find.text('Paramètres'), findsOneWidget);
    expect(find.byTooltip('Retour'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

    await tester.tap(find.byTooltip('Retour'));
    await tester.pump();

    expect(backTaps, 1);
  });
}
