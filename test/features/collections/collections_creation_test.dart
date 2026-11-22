import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipemate/core/models/recipe.dart';
import 'package:recipemate/core/models/recipe_collection.dart';
import 'package:recipemate/core/providers/app_providers.dart';
import 'package:recipemate/core/services/firestore_service.dart';
import 'package:recipemate/features/collections/collections_screen.dart';

/// Service en mémoire : reproduit le flux de création sans Firebase.
class _FakeFirestoreService extends FirestoreService {
  final StreamController<List<RecipeCollection>> _controller =
      StreamController<List<RecipeCollection>>.broadcast();
  final List<RecipeCollection> _collections = <RecipeCollection>[];
  int _nextId = 1;

  Future<void> dispose() => _controller.close();

  @override
  Stream<List<RecipeCollection>> watchCollections(String uid) async* {
    // Valeur initiale indispensable : sans elle l'écran reste en chargement
    // et le CircularProgressIndicator empêche pumpAndSettle de terminer.
    yield List<RecipeCollection>.unmodifiable(_collections);
    yield* _controller.stream;
  }

  @override
  Future<RecipeCollection> createCollection(String uid, String name) async {
    final collection = RecipeCollection(
      id: 'col_${_nextId++}',
      name: name.trim(),
      recipeIds: const <String>[],
      createdAt: DateTime.now(),
    );
    _collections.insert(0, collection);
    _controller.add(List<RecipeCollection>.unmodifiable(_collections));
    return collection;
  }

  @override
  Stream<List<Recipe>> watchUserRecipes(String uid) =>
      Stream<List<Recipe>>.value(const <Recipe>[]);

  @override
  Stream<List<Recipe>> watchSharedRecipes() =>
      Stream<List<Recipe>>.value(const <Recipe>[]);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDownAll(() => GoogleFonts.config.allowRuntimeFetching = true);

  testWidgets('crée quatre collections à la suite sans crash de widget', (
    tester,
  ) async {
    final fake = _FakeFirestoreService();
    addTearDown(fake.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          currentUidProvider.overrideWithValue('uid-test'),
          firestoreServiceProvider.overrideWithValue(fake),
        ],
        child: const MaterialApp(home: CollectionsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    for (var index = 1; index <= 4; index++) {
      final name = 'Collection $index';

      await tester.tap(find.byTooltip('Créer une collection'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), name);
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(find.text(name), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    expect(find.text('Collection 4'), findsOneWidget);
    expect(find.text('Collection 1'), findsOneWidget);
  });
}
