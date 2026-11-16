import 'package:flutter_test/flutter_test.dart';
import 'package:recipemate/core/data/mock_data.dart';
import 'package:recipemate/core/models/fridge_item.dart';

void main() {
  group('FridgeItem Model Tests', () {
    test('Calculates isExpiringSoon true when expiring within 3 days', () {
      final now = DateTime.now();
      final item = FridgeItem(
        id: 'fi_soon',
        ingredient: MockData.ingFeta,
        quantity: 150,
        unit: 'g',
        expirationDate: now.add(const Duration(days: 2)),
      );

      expect(item.daysUntilExpiration, equals(2));
      expect(item.isExpiringSoon, isTrue);
      expect(item.isExpired, isFalse);
      expect(item.expirationLabel, equals('Expire dans 2 jours'));
    });

    test('Correctly identifies expired items', () {
      final now = DateTime.now();
      final item = FridgeItem(
        id: 'fi_expired',
        ingredient: MockData.ingSpinach,
        quantity: 100,
        unit: 'g',
        expirationDate: now.subtract(const Duration(days: 1)),
      );

      expect(item.isExpired, isTrue);
      expect(item.isExpiringSoon, isFalse);
      expect(item.expirationLabel, equals('Périmé depuis hier'));
    });

    test('Identifies items expiring today', () {
      final now = DateTime.now();
      final item = FridgeItem(
        id: 'fi_today',
        ingredient: MockData.ingCherryTomatoes,
        quantity: 200,
        unit: 'g',
        expirationDate: DateTime(now.year, now.month, now.day),
      );

      expect(item.daysUntilExpiration, equals(0));
      expect(item.isExpiringSoon, isTrue);
      expect(item.expirationLabel, equals("Expire aujourd'hui"));
    });

    test('FridgeItem copyWith updates fields cleanly', () {
      final original = MockData.initialFridgeItems.first;
      final updated = original.copyWith(quantity: 500, unit: 'kg');

      expect(updated.id, equals(original.id));
      expect(updated.quantity, equals(500));
      expect(updated.unit, equals('kg'));
      expect(updated.ingredient, equals(original.ingredient));
    });
  });
}
