import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipemate/features/add_recipe/add_recipe_screen.dart';
import 'package:recipemate/shared/widgets/app_text_field.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDownAll(() => GoogleFonts.config.allowRuntimeFetching = true);

  testWidgets('affiche les sections du formulaire', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AddRecipeScreen())),
    );

    expect(find.text('Ajouter une recette'), findsOneWidget);
    expect(find.text('Informations générales'), findsOneWidget);
    expect(find.text('Ingrédients'), findsOneWidget);
    expect(find.text('Étapes de préparation'), findsOneWidget);
    expect(find.text('Enregistrer la recette'), findsOneWidget);
  });

  testWidgets('valide les champs avant toute sauvegarde Firebase', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AddRecipeScreen())),
    );

    final saveButton = find.text('Enregistrer la recette');
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Le nom de la recette est obligatoire.'), findsOneWidget);
    expect(find.text('La description est obligatoire.'), findsOneWidget);
    expect(find.text('L’ingrédient est obligatoire.'), findsOneWidget);
    expect(find.text('L’étape est obligatoire.'), findsOneWidget);
  });

  testWidgets('ajoute et supprime dynamiquement un ingrédient', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AddRecipeScreen())),
    );

    expect(find.text('Ingrédient 1'), findsOneWidget);
    final addButton = find.text('Ajouter un ingrédient');
    await tester.ensureVisible(addButton);
    await tester.pumpAndSettle();
    await tester.tap(addButton);
    await tester.pumpAndSettle();
    expect(find.text('Ingrédient 2'), findsOneWidget);

    final removeButtons = find.byTooltip('Supprimer cet ingrédient');
    expect(removeButtons, findsNWidgets(2));
    await tester.ensureVisible(removeButtons.first);
    await tester.pumpAndSettle();
    await tester.tap(removeButtons.first);
    await tester.pumpAndSettle();
    expect(find.text('Ingrédient 2'), findsNothing);
  });

  testWidgets('affiche les champs E11 (photo, difficulté, fibres)', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AddRecipeScreen())),
    );

    expect(find.text('Photo de la recette'), findsOneWidget);
    expect(find.text('Galerie'), findsOneWidget);
    expect(find.text('Appareil photo'), findsOneWidget);
    expect(find.text('Difficulté'), findsOneWidget);
    expect(find.text('Fibres (g, facultatif)'), findsOneWidget);

    final category = find.byType(DropdownButtonFormField<String>).first;
    await tester.ensureVisible(category);
    await tester.pumpAndSettle();
    await tester.tap(category);
    await tester.pumpAndSettle();
    expect(find.text('Entrées'), findsWidgets);
    expect(find.text('Snacks'), findsOneWidget);
  });

  testWidgets('permet de réordonner les étapes sans perdre le texte', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AddRecipeScreen())),
    );

    final addStep = find.text('Ajouter une étape');
    await tester.ensureVisible(addStep);
    await tester.pumpAndSettle();
    await tester.tap(addStep);
    await tester.pumpAndSettle();

    Future<void> fillStep(String label, String text) async {
      final labelFinder = find.text(label);
      await tester.ensureVisible(labelFinder);
      await tester.pumpAndSettle();
      final field = find.descendant(
        of: find.ancestor(of: labelFinder, matching: find.byType(AppTextField)),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(field, text);
      await tester.pumpAndSettle();
    }

    await fillStep('Étape 1', 'Première');
    await fillStep('Étape 2', 'Deuxième');

    final moveDown = find.byTooltip('Descendre cette étape').first;
    await tester.ensureVisible(moveDown);
    await tester.pumpAndSettle();
    await tester.tap(moveDown);
    await tester.pumpAndSettle();

    final firstField = find.descendant(
      of: find.ancestor(
        of: find.text('Étape 1'),
        matching: find.byType(AppTextField),
      ),
      matching: find.byType(TextFormField),
    );
    expect(
      tester.widget<TextFormField>(firstField).controller!.text,
      'Deuxième',
    );
  });
}
