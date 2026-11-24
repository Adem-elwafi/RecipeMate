import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:recipemate/core/data/mock_data.dart';
import 'package:recipemate/core/models/ingredient.dart';
import 'package:recipemate/core/models/recipe.dart';

/// Exception thrown by [RecipeApi].
class RecipeApiException implements Exception {
  const RecipeApiException(this.message, this.statusCode);

  final String message;
  final int? statusCode;

  @override
  String toString() => 'RecipeApiException: $message (statusCode: $statusCode)';
}

/// In-memory cache for recipes retrieved from the external API (TheMealDB).
final Map<String, Recipe> apiRecipeCache = <String, Recipe>{};

/// HTTP client for recipe search using TheMealDB API.
class RecipeApi {
  const RecipeApi({this.baseUrl = defaultBaseUrl, this.client});

  static const String defaultBaseUrl =
      'https://www.themealdb.com/api/json/v1/1';

  final String baseUrl;
  final http.Client? client;

  /// Searches recipes by query string using TheMealDB API.
  Future<List<Recipe>> searchRecipes(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return const <Recipe>[];

    final searchTerm = _translateQueryToEnglish(cleanQuery);
    final uri = baseUrl.contains('themealdb.com')
        ? Uri.parse('$baseUrl/search.php')
            .replace(queryParameters: <String, String>{'s': searchTerm})
        : Uri.parse('$baseUrl/recipes')
            .replace(queryParameters: <String, String>{'q': cleanQuery});

    final httpClient = client ?? http.Client();
    final response = await httpClient.get(uri);

    if (response.statusCode != 200) {
      throw RecipeApiException('Erreur de recherche.', response.statusCode);
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>? ?? const {};

    // 1. Check TheMealDB format ('meals')
    final meals = body['meals'] as List<dynamic>?;
    if (meals != null) {
      final recipes = <Recipe>[];
      for (final raw in meals) {
        if (raw is Map<String, dynamic>) {
          final recipe = _mapMeal(raw);
          apiRecipeCache[recipe.id] = recipe;
          recipes.add(recipe);
        }
      }
      return recipes;
    }

    // 2. Fallback to custom/test format ('recipes')
    final rawRecipes = body['recipes'] as List<dynamic>?;
    if (rawRecipes != null) {
      final recipes = <Recipe>[];
      for (final raw in rawRecipes) {
        if (raw is Map<String, dynamic>) {
          final recipe = raw.containsKey('idMeal')
              ? _mapMeal(raw)
              : _mapRecipe(raw);
          apiRecipeCache[recipe.id] = recipe;
          recipes.add(recipe);
        }
      }
      return recipes;
    }

    return const <Recipe>[];
  }

  /// Looks up full meal details by ID from TheMealDB API.
  Future<Recipe?> lookupRecipeById(String id) async {
    if (apiRecipeCache.containsKey(id)) {
      return apiRecipeCache[id];
    }

    final uri = Uri.parse('$baseUrl/lookup.php')
        .replace(queryParameters: <String, String>{'i': id});
    final httpClient = client ?? http.Client();
    final response = await httpClient.get(uri);

    if (response.statusCode != 200) return null;

    final body = jsonDecode(response.body) as Map<String, dynamic>? ?? const {};
    final meals = body['meals'] as List<dynamic>?;
    if (meals == null || meals.isEmpty) return null;

    final raw = meals.first as Map<String, dynamic>;
    final recipe = _mapMeal(raw);
    apiRecipeCache[recipe.id] = recipe;
    return recipe;
  }

  /// Maps a TheMealDB JSON object to a [Recipe] model.
  static Recipe _mapMeal(Map<String, dynamic> data) {
    final id = data['idMeal'] as String? ?? '';
    final title = data['strMeal'] as String? ?? 'Recette sans nom';
    final area = data['strArea'] as String? ?? '';
    final category = data['strCategory'] as String? ?? '';
    final imageUrl = data['strMealThumb'] as String? ?? '';
    final tagsStr = data['strTags'] as String?;
    final rawInstructions = data['strInstructions'] as String?;

    final descriptionList = [
      if (area.isNotEmpty) 'Spécialité $area',
      if (category.isNotEmpty) 'Catégorie $category',
    ];
    final description = descriptionList.isEmpty
        ? title
        : descriptionList.join(' · ');

    final hash = id.hashCode.abs();
    final prepMinutes = 10 + (hash % 15);
    final cookMinutes = 15 + ((hash ~/ 2) % 30);
    final calories = 300 + (hash % 350);
    final protein = 15.0 + (hash % 30);
    final carbs = 20.0 + (hash % 50);
    final fat = 8.0 + (hash % 20);

    final badges = _extractBadges(category, tagsStr);
    final instructions = _parseInstructions(rawInstructions);

    final ingredients = <RecipeIngredient>[];
    for (var i = 1; i <= 20; i++) {
      final ingName = data['strIngredient$i'] as String?;
      final measureStr = data['strMeasure$i'] as String?;
      if (ingName != null && ingName.trim().isNotEmpty) {
        final name = ingName.trim();
        final (qty, unit) = _parseMeasure(measureStr ?? '');
        ingredients.add(
          RecipeIngredient(
            ingredient: Ingredient(
              id: 'ing_${id}_$i',
              name: name,
              category: _inferCategory(name),
            ),
            quantity: qty,
            unit: unit,
          ),
        );
      }
    }

    return Recipe(
      id: id,
      title: title,
      description: description,
      imageUrl: imageUrl,
      prepTimeMinutes: prepMinutes,
      cookTimeMinutes: cookMinutes,
      calories: calories,
      proteinGrams: protein,
      carbsGrams: carbs,
      fatGrams: fat,
      dietBadges: badges,
      allergens: const [],
      servings: 4,
      rating: 4.0 + ((hash % 10) / 10.0),
      matchPercentage: 80.0 + (hash % 20),
      ingredients: ingredients.isEmpty
          ? const [
              RecipeIngredient(
                ingredient: Ingredient(
                  id: 'ing_default',
                  name: 'Ingrédient principal',
                  category: IngredientCategory.other,
                ),
                quantity: 1,
                unit: 'portion',
              ),
            ]
          : ingredients,
      instructions: instructions,
    );
  }

  /// Maps legacy JSON payload to a [Recipe] model.
  static Recipe _mapRecipe(Map<String, dynamic> data) {
    final rawIngredients =
        data['ingredients'] as List<dynamic>? ?? const <dynamic>[];
    final ingredients = [
      for (final raw in rawIngredients)
        RecipeIngredient(
          ingredient: _ingredientById(
            _field(raw, 'ingredientId') as String? ?? '',
          ),
          quantity: _numField(raw, 'quantity') ?? 0,
          unit: _field(raw, 'unit') as String? ?? '',
        ),
    ];
    return Recipe(
      id: _field(data, 'id') as String? ?? '',
      title: _field(data, 'title') as String? ?? '',
      description: _field(data, 'description') as String? ?? '',
      imageUrl: _field(data, 'imageUrl') as String? ?? '',
      prepTimeMinutes: _field(data, 'prepTimeMinutes') as int? ?? 0,
      cookTimeMinutes: _field(data, 'cookTimeMinutes') as int? ?? 0,
      calories: _field(data, 'calories') as int? ?? 0,
      proteinGrams: _numField(data, 'proteinGrams') ?? 0,
      carbsGrams: _numField(data, 'carbsGrams') ?? 0,
      fatGrams: _numField(data, 'fatGrams') ?? 0,
      dietBadges: List<String>.from(
        _field(data, 'dietBadges') as List? ?? const [],
      ),
      allergens: List<String>.from(
        _field(data, 'allergens') as List? ?? const [],
      ),
      servings: _field(data, 'servings') as int? ?? 2,
      rating: _numField(data, 'rating') ?? 0,
      matchPercentage: _numField(data, 'matchPercentage'),
      ingredients: ingredients,
      instructions: List<String>.from(
        _field(data, 'instructions') as List? ?? const [],
      ),
    );
  }

  static String _translateQueryToEnglish(String query) {
    final lower = query.toLowerCase().trim();
    const translations = <String, String>{
      'poulet': 'chicken',
      'boeuf': 'beef',
      'bœuf': 'beef',
      'porc': 'pork',
      'poisson': 'fish',
      'crevette': 'shrimp',
      'crevettes': 'prawn',
      'riz': 'rice',
      'pâtes': 'pasta',
      'pates': 'pasta',
      'salade': 'salad',
      'soupe': 'soup',
      'gâteau': 'cake',
      'gateau': 'cake',
      'chocolat': 'chocolate',
      'fromage': 'cheese',
      'oeuf': 'egg',
      'œuf': 'egg',
      'oeufs': 'egg',
      'œufs': 'egg',
      'légumes': 'vegetable',
      'legumes': 'vegetable',
      'pomme': 'apple',
      'agneau': 'lamb',
      'canard': 'duck',
      'dinde': 'turkey',
      'pain': 'bread',
      'tarte': 'pie',
    };
    return translations[lower] ?? query;
  }

  static (double, String) _parseMeasure(String rawMeasure) {
    final text = rawMeasure.trim();
    if (text.isEmpty) return (1.0, '');

    final fractionMatch = RegExp(r'^(\d+)/(\d+)\s*(.*)$').firstMatch(text);
    if (fractionMatch != null) {
      final num = double.parse(fractionMatch.group(1)!);
      final den = double.parse(fractionMatch.group(2)!);
      final unit = fractionMatch.group(3)!.trim();
      return (num / den, unit);
    }

    final numMatch = RegExp(r'^([\d.]+)\s*(.*)$').firstMatch(text);
    if (numMatch != null) {
      final val = double.tryParse(numMatch.group(1)!);
      if (val != null) {
        final unit = numMatch.group(2)!.trim();
        return (val, unit);
      }
    }

    return (1.0, text);
  }

  static List<String> _extractBadges(String category, String? tagsStr) {
    final badges = <String>{};
    if (category.isNotEmpty) {
      switch (category.toLowerCase()) {
        case 'vegetarian':
          badges.add('Végétarien');
        case 'vegan':
          badges.add('Vegan');
        case 'chicken':
          badges.add('Poulet');
        case 'beef':
          badges.add('Bœuf');
        case 'seafood':
          badges.add('Fruits de mer');
        case 'dessert':
          badges.add('Dessert');
        case 'pasta':
          badges.add('Pâtes');
        case 'side':
          badges.add('Accompagnement');
        case 'starter':
          badges.add('Entrée');
        default:
          badges.add(category);
      }
    }

    if (tagsStr != null && tagsStr.isNotEmpty) {
      for (final tag in tagsStr.split(',')) {
        final clean = tag.trim();
        if (clean.isNotEmpty) {
          if (clean.toLowerCase() == 'vegetarian') {
            badges.add('Végétarien');
          } else if (clean.toLowerCase() == 'vegan') {
            badges.add('Vegan');
          } else if (clean.toLowerCase() == 'gluten-free') {
            badges.add('Sans gluten');
          } else {
            badges.add(clean);
          }
        }
      }
    }

    return badges.toList();
  }

  static List<String> _parseInstructions(String? text) {
    if (text == null || text.trim().isEmpty) {
      return const ['Préparer les ingrédients.', 'Suivre les étapes de cuisson.'];
    }
    final rawLines = text.split(RegExp(r'\r?\n+'));
    final steps = <String>[];
    for (final line in rawLines) {
      final clean = line.trim();
      if (clean.isNotEmpty && !clean.toUpperCase().startsWith('STEP ')) {
        steps.add(clean);
      }
    }
    return steps.isEmpty ? [text.trim()] : steps;
  }

  static IngredientCategory _inferCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('chicken') ||
        lower.contains('beef') ||
        lower.contains('pork') ||
        lower.contains('meat') ||
        lower.contains('bacon') ||
        lower.contains('turkey') ||
        lower.contains('lamb') ||
        lower.contains('sausage')) {
      return IngredientCategory.meat;
    }
    if (lower.contains('fish') ||
        lower.contains('salmon') ||
        lower.contains('tuna') ||
        lower.contains('shrimp') ||
        lower.contains('prawn') ||
        lower.contains('cod')) {
      return IngredientCategory.fish;
    }
    if (lower.contains('milk') ||
        lower.contains('cheese') ||
        lower.contains('butter') ||
        lower.contains('cream') ||
        lower.contains('yogurt') ||
        lower.contains('yoghurt')) {
      return IngredientCategory.dairy;
    }
    if (lower.contains('apple') ||
        lower.contains('lemon') ||
        lower.contains('lime') ||
        lower.contains('berry') ||
        lower.contains('banana') ||
        lower.contains('orange')) {
      return IngredientCategory.fruits;
    }
    if (lower.contains('onion') ||
        lower.contains('garlic') ||
        lower.contains('tomato') ||
        lower.contains('pepper') ||
        lower.contains('carrot') ||
        lower.contains('potato') ||
        lower.contains('spinach') ||
        lower.contains('mushroom')) {
      return IngredientCategory.vegetables;
    }
    return IngredientCategory.other;
  }

  static T? _field<T>(dynamic value, String key) {
    final map = value is Map<String, dynamic>
        ? value
        : const <String, dynamic>{};
    return map[key] as T?;
  }

  static double? _numField(dynamic value, String key) =>
      _field<num>(value, key)?.toDouble();

  static Ingredient _ingredientById(String id) {
    final known = MockData.allIngredients
        .where((ingredient) => ingredient.id == id)
        .firstOrNull;
    return known ??
        Ingredient(id: id, name: id, category: IngredientCategory.other);
  }
}
