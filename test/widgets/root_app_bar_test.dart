import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipemate/core/config/app_assets.dart';
import 'package:recipemate/core/models/recipe.dart';
import 'package:recipemate/core/models/user_profile.dart';
import 'package:recipemate/core/providers/app_providers.dart';
import 'package:recipemate/features/explore/explore_screen.dart';
import 'package:recipemate/features/fridge/fridge_screen.dart';
import 'package:recipemate/features/home/home_screen.dart';
import 'package:recipemate/features/profile/profile_screen.dart';
import 'package:recipemate/features/recommendations/recommendations_screen.dart';

import '../helpers/svg_asset_finder.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDownAll(() => GoogleFonts.config.allowRuntimeFetching = true);

  final rootScreens = <String, Widget>{
    'Accueil': const HomeScreen(),
    'Explorer': const ExploreScreen(),
    'Mon frigo': const FridgeScreen(),
    'Recettes IA': const RecommendationsScreen(),
  };

  for (final entry in rootScreens.entries) {
    testWidgets('${entry.key} affiche l’en-tête commun RecipeMate', (
      tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: entry.value));

      expect(find.text('RecipeMate'), findsOneWidget);
      expect(findSvgAsset(appLogoAssetPath), findsOneWidget);
      expect(find.byTooltip('Profil'), findsOneWidget);
      expect(find.byTooltip('Paramètres'), findsOneWidget);
    });
  }

  testWidgets(
    'Profil affiche son en-tête dédié sans barre commune redondante',
    (tester) async {
      const profile = UserProfile(id: 'uid-test', name: 'Farah');

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            currentUidProvider.overrideWithValue('uid-test'),
            userProfileProvider.overrideWith(
              (ref, uid) => Stream<UserProfile?>.value(profile),
            ),
            favoriteIdsProvider.overrideWith(
              (ref, uid) => Stream<List<String>>.value(const <String>[]),
            ),
            userRecipesProvider.overrideWith(
              (ref, uid) => Stream<List<Recipe>>.value(const <Recipe>[]),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile_header')), findsOneWidget);
      expect(find.text('Mon profil'), findsOneWidget);
      expect(find.byTooltip('Retour'), findsOneWidget);
      expect(find.text('RecipeMate'), findsNothing);
      expect(findSvgAsset(appLogoAssetPath), findsNothing);
      expect(find.byTooltip('Profil'), findsNothing);
      expect(find.byTooltip('Paramètres'), findsNothing);
      expect(find.text('Paramètres'), findsOneWidget);
    },
  );
}
