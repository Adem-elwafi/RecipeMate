import 'package:flutter_test/flutter_test.dart';
import 'package:recipemate/core/utils/allergy_labels.dart';

void main() {
  group('AllergyLabels', () {
    test('corrige « Guten » en « Gluten »', () {
      expect(AllergyLabels.correct('Guten'), 'Gluten');
      expect(AllergyLabels.correct('guten'), 'Gluten');
    });

    test('conserve les précisions entre parenthèses', () {
      expect(AllergyLabels.correct('Guten (Avoine)'), 'Gluten (Avoine)');
      expect(AllergyLabels.correct('Lait (Feta)'), 'Lait (Feta)');
    });

    test('ne modifie pas un libellé déjà correct', () {
      expect(AllergyLabels.correct('Gluten'), 'Gluten');
      expect(AllergyLabels.correct('Œufs'), 'Œufs');
      expect(AllergyLabels.correct('  '), '');
    });

    test('normalise une liste complète en ignorant les valeurs vides', () {
      final corrected = AllergyLabels.correctAll(<Object?>[
        'Guten, Lait',
        'guten',
        ' ',
        null,
      ]);

      expect(corrected, <String>['Gluten, Lait', 'Gluten']);
    });

    test('accepte une liste absente', () {
      expect(AllergyLabels.correctAll(null), isEmpty);
    });
  });
}
