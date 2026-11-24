import 'package:recipemate/core/models/difficulty.dart';
import 'package:recipemate/core/models/fridge_item.dart';
import 'package:recipemate/core/models/ingredient.dart';
import 'package:recipemate/core/models/recipe.dart';
import 'package:recipemate/core/models/user_profile.dart';

/// Centralized mock data matching `docs/design/RecipeMate.html`.
abstract final class MockData {
  // Ingredients
  static const ingChicken = Ingredient(
    id: 'ing_chicken',
    name: 'Blancs de poulet',
    category: IngredientCategory.meat,
    defaultUnit: 'g',
  );

  static const ingFeta = Ingredient(
    id: 'ing_feta',
    name: 'Feta AOP',
    category: IngredientCategory.dairy,
    defaultUnit: 'g',
  );

  static const ingCherryTomatoes = Ingredient(
    id: 'ing_cherry_tomatoes',
    name: 'Tomates cerises',
    category: IngredientCategory.vegetables,
    defaultUnit: 'g',
  );

  static const ingCucumber = Ingredient(
    id: 'ing_cucumber',
    name: 'Concombre',
    category: IngredientCategory.vegetables,
    defaultUnit: 'pièce',
  );

  static const ingAvocado = Ingredient(
    id: 'ing_avocado',
    name: 'Avocat Hass',
    category: IngredientCategory.vegetables,
    defaultUnit: 'pièce',
  );

  static const ingSalmon = Ingredient(
    id: 'ing_salmon',
    name: 'Pavé de saumon frais',
    category: IngredientCategory.fish,
    defaultUnit: 'g',
  );

  static const ingSpinach = Ingredient(
    id: 'ing_spinach',
    name: 'Épinards frais',
    category: IngredientCategory.vegetables,
    defaultUnit: 'g',
  );

  static const ingEggs = Ingredient(
    id: 'ing_eggs',
    name: 'Œufs frais bio',
    category: IngredientCategory.dairy,
    defaultUnit: 'pièce',
  );

  static const ingGreekYogurt = Ingredient(
    id: 'ing_greek_yogurt',
    name: 'Yaourt grec',
    category: IngredientCategory.dairy,
    defaultUnit: 'g',
  );

  static const ingChickpeas = Ingredient(
    id: 'ing_chickpeas',
    name: 'Pois chiches',
    category: IngredientCategory.grains,
    defaultUnit: 'g',
  );

  static const ingCoconutMilk = Ingredient(
    id: 'ing_coconut_milk',
    name: 'Lait de coco',
    category: IngredientCategory.other,
    defaultUnit: 'ml',
  );

  static const ingOats = Ingredient(
    id: 'ing_oats',
    name: "Flocons d'avoine",
    category: IngredientCategory.grains,
    defaultUnit: 'g',
  );

  static const ingBerries = Ingredient(
    id: 'ing_berries',
    name: 'Fruits rouges',
    category: IngredientCategory.fruits,
    defaultUnit: 'g',
  );

  static const ingOliveOil = Ingredient(
    id: 'ing_olive_oil',
    name: "Huile d'olive extra vierge",
    category: IngredientCategory.spices,
    defaultUnit: 'c. à soupe',
  );

  static const ingRice = Ingredient(
    id: 'ing_rice',
    name: 'Riz basmati',
    category: IngredientCategory.grains,
    defaultUnit: 'g',
  );

  /// All known ingredients, for API mappings.
  static List<Ingredient> get allIngredients => <Ingredient>[
    ingChicken,
    ingFeta,
    ingCherryTomatoes,
    ingCucumber,
    ingAvocado,
    ingSalmon,
    ingSpinach,
    ingEggs,
    ingGreekYogurt,
    ingChickpeas,
    ingCoconutMilk,
    ingOats,
    ingBerries,
    ingOliveOil,
    ingRice,
  ];

  /// Initial fridge stock with expiration dates
  static List<FridgeItem> get initialFridgeItems {
    final now = DateTime.now();
    return [
      FridgeItem(
        id: 'fi_1',
        ingredient: ingFeta,
        quantity: 180,
        unit: 'g',
        expirationDate: now.add(const Duration(days: 2)),
      ),
      FridgeItem(
        id: 'fi_2',
        ingredient: ingCherryTomatoes,
        quantity: 250,
        unit: 'g',
        expirationDate: now.add(const Duration(days: 3)),
      ),
      FridgeItem(
        id: 'fi_3',
        ingredient: ingSpinach,
        quantity: 150,
        unit: 'g',
        expirationDate: now.add(const Duration(days: 1)),
      ),
      FridgeItem(
        id: 'fi_4',
        ingredient: ingAvocado,
        quantity: 2,
        unit: 'pièce',
        expirationDate: now.add(const Duration(days: 3)),
      ),
      FridgeItem(
        id: 'fi_5',
        ingredient: ingCucumber,
        quantity: 1,
        unit: 'pièce',
        expirationDate: now.add(const Duration(days: 5)),
      ),
      FridgeItem(
        id: 'fi_6',
        ingredient: ingChicken,
        quantity: 350,
        unit: 'g',
        expirationDate: now.add(const Duration(days: 4)),
      ),
      FridgeItem(
        id: 'fi_7',
        ingredient: ingEggs,
        quantity: 6,
        unit: 'pièce',
        expirationDate: now.add(const Duration(days: 12)),
      ),
      FridgeItem(
        id: 'fi_8',
        ingredient: ingGreekYogurt,
        quantity: 400,
        unit: 'g',
        expirationDate: now.add(const Duration(days: 9)),
      ),
    ];
  }

  /// High fidelity mock recipes
  static final List<Recipe> recipes = [
    const Recipe(
      id: 'rec_1',
      title: 'Salade grecque au poulet',
      description: 'Une salade méditerranéenne croustillante et parfumée, garnie de poulet grillé doré, feta AOP crémeuse et tomates cerises gorgées de soleil.',
      imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=800&auto=format&fit=crop&q=80',
      prepTimeMinutes: 15,
      cookTimeMinutes: 10,
      calories: 420,
      proteinGrams: 34,
      carbsGrams: 12,
      fatGrams: 26,
      dietBadges: ['Healthy', 'Riche en protéines', 'Sans gluten'],
      allergens: ['Lait (Feta)'],
      servings: 2,
      rating: 4.9,
      matchPercentage: 0.88,
      isFavorite: true,
      difficulty: Difficulty.easy,
      ingredients: [
        RecipeIngredient(ingredient: ingChicken, quantity: 200, unit: 'g'),
        RecipeIngredient(ingredient: ingFeta, quantity: 80, unit: 'g'),
        RecipeIngredient(
          ingredient: ingCherryTomatoes,
          quantity: 150,
          unit: 'g',
        ),
        RecipeIngredient(ingredient: ingCucumber, quantity: 0.5, unit: 'pièce'),
        RecipeIngredient(
          ingredient: ingOliveOil,
          quantity: 2,
          unit: 'c. à soupe',
        ),
      ],
      instructions: [
        'Couper les blancs de poulet en dés et les assaisonner de sel, poivre et origan.',
        'Faire dorer le poulet à la poêle avec une cuillère d’huile d’olive pendant 8 à 10 minutes.',
        'Laver et couper le concombre en demi-rondelles et les tomates cerises en deux.',
        'Dans un grand bol, mélanger les légumes frais avec la feta émiettée.',
        'Ajouter le poulet tiède, arroser du reste d’huile d’olive et servir aussitôt.',
      ],
    ),
    const Recipe(
      id: 'rec_2',
      title: 'Bowl avocat saumon',
      description: 'Bol fraîcheur composé de dés de saumon frais mariné, d’avocat crémeux, de riz tiède et de graines de sésame croquantes.',
      imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&auto=format&fit=crop&q=80',
      prepTimeMinutes: 15,
      cookTimeMinutes: 0,
      calories: 510,
      proteinGrams: 28,
      carbsGrams: 38,
      fatGrams: 28,
      dietBadges: ['Healthy', 'Oméga 3', 'Sans gluten'],
      allergens: ['Poisson (Saumon)', 'Sésame'],
      servings: 1,
      rating: 4.8,
      matchPercentage: 0.75,
      isFavorite: false,
      difficulty: Difficulty.medium,
      ingredients: [
        RecipeIngredient(ingredient: ingSalmon, quantity: 120, unit: 'g'),
        RecipeIngredient(ingredient: ingAvocado, quantity: 1, unit: 'pièce'),
        RecipeIngredient(ingredient: ingCucumber, quantity: 0.5, unit: 'pièce'),
        RecipeIngredient(ingredient: ingRice, quantity: 70, unit: 'g'),
      ],
      instructions: [
        'Faire cuire le riz basmati selon les indications du paquet puis laisser tiédir.',
        'Couper le saumon frais en cubes réguliers et émincer l’avocat en fines lamelles.',
        'Disposer le riz au fond du bol, puis garnir avec le saumon, l’avocat et le concombre.',
        'Arroser d’un filet de sauce soja et parsemer de graines de sésame avant de déguster.',
      ],
    ),
    const Recipe(
      id: 'rec_3',
      title: 'Porridge aux fruits rouges',
      description: 'Un petit-déjeuner énergétique et réconfortant à base de flocons d’avoine fondants, de yaourt grec et de baies acidulées.',
      imageUrl: 'https://images.unsplash.com/photo-1517673132405-a56a62b18caf?w=800&auto=format&fit=crop&q=80',
      prepTimeMinutes: 5,
      cookTimeMinutes: 5,
      calories: 340,
      proteinGrams: 14,
      carbsGrams: 54,
      fatGrams: 7,
      dietBadges: ['Végétarien', 'Fibres', 'Petit-déjeuner'],
      allergens: ['Gluten (Avoine)', 'Lait'],
      servings: 1,
      rating: 4.7,
      matchPercentage: 0.60,
      isFavorite: true,
      difficulty: Difficulty.easy,
      ingredients: [
        RecipeIngredient(ingredient: ingOats, quantity: 50, unit: 'g'),
        RecipeIngredient(ingredient: ingGreekYogurt, quantity: 100, unit: 'g'),
        RecipeIngredient(ingredient: ingBerries, quantity: 80, unit: 'g'),
      ],
      instructions: [
        'Dans une casserole, faire cuire les flocons d’avoine avec 150ml d’eau ou de lait pendant 5 minutes.',
        'Verser le porridge crémeux dans un bol et incorporer délicatement le yaourt grec.',
        'Déposer sur le dessus les fruits rouges frais et un filet de sirop d’érable si souhaité.',
      ],
    ),
    const Recipe(
      id: 'rec_4',
      title: 'Curry de pois chiches & coco',
      description: 'Plat végétal parfumé au lait de coco onctueux, épices douces et pois chiches fondants mijotés lentement.',
      imageUrl: 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=800&auto=format&fit=crop&q=80',
      prepTimeMinutes: 10,
      cookTimeMinutes: 20,
      calories: 460,
      proteinGrams: 18,
      carbsGrams: 52,
      fatGrams: 20,
      dietBadges: ['Végétarien', 'Végan', 'Sans gluten'],
      allergens: [],
      servings: 2,
      rating: 4.9,
      matchPercentage: 0.82,
      isFavorite: false,
      difficulty: Difficulty.medium,
      ingredients: [
        RecipeIngredient(ingredient: ingChickpeas, quantity: 250, unit: 'g'),
        RecipeIngredient(ingredient: ingCoconutMilk, quantity: 200, unit: 'ml'),
        RecipeIngredient(ingredient: ingSpinach, quantity: 100, unit: 'g'),
        RecipeIngredient(
          ingredient: ingOliveOil,
          quantity: 1,
          unit: 'c. à soupe',
        ),
      ],
      instructions: [
        'Faire revenir les épices curry dans une cuillère d’huile d’olive jusqu’à libération des arômes.',
        'Ajouter les pois chiches rincés et égouttés, puis mouiller avec le lait de coco.',
        'Laisser mijoter à feu doux pendant 15 minutes pour que les saveurs s’imprègnent.',
        'Ajouter les épinards frais en fin de cuisson, mélanger 2 minutes jusqu’à ce qu’ils tombent.',
        'Servir chaud accompagné de riz basmati ou de naans.',
      ],
    ),
    const Recipe(
      id: 'rec_5',
      title: 'Omelette aux épinards et feta',
      description: 'Recette anti-gaspi express idéale pour utiliser les épinards frais et la feta qui expirent bientôt.',
      imageUrl: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=800&auto=format&fit=crop&q=80',
      prepTimeMinutes: 5,
      cookTimeMinutes: 8,
      calories: 310,
      proteinGrams: 22,
      carbsGrams: 4,
      fatGrams: 23,
      dietBadges: ['Végétarien', 'Keto', 'Anti-gaspi'],
      allergens: ['Œufs', 'Lait (Feta)'],
      servings: 1,
      rating: 4.8,
      matchPercentage: 0.95,
      isFavorite: true,
      difficulty: Difficulty.easy,
      ingredients: [
        RecipeIngredient(ingredient: ingEggs, quantity: 3, unit: 'pièce'),
        RecipeIngredient(ingredient: ingSpinach, quantity: 60, unit: 'g'),
        RecipeIngredient(ingredient: ingFeta, quantity: 40, unit: 'g'),
        RecipeIngredient(
          ingredient: ingOliveOil,
          quantity: 1,
          unit: 'c. à café',
        ),
      ],
      instructions: [
        'Battre les œufs dans un bol avec une pincée de sel et de poivre.',
        'Faire suer les épinards 2 minutes dans une poêle chaude avec un filet d’huile d’olive.',
        'Verser les œufs battus sur les épinards et cuire à feu moyen.',
        'Émietter la feta sur la surface, rabattre l’omelette en deux et servir tiède.',
      ],
    ),
  ];

  /// Default user profile
  static const UserProfile defaultUser = UserProfile(
    id: 'usr_adem',
    name: 'Adem El Wafi',
    email: 'adem@recipemate.app',
    diets: ['Healthy', 'Riche en protéines'],
    allergies: [],
    calorieGoal: 2100,
    proteinGoal: 135,
    carbsGoal: 210,
    fatGoal: 65,
  );
}
