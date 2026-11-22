import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:recipemate/shared/widgets/recipemate_app_bar.dart';
import 'package:recipemate/shared/widgets/secondary_app_bar.dart';

void main() {
  testWidgets(
    'la flèche retour d’une page secondaire revient à la page précédente',
    (tester) async {
      final router = GoRouter(
        initialLocation: '/profile',
        routes: <RouteBase>[
          GoRoute(
            path: '/profile',
            builder: (context, state) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => context.push('/settings'),
                  child: const Text('Ouvrir paramètres'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const Scaffold(
              appBar: SecondaryAppBar(title: 'Paramètres'),
              body: Center(child: Text('Contenu des paramètres')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ouvrir paramètres'));
      await tester.pumpAndSettle();
      expect(find.text('Contenu des paramètres'), findsOneWidget);

      await tester.tap(find.byTooltip('Retour'));
      await tester.pumpAndSettle();
      expect(find.text('Ouvrir paramètres'), findsOneWidget);
      expect(find.text('Contenu des paramètres'), findsNothing);
    },
  );

  testWidgets('les icônes de l’en-tête commun ouvrent Profil et Paramètres', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            appBar: RecipeMateAppBar(),
            body: Center(child: Text('Écran accueil')),
          ),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const Scaffold(
            appBar: RecipeMateAppBar(showProfile: false),
            body: Center(child: Text('Écran profil')),
          ),
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const Scaffold(
            appBar: SecondaryAppBar(title: 'Paramètres'),
            body: Center(child: Text('Paramètres routés')),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Paramètres'));
    await tester.pumpAndSettle();
    expect(find.text('Paramètres routés'), findsOneWidget);

    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();
    expect(find.text('Écran accueil'), findsOneWidget);

    await tester.tap(find.byTooltip('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Écran profil'), findsOneWidget);
  });
}
