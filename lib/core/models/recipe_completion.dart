import 'package:flutter/foundation.dart';

/// One finished recipe: the recipe and when it was finished.
///
/// Records are kept in the database. Recipes finished by many people
/// show up in the home screen's popular section.
@immutable
class RecipeCompletion {
  const RecipeCompletion({
    required this.recipeId,
    required this.recipeTitle,
    required this.completedAt,
  });

  final String recipeId;
  final String recipeTitle;
  final DateTime completedAt;

  RecipeCompletion copyWith({
    String? recipeId,
    String? recipeTitle,
    DateTime? completedAt,
  }) {
    return RecipeCompletion(
      recipeId: recipeId ?? this.recipeId,
      recipeTitle: recipeTitle ?? this.recipeTitle,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecipeCompletion &&
          runtimeType == other.runtimeType &&
          recipeId == other.recipeId &&
          recipeTitle == other.recipeTitle &&
          completedAt == other.completedAt;

  @override
  int get hashCode => Object.hash(recipeId, recipeTitle, completedAt);
}
