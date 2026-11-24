import 'package:flutter/foundation.dart';

/// Type d'un rappel (point 4) : péremption d'un produit ou repas planifié.
enum ReminderType { expiry, meal }

/// Statut d'un rappel dans l'historique Firestore.
enum ReminderStatus { pending, sent, cancelled }

/// Modèle d'un document `users/{uid}/reminders/{reminderId}`.
@immutable
class Reminder {
  const Reminder({
    required this.id,
    required this.type,
    required this.title,
    required this.scheduledAt,
    required this.relatedId,
    required this.status,
    required this.createdAt,
    this.triggeredAt,
  });

  factory Reminder.fromMap(String id, Map<String, dynamic> map) {
    return Reminder(
      id: id,
      type: ReminderType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => ReminderType.meal,
      ),
      title: map['title'] as String? ?? '',
      scheduledAt:
          DateTime.tryParse(map['scheduledAt'] as String? ?? '') ??
          DateTime.now(),
      relatedId: map['relatedId'] as String? ?? '',
      status: ReminderStatus.values.firstWhere(
        (value) => value.name == map['status'],
        orElse: () => ReminderStatus.pending,
      ),
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
      triggeredAt: DateTime.tryParse(map['triggeredAt'] as String? ?? ''),
    );
  }

  final String id;
  final ReminderType type;
  final String title;
  final DateTime scheduledAt;
  final String relatedId;
  final ReminderStatus status;
  final DateTime createdAt;
  final DateTime? triggeredAt;

  Reminder copyWith({ReminderStatus? status, DateTime? triggeredAt}) {
    return Reminder(
      id: id,
      type: type,
      title: title,
      scheduledAt: scheduledAt,
      relatedId: relatedId,
      status: status ?? this.status,
      createdAt: createdAt,
      triggeredAt: triggeredAt ?? this.triggeredAt,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
    'type': type.name,
    'title': title,
    'scheduledAt': scheduledAt.toIso8601String(),
    'relatedId': relatedId,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'triggeredAt': triggeredAt?.toIso8601String(),
  };
}
