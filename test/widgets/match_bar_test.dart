import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipemate/shared/widgets/match_bar.dart';

void main() {
  group('MatchBar Widget Tests', () {
    testWidgets('Renders percentage label correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MatchBar(percentage: 0.85))),
      );

      expect(find.text('85% d’ingrédients disponibles'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('Renders clamped value for edge values', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MatchBar(percentage: 100))),
      );

      expect(find.text('100% d’ingrédients disponibles'), findsOneWidget);
    });

    testWidgets('Hides label when showLabel is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: MatchBar(percentage: 0.50, showLabel: false)),
        ),
      );

      expect(find.text('50% d’ingrédients disponibles'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
