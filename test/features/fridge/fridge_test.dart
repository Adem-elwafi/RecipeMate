import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipemate/core/data/mock_data.dart';
import 'package:recipemate/core/models/fridge_item.dart';
import 'package:recipemate/core/models/ingredient.dart';
import 'package:recipemate/features/fridge/fridge_screen.dart';
import 'package:recipemate/features/fridge/providers/fridge_provider.dart';
import 'package:recipemate/features/fridge/widgets/fridge_item_card.dart';

void main() {
  group('FridgeState & FridgeNotifier Unit Tests', () {
    test('mapIngredientCategoryToFilter maps all ingredient categories', () {
      expect(
        mapIngredientCategoryToFilter(IngredientCategory.vegetables),
        FridgeCategoryFilter.vegetables,
      );
      expect(
        mapIngredientCategoryToFilter(IngredientCategory.fruits),
        FridgeCategoryFilter.fruits,
      );
      expect(
        mapIngredientCategoryToFilter(IngredientCategory.meat),
        FridgeCategoryFilter.meatFish,
      );
      expect(
        mapIngredientCategoryToFilter(IngredientCategory.fish),
        FridgeCategoryFilter.meatFish,
      );
      expect(
        mapIngredientCategoryToFilter(IngredientCategory.dairy),
        FridgeCategoryFilter.dairy,
      );
      expect(
        mapIngredientCategoryToFilter(IngredientCategory.grains),
        FridgeCategoryFilter.other,
      );
      expect(
        mapIngredientCategoryToFilter(IngredientCategory.spices),
        FridgeCategoryFilter.other,
      );
      expect(
        mapIngredientCategoryToFilter(IngredientCategory.bakery),
        FridgeCategoryFilter.other,
      );
      expect(
        mapIngredientCategoryToFilter(IngredientCategory.other),
        FridgeCategoryFilter.other,
      );
    });

    test('kFridgeIngredientSuggestions provides rich common ingredients', () {
      expect(kFridgeIngredientSuggestions.length, greaterThanOrEqualTo(18));
      final names = kFridgeIngredientSuggestions.map((i) => i.name).toList();
      expect(names, containsAll(<String>['Courgette', 'Courge butternut']));
    });

    test('Initial state seeds all categories and computes stats correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(fridgeProvider);
      expect(state.selectedCategory, FridgeCategoryFilter.all);
      expect(state.totalCount, state.items.length);
      expect(state.totalCount, greaterThanOrEqualTo(12));
      expect(
        state.expiringSoonCount,
        state.items.where((item) => item.isExpiringSoon).length,
      );

      final grouped = state.groupedItems;
      expect(grouped.keys.toList(), <FridgeCategoryFilter>[
        FridgeCategoryFilter.vegetables,
        FridgeCategoryFilter.fruits,
        FridgeCategoryFilter.meatFish,
        FridgeCategoryFilter.dairy,
        FridgeCategoryFilter.other,
      ]);
      for (final group in grouped.values) {
        expect(group, isNotEmpty);
      }

      // Items without expiration date are sorted to the end.
      final filtered = state.filteredItems;
      expect(filtered.last.hasExpirationDate, isFalse);
      final dated = filtered.where((item) => item.hasExpirationDate).toList();
      for (var i = 0; i < dated.length - 1; i++) {
        expect(
          dated[i].expirationDate.compareTo(dated[i + 1].expirationDate) <= 0,
          isTrue,
        );
      }
    });

    test('addItem adds a new item and updates totals and groups', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(fridgeProvider.notifier);
      final initialCount = container.read(fridgeProvider).totalCount;
      final now = DateTime.now();

      final newItem = FridgeItem(
        id: 'fi_test_broccoli',
        ingredient: const Ingredient(
          id: 'ing_broccoli',
          name: 'Brocoli',
          category: IngredientCategory.vegetables,
          defaultUnit: 'pièce',
        ),
        quantity: 2,
        unit: 'pièce',
        expirationDate: DateTime(now.year, now.month, now.day + 1),
      );

      notifier.addItem(newItem);
      final updated = container.read(fridgeProvider);

      expect(updated.totalCount, initialCount + 1);
      expect(updated.items.any((i) => i.id == 'fi_test_broccoli'), isTrue);
      expect(
        updated.groupedItems[FridgeCategoryFilter.vegetables]!.any(
          (i) => i.id == 'fi_test_broccoli',
        ),
        isTrue,
      );
    });

    test('updateItem modifies existing item quantity and expiration', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(fridgeProvider.notifier);
      final target = container
          .read(fridgeProvider)
          .items
          .firstWhere((i) => i.id == 'fi_carrots');
      final now = DateTime.now();

      final updatedItem = target.copyWith(
        quantity: 10,
        expirationDate: DateTime(now.year, now.month, now.day + 1),
      );

      final soonBefore = container.read(fridgeProvider).expiringSoonCount;
      notifier.updateItem(updatedItem);

      final nextState = container.read(fridgeProvider);
      final stored = nextState.items.firstWhere((i) => i.id == 'fi_carrots');
      expect(stored.quantity, 10);
      expect(stored.isExpiringSoon, isTrue);
      expect(nextState.expiringSoonCount, soonBefore + 1);
    });

    test('removeItem and restoreItem update state cleanly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(fridgeProvider.notifier);
      final initialCount = container.read(fridgeProvider).totalCount;
      final removedTarget = container.read(fridgeProvider).items.first;

      notifier.removeItem(removedTarget.id);
      expect(container.read(fridgeProvider).totalCount, initialCount - 1);
      expect(
        container
            .read(fridgeProvider)
            .items
            .any((i) => i.id == removedTarget.id),
        isFalse,
      );

      notifier
        ..restoreItem(removedTarget)
        ..restoreItem(removedTarget);

      expect(container.read(fridgeProvider).totalCount, initialCount);
      expect(
        container
            .read(fridgeProvider)
            .items
            .where((i) => i.id == removedTarget.id)
            .length,
        1,
      );
    });

    test('selectCategory filters items and groupedItems', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(fridgeProvider.notifier)
        ..selectCategory(FridgeCategoryFilter.dairy);

      final dairyState = container.read(fridgeProvider);
      expect(dairyState.selectedCategory, FridgeCategoryFilter.dairy);
      expect(dairyState.groupedItems.keys, <FridgeCategoryFilter>[
        FridgeCategoryFilter.dairy,
      ]);
      expect(
        dairyState.filteredItems.every(
          (item) =>
              mapIngredientCategoryToFilter(item.ingredient.category) ==
              FridgeCategoryFilter.dairy,
        ),
        isTrue,
      );

      notifier.selectCategory(FridgeCategoryFilter.all);
      expect(container.read(fridgeProvider).groupedItems.length, 5);
    });

    test('computePossibleRecipesCount reflects available fridge stock', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(fridgeProvider);
      expect(
        computePossibleRecipesCount(state.items, MockData.recipes),
        greaterThanOrEqualTo(4),
      );
      expect(computePossibleRecipesCount(const [], MockData.recipes), 0);
    });
  });

  group('FridgeScreen Widget Tests', () {
    void setPhoneViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    Widget buildTestApp({GoRouter? router}) {
      if (router != null) {
        return ProviderScope(child: MaterialApp.router(routerConfig: router));
      }
      return const ProviderScope(child: MaterialApp(home: FridgeScreen()));
    }

    testWidgets('Renders French header and green stats banner', (tester) async {
      setPhoneViewport(tester);
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Mon frigo'), findsOneWidget);
      expect(find.text('Gérez vos ingrédients disponibles.'), findsOneWidget);
      expect(find.text('ingrédients'), findsOneWidget);
      expect(find.text('expirent bientôt'), findsOneWidget);
      expect(find.text('recettes possibles'), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.text('5'), findsAtLeastNWidgets(1));
    });

    testWidgets('Filters suggestions and adds an ingredient from text input', (
      tester,
    ) async {
      setPhoneViewport(tester);
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final inputFinder = find.byType(TextField);
      await tester.enterText(inputFinder, 'Cour');
      await tester.pump();

      expect(find.text('Courgette'), findsOneWidget);
      expect(find.text('Courge butternut'), findsOneWidget);

      await tester.tap(find.text('Courgette'));
      await tester.pump();

      await tester.tap(find.byTooltip('Augmenter'));
      await tester.pump();
      expect(find.text('3 pièces'), findsOneWidget);

      await tester.tap(find.text('Ajouter'));
      await tester.pump();

      expect(find.text('Courgette ajouté au frigo'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);

      final addedCard = find.descendant(
        of: find.byType(FridgeItemCard),
        matching: find.text('Courgette'),
      );
      await tester.scrollUntilVisible(
        addedCard,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(addedCard, findsOneWidget);

      // Scroll all the way back to top so the quick-add card is fully visible.
      await tester.scrollUntilVisible(
        find.text('Mon frigo'),
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.enterText(inputFinder, 'Brocoli');
      await tester.pump();
      await tester.ensureVisible(find.text('Ajouter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ajouter'));
      await tester.pumpAndSettle();

      expect(find.text('Brocoli ajouté au frigo'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('16'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('16'), findsOneWidget);
      final broccoliCard = find.descendant(
        of: find.byType(FridgeItemCard),
        matching: find.text('Brocoli'),
      );
      await tester.scrollUntilVisible(
        broccoliCard,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(broccoliCard, findsOneWidget);
    });

    testWidgets('Filters ingredient list by category tab', (tester) async {
      setPhoneViewport(tester);
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Fruits'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Fruits'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Citrons'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Citrons'), findsOneWidget);
      expect(find.text('Fruits rouges'), findsOneWidget);
      expect(find.text('Feta AOP'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('Tout'),
        -150,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tout'));
      await tester.pumpAndSettle();

      final spinachCard = find.descendant(
        of: find.byType(FridgeItemCard),
        matching: find.text('Épinards frais'),
      );
      await tester.scrollUntilVisible(
        spinachCard,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(spinachCard, findsOneWidget);
    });

    testWidgets('Deletes an item and supports snackbar undo', (tester) async {
      setPhoneViewport(tester);
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Feta AOP'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      final deleteButton = find.bySemanticsLabel('Supprimer Feta AOP');
      await tester.ensureVisible(deleteButton);
      await tester.pumpAndSettle();
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      expect(find.text('Feta AOP'), findsNothing);
      expect(find.text('Feta AOP supprimé du frigo'), findsOneWidget);

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('14'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('14'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Feta AOP'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Feta AOP'), findsOneWidget);
    });

    testWidgets('Edits an item quantity via modal bottom sheet', (
      tester,
    ) async {
      setPhoneViewport(tester);
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Feta AOP'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      final editButton = find.bySemanticsLabel('Modifier Feta AOP');
      await tester.ensureVisible(editButton);
      await tester.pumpAndSettle();
      await tester.tap(editButton);
      await tester.pumpAndSettle();

      expect(find.text('Modifier Feta AOP'), findsOneWidget);
      expect(find.text('180 g'), findsAtLeastNWidgets(1));

      final sheetAugmenter = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byTooltip('Augmenter'),
      );
      await tester.tap(sheetAugmenter);
      await tester.pump();
      expect(find.text('230 g'), findsOneWidget);

      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(find.text('230 g'), findsOneWidget);
    });

    testWidgets('Navigates to /scanner and /recommendations', (tester) async {
      setPhoneViewport(tester);
      final router = GoRouter(
        initialLocation: '/fridge',
        routes: [
          GoRoute(
            path: '/fridge',
            builder: (context, state) => const FridgeScreen(),
          ),
          GoRoute(
            path: '/scanner',
            builder: (context, state) =>
                const Scaffold(body: Text('ScannerRoute')),
          ),
          GoRoute(
            path: '/recommendations',
            builder: (context, state) =>
                const Scaffold(body: Text('RecommendationsRoute')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(buildTestApp(router: router));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Scanner un code-barres'));
      await tester.pumpAndSettle();
      expect(find.text('ScannerRoute'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();

      final ctaFinder = find.text('Trouver des recettes avec mes ingrédients');
      await tester.scrollUntilVisible(
        ctaFinder,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(ctaFinder);
      await tester.pumpAndSettle();
      await tester.tap(ctaFinder);
      await tester.pumpAndSettle();
      expect(find.text('RecommendationsRoute'), findsOneWidget);
    });
  });
}
