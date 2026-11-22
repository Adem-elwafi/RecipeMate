import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipemate/core/providers/app_providers.dart';
import 'package:recipemate/features/collections/collections_screen.dart';

void main() {
  testWidgets('affiche un message quand l’utilisateur est déconnecté', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[currentUserProvider.overrideWithValue(null)],
        child: const MaterialApp(home: CollectionsScreen()),
      ),
    );

    expect(
      find.text('Connectez-vous pour voir vos collections.'),
      findsOneWidget,
    );
  });
}
