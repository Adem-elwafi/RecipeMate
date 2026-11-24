import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipemate/features/recipe_details/recipe_details_screen.dart';

void main() {
  testWidgets('the recipe page match percentage follows the checkboxes', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: RecipeDetailsScreen(recipeId: 'rec_1')),
      ),
    );
    await tester.pumpAndSettle();

    // Recette du jour: 5 ingrédients, 4 dans le frigo (sans l'huile d'olive).
    expect(find.text('80% d’ingrédients disponibles'), findsOneWidget);

    // Cocher l'ingrédient restant (5e case) augmente le pourcentage.
    await tester.ensureVisible(find.byType(Checkbox).at(4));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).at(4));
    await tester.pumpAndSettle();
    expect(find.text('100% d’ingrédients disponibles'), findsOneWidget);

    // Éviter un ingrédient (décocher le poulet) diminue le pourcentage.
    await tester.ensureVisible(find.byType(Checkbox).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).at(0));
    await tester.pumpAndSettle();
    expect(find.text('80% d’ingrédients disponibles'), findsOneWidget);
  });
}
