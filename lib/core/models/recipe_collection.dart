import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Une collection de recettes créée par l'utilisateur. Stockée dans
/// `users/{uid}/collections/{collectionId}` dans Firestore.
@immutable
class RecipeCollection {
  const RecipeCollection({
    required this.id,
    required this.name,
    required this.recipeIds,
    required this.createdAt,
  });

  factory RecipeCollection.fromMap(String id, Map<String, Object?> map) {
    // Point B1 : `createdAt` est un serverTimestamp() Firestore (Timestamp),
    // mais les anciens documents peuvent contenir une chaîne ISO. Sans ce
    // traitement, la date retombait sur DateTime.now() à chaque lecture.
    final rawCreatedAt = map['createdAt'];
    DateTime? createdAt;
    if (rawCreatedAt is Timestamp) {
      createdAt = rawCreatedAt.toDate();
    } else if (rawCreatedAt is String) {
      createdAt = DateTime.tryParse(rawCreatedAt);
    }

    return RecipeCollection(
      id: id,
      name: map['name'] as String? ?? '',
      recipeIds: (map['recipeIds'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic item) => item.toString())
          .toList(),
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  final String id;
  final String name;
  final List<String> recipeIds;
  final DateTime createdAt;

  RecipeCollection copyWith({
    String? id,
    String? name,
    List<String>? recipeIds,
    DateTime? createdAt,
  }) {
    return RecipeCollection(
      id: id ?? this.id,
      name: name ?? this.name,
      recipeIds: recipeIds ?? this.recipeIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Format attendu par les tests et par les anciennes versions de l'application
  /// qui enregistrent encore `createdAt` comme chaîne ISO.
  Map<String, Object?> toMap() => <String, Object?>{
    'name': name,
    'recipeIds': recipeIds,
    'createdAt': createdAt.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RecipeCollection && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
