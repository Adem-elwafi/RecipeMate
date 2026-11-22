import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipemate/core/config/app_assets.dart';
import 'package:recipemate/features/auth/auth_screen.dart';
import '../../helpers/svg_asset_finder.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDownAll(() => GoogleFonts.config.allowRuntimeFetching = true);

  Future<void> pumpAuthScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AuthScreen())),
    );
  }

  Finder fieldWithHint(String hint) =>
      find.ancestor(of: find.text(hint), matching: find.byType(TextFormField));

  Future<void> tapText(WidgetTester tester, String label) async {
    final button = find.text(label);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  group('AuthScreen', () {
    testWidgets('affiche le formulaire de connexion', (tester) async {
      await pumpAuthScreen(tester);

      expect(find.text('Bon retour parmi nous !'), findsOneWidget);
      expect(findSvgAsset(appLogoAssetPath), findsOneWidget);
      expect(find.text('Adresse e-mail'), findsOneWidget);
      expect(find.text('Mot de passe'), findsOneWidget);
      expect(find.text('Continuer avec Google'), findsOneWidget);
      expect(find.text('Nom complet'), findsNothing);
    });

    testWidgets('valide les champs obligatoires avant toute connexion', (
      tester,
    ) async {
      await pumpAuthScreen(tester);

      await tapText(tester, 'Se connecter');

      expect(find.text('L’e-mail est obligatoire.'), findsOneWidget);
      expect(find.text('Le mot de passe est obligatoire.'), findsOneWidget);
    });

    testWidgets('refuse une adresse e-mail invalide', (tester) async {
      await pumpAuthScreen(tester);

      await tester.enterText(fieldWithHint('vous@exemple.com'), 'pas-un-email');
      await tester.enterText(fieldWithHint('Au moins 6 caractères'), 'secret1');
      await tapText(tester, 'Se connecter');

      expect(find.text('Entrez une adresse e-mail valide.'), findsOneWidget);
    });

    testWidgets('bascule vers l’inscription et valide la confirmation', (
      tester,
    ) async {
      await pumpAuthScreen(tester);

      await tapText(tester, 'Créer un compte');

      expect(find.text('Créez votre compte'), findsOneWidget);
      expect(find.text('Nom complet'), findsOneWidget);
      expect(find.text('Confirmer le mot de passe'), findsOneWidget);

      await tester.enterText(fieldWithHint('Au moins 6 caractères'), 'secret1');
      await tester.enterText(
        fieldWithHint('Répétez le mot de passe'),
        'autre1',
      );
      await tapText(tester, 'Créer un compte');

      expect(
        find.text('Les mots de passe ne correspondent pas.'),
        findsOneWidget,
      );
    });

    testWidgets('affiche le formulaire de mot de passe oublié', (tester) async {
      await pumpAuthScreen(tester);

      await tapText(tester, 'Mot de passe oublié ?');

      expect(find.text('Réinitialiser le mot de passe'), findsOneWidget);
      expect(find.text('Envoyer le lien'), findsOneWidget);
      expect(find.text('Mot de passe'), findsNothing);
      expect(find.text('Continuer avec Google'), findsNothing);
    });
  });
}
