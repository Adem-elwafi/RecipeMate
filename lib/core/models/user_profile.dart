import 'package:flutter/foundation.dart';

/// Represents the authenticated user profile with dietary and macro preferences.
@immutable
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.diets = const [],
    this.allergies = const [],
    this.calorieGoal = 2000,
    this.proteinGoal = 130,
    this.carbsGoal = 220,
    this.fatGoal = 65,
  });

  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final List<String> diets;
  final List<String> allergies;
  final int calorieGoal;
  final double proteinGoal;
  final double carbsGoal;
  final double fatGoal;

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    List<String>? diets,
    List<String>? allergies,
    int? calorieGoal,
    double? proteinGoal,
    double? carbsGoal,
    double? fatGoal,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      diets: diets ?? this.diets,
      allergies: allergies ?? this.allergies,
      calorieGoal: calorieGoal ?? this.calorieGoal,
      proteinGoal: proteinGoal ?? this.proteinGoal,
      carbsGoal: carbsGoal ?? this.carbsGoal,
      fatGoal: fatGoal ?? this.fatGoal,
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
