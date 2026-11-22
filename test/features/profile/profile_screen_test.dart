import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
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
}
