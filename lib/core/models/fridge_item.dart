import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:recipemate/core/models/ingredient.dart';

/// An ingredient stored in the user's fridge with expiration tracking.
@immutable
class FridgeItem {
  const FridgeItem({
    required this.id,
    required this.ingredient,
    required this.quantity,
    required this.unit,
    required this.expirationDate,
    this.hasExpirationDate = true,
    DateTime? addedDate,
  }) : addedDate = addedDate ?? expirationDate;

  final String id;
  final Ingredient ingredient;
  final double quantity;
  final String unit;
  final DateTime expirationDate;
  final bool hasExpirationDate;
  final DateTime addedDate;

  /// Number of days remaining before expiration.
  int get daysUntilExpiration {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exp = DateTime(
      expirationDate.year,
      expirationDate.month,
      expirationDate.day,
    );
    return exp.difference(today).inDays;
  }

  /// Whether the item expires in 3 days or fewer and is not yet expired.
  bool get isExpiringSoon =>
      hasExpirationDate && daysUntilExpiration >= 0 && daysUntilExpiration <= 3;

  /// Whether the item has already passed its expiration date.
  bool get isExpired => hasExpirationDate && daysUntilExpiration < 0;

  /// Human-friendly French expiration label.
  String get expirationLabel {
    if (!hasExpirationDate) {
      return 'Sans date';
    }
    final days = daysUntilExpiration;
    if (days < 0) {
      final abs = days.abs();
      return abs == 1 ? 'Périmé depuis hier' : 'Périmé depuis $abs jours';
    }
    if (days == 0) {
      return "Expire aujourd'hui";
    }
    if (days == 1) {
      return 'Expire demain';
    }
    return 'Expire dans $days jours';
  }

  /// Compact French expiration label matching `06 · Mon frigo`.
  String get shortExpirationLabel {
    if (!hasExpirationDate) {
      return 'Sans date';
    }
    final days = daysUntilExpiration;
    if (days < 0) {
      return 'Périmé';
    }
    if (days == 0) {
      return "Expire aujourd'hui";
    }
    if (days == 1) {
      return 'Expire demain';
    }
    return 'Expire dans $days j';
  }

  /// Formatted date in French (e.g. 18 nov. 2026).
  String get formattedDate {
    if (!hasExpirationDate) {
      return 'Sans date';
    }
    return DateFormat('d MMM yyyy', 'fr_FR').format(expirationDate);
  }

  FridgeItem copyWith({
    String? id,
    Ingredient? ingredient,
    double? quantity,
    String? unit,
    DateTime? expirationDate,
    bool? hasExpirationDate,
    DateTime? addedDate,
  }) {
    return FridgeItem(
      id: id ?? this.id,
      ingredient: ingredient ?? this.ingredient,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expirationDate: expirationDate ?? this.expirationDate,
      hasExpirationDate: hasExpirationDate ?? this.hasExpirationDate,
      addedDate: addedDate ?? this.addedDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FridgeItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
