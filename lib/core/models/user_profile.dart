import 'package:flutter/foundation.dart';

/// Profil de l'utilisateur authentifié.
///
/// Point 5 : à la création de compte, tous les champs non fournis sont vides
/// ou nuls. Aucune valeur d'exemple n'est inventée par le modèle.
@immutable
class UserProfile {
  const UserProfile({
    required this.id,
    this.name = '',
    this.email = '',
    this.displayName,
    this.photoUrl,
    this.age,
    this.weight,
    this.height,
    this.goal,
    this.bio = '',
    this.diets = const <String>[],
    this.allergies = const <String>[],
    this.excludedIngredients = const <String>[],
    this.calorieGoal,
    this.proteinGoal,
    this.carbsGoal,
    this.fatGoal,
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;

  // Champs explicites demandés au point 5.
  final String? displayName;
  final String? photoUrl;
  final int? age;
  final double? weight;
  final double? height;
  final String? goal;
  final String bio;
  final List<String> diets;
  final List<String> allergies;
  final List<String> excludedIngredients;

  // Objectifs nutritionnels : null tant que l'utilisateur ne les a pas saisis.
  final int? calorieGoal;
  final double? proteinGoal;
  final double? carbsGoal;
  final double? fatGoal;
  final DateTime? createdAt;

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? displayName,
    String? photoUrl,
    int? age,
    double? weight,
    double? height,
    String? goal,
    String? bio,
    List<String>? diets,
    List<String>? allergies,
    List<String>? excludedIngredients,
    int? calorieGoal,
    double? proteinGoal,
    double? carbsGoal,
    double? fatGoal,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      goal: goal ?? this.goal,
      bio: bio ?? this.bio,
      diets: diets ?? this.diets,
      allergies: allergies ?? this.allergies,
      excludedIngredients: excludedIngredients ?? this.excludedIngredients,
      calorieGoal: calorieGoal ?? this.calorieGoal,
      proteinGoal: proteinGoal ?? this.proteinGoal,
      carbsGoal: carbsGoal ?? this.carbsGoal,
      fatGoal: fatGoal ?? this.fatGoal,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
