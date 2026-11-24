import 'package:flutter/foundation.dart';

/// Aggregated nutrition totals of the day.
///
/// Updated as the user finishes recipes; displayed on the home dashboard
/// and persisted through the database so the values survive a restart.
@immutable
class DailyNutrition {
  const DailyNutrition({
    this.calories = 0,
    this.proteinGrams = 0,
    this.carbsGrams = 0,
    this.fatGrams = 0,
    this.completedRecipes = 0,
  });

  final double calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final int completedRecipes;

  DailyNutrition copyWith({
    double? calories,
    double? proteinGrams,
    double? carbsGrams,
    double? fatGrams,
    int? completedRecipes,
  }) {
    return DailyNutrition(
      calories: calories ?? this.calories,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      fatGrams: fatGrams ?? this.fatGrams,
      completedRecipes: completedRecipes ?? this.completedRecipes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyNutrition &&
          runtimeType == other.runtimeType &&
          calories == other.calories &&
          proteinGrams == other.proteinGrams &&
          carbsGrams == other.carbsGrams &&
          fatGrams == other.fatGrams &&
          completedRecipes == other.completedRecipes;

  @override
  int get hashCode => Object.hash(
    calories,
    proteinGrams,
    carbsGrams,
    fatGrams,
    completedRecipes,
  );
}
