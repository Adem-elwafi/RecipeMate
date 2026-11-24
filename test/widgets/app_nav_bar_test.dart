import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipemate/core/router/app_router.dart';
import 'package:recipemate/shared/widgets/app_nav_bar.dart';

void main() {
  group('AppNavBar', () {
    test('selectedIndex follows the current location', () {
      expect(
        AppNavBar(
          currentIndex: 0,
          onTap: (_) {},
          location: '/explore',
        ).selectedIndex,
        1,
      );
      expect(
        AppNavBar(
          currentIndex: 2,
          onTap: (_) {},
          location: '/fridge',
        ).selectedIndex,
        2,
      );
      expect(
        AppNavBar(
          currentIndex: 2,
          onTap: (_) {},
          location: '/recipe/rec_1',
        ).selectedIndex,
        2,
      );
      expect(AppNavBar(currentIndex: 0, onTap: (_) {}).selectedIndex, 0);
    });

    testWidgets('the bottom bar changes with the page being accessed', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: MaterialApp.router(routerConfig: appRouter)),
      );
      await tester.pumpAndSettle();

      int selectedIndex() =>
          tester.widget<AppNavBar>(find.byType(AppNavBar)).selectedIndex;

      expect(selectedIndex(), 0);

      await tester.tap(find.text('Explorer'));
      await tester.pumpAndSettle();
      expect(selectedIndex(), 1);

      await tester.tap(find.text('Mon frigo'));
      await tester.pumpAndSettle();
      expect(selectedIndex(), 2);

      await tester.tap(find.text('Accueil'));
      await tester.pumpAndSettle();
      expect(selectedIndex(), 0);
    });
  });
}
