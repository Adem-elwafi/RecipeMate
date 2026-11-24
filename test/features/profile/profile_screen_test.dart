import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipemate/core/models/recipe.dart';
import 'package:recipemate/core/models/user_profile.dart';
import 'package:recipemate/core/providers/app_providers.dart';
import 'package:recipemate/features/profile/profile_screen.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDownAll(() => GoogleFonts.config.allowRuntimeFetching = true);

  testWidgets('invite à se connecter quand aucun utilisateur n’est actif', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[currentUserProvider.overrideWithValue(null)],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );

    expect(find.text('Mon profil'), findsWidgets);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsNothing);
  });

  testWidgets('affiche les vraies données Firebase dans l’en-tête', (
    tester,
  ) async {
    const profile = UserProfile(
      id: 'uid-1',
      name: 'Lea Martin',
      email: 'lea@example.com',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          currentUidProvider.overrideWithValue('uid-1'),
          userProfileProvider.overrideWith((_, __) => Stream.value(profile)),
          favoriteIdsProvider.overrideWith((_, __) => Stream.value(<String>[])),
          userRecipesProvider.overrideWith((_, __) => Stream.value(<Recipe>[])),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile_header')), findsOneWidget);
    expect(find.byKey(const Key('profile_back_button')), findsOneWidget);
    expect(find.byKey(const Key('profile_photo_button')), findsOneWidget);
    expect(find.text('Mon profil'), findsOneWidget);
    expect(find.text('Lea Martin'), findsOneWidget);
    expect(find.text('lea@example.com'), findsOneWidget);
    expect(find.text('LM'), findsOneWidget);
    expect(find.byKey(const Key('edit_profile_button')), findsOneWidget);
  });
}
