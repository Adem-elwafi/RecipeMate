import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipemate/shared/widgets/app_snack_bar.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDownAll(() => GoogleFonts.config.allowRuntimeFetching = true);

  testWidgets('affiche un SnackBar Material flottant et themé', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => AppSnackBar.show(context, 'Enregistré'),
              child: const Text('Afficher'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Afficher'));
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Enregistré'), findsOneWidget);

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.behavior, SnackBarBehavior.floating);
    expect(snackBar.duration, const Duration(seconds: 3));
  });
}
