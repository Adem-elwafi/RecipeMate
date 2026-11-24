import 'package:flutter_test/flutter_test.dart';
import 'package:recipemate/core/models/reminder.dart';

void main() {
  group('Reminder', () {
    final createdAt = DateTime(2026, 11, 21, 9);
    final scheduledAt = DateTime(2026, 11, 24, 12, 30);

    final reminder = Reminder(
      id: 'rappel-1',
      type: ReminderType.expiry,
      title: 'Yaourt nature va périmer bientôt',
      scheduledAt: scheduledAt,
      relatedId: 'pantry-1',
      status: ReminderStatus.pending,
      createdAt: createdAt,
    );

    test('sérialise tous les champs de l’historique Firestore', () {
      final map = reminder.toMap();

      expect(map['type'], 'expiry');
      expect(map['title'], 'Yaourt nature va périmer bientôt');
      expect(map['scheduledAt'], scheduledAt.toIso8601String());
      expect(map['relatedId'], 'pantry-1');
      expect(map['status'], 'pending');
      expect(map['createdAt'], createdAt.toIso8601String());
      expect(map['triggeredAt'], isNull);
    });

    test('désérialise un document Firestore sans valeur inventée', () {
      final restored = Reminder.fromMap('rappel-1', reminder.toMap());

      expect(restored.id, 'rappel-1');
      expect(restored.type, ReminderType.expiry);
      expect(restored.status, ReminderStatus.pending);
      expect(restored.scheduledAt, scheduledAt);
      expect(restored.relatedId, 'pantry-1');
      expect(restored.triggeredAt, isNull);
    });

    test(
      'copyWith met à jour uniquement le statut et la date de déclenchement',
      () {
        final triggeredAt = DateTime(2026, 11, 24, 12, 31);

        final sent = reminder.copyWith(
          status: ReminderStatus.sent,
          triggeredAt: triggeredAt,
        );

        expect(sent.status, ReminderStatus.sent);
        expect(sent.triggeredAt, triggeredAt);
        expect(sent.title, reminder.title);
        expect(sent.createdAt, createdAt);
      },
    );
  });
}
