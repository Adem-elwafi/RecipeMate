import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipemate/core/providers/app_providers.dart';
import 'package:recipemate/features/profile/settings_screen.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDownAll(() => GoogleFonts.config.allowRuntimeFetching = true);

  testWidgets('affiche les réglages sans nécessiter de session Firebase', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[currentUserProvider.overrideWithValue(null)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    expect(find.text('Paramètres'), findsOneWidget);
    expect(find.text('Non connecté'), findsOneWidget);
    expect(find.text('Apparence'), findsOneWidget);
    expect(find.text('Mode clair'), findsOneWidget);
    expect(find.text('Mode sombre'), findsOneWidget);
    expect(find.text('Suivre le système'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(find.text('Se déconnecter'), findsOneWidget);
    expect(find.text('Supprimer mon compte'), findsOneWidget);
  });
}
