
import 'package:flutter/foundation.dart';
import 'package:recipemate/core/models/ingredient.dart';

/// Full recipe representation with nutritional data and instructions.
@immutable
class Recipe {
  const Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.ingredients,
    required this.instructions,
    this.dietBadges = const [],
    this.allergens = const [],
    this.category = '',
    this.difficulty = 'Facile',
    this.dietTags = const <String>[],
    this.fiberGrams = 0,
    this.servings = 2,
    this.rating = 4.8,
    this.matchPercentage,
    this.isFavorite = false,
    this.authorId = '',
    this.ingredientKeywords = const <String>[],
    this.isPublic = true,
  });

  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final int calories;
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;

  final List<String> dietBadges;
  final List<String> allergens;

  /// Recipe category.
  final String category;

  /// Difficulty: Facile, Moyen or Difficile.
  final String difficulty;

  /// Diet tags.
  final List<String> dietTags;

  /// Fiber per serving, in grams.
  final double fiberGrams;

  final List<RecipeIngredient> ingredients;
  final List<String> instructions;

  final int servings;
  final double rating;
  final double? matchPercentage;
  final bool isFavorite;

  /// Author UID in Firestore.
  final String authorId;

  /// Normalized ingredient keywords for fridge search.
  final List<String> ingredientKeywords;

  /// Whether the recipe is publicly visible.
  final bool isPublic;

  /// Total preparation and cooking duration in minutes.
  int get totalTimeMinutes => prepTimeMinutes + cookTimeMinutes;

  /// Formatted total time.
  String get formattedTotalTime {
    if (totalTimeMinutes < 60) {
      return '$totalTimeMinutes min';
    }

    final hours = totalTimeMinutes ~/ 60;
    final mins = totalTimeMinutes % 60;

    return mins == 0
        ? '${hours}h'
        : '${hours}h ${mins}min';
  }

  Recipe copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    int? calories,
    double? proteinGrams,
    double? carbsGrams,
    double? fatGrams,
    List<String>? dietBadges,
    List<String>? allergens,
    String? category,
    String? difficulty,
    List<String>? dietTags,
    double? fiberGrams,
    List<RecipeIngredient>? ingredients,
    List<String>? instructions,
    int? servings,
    double? rating,
    double? matchPercentage,
    bool? isFavorite,
    String? authorId,
    List<String>? ingredientKeywords,
    bool? isPublic,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      calories: calories ?? this.calories,
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      fatGrams: fatGrams ?? this.fatGrams,
      dietBadges: dietBadges ?? this.dietBadges,
      allergens: allergens ?? this.allergens,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      dietTags: dietTags ?? this.dietTags,
      fiberGrams: fiberGrams ?? this.fiberGrams,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      servings: servings ?? this.servings,
      rating: rating ?? this.rating,
      matchPercentage: matchPercentage ?? this.matchPercentage,
      isFavorite: isFavorite ?? this.isFavorite,
      authorId: authorId ?? this.authorId,
      ingredientKeywords:
          ingredientKeywords ?? this.ingredientKeywords,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Recipe && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
