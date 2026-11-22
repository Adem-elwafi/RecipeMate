import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:recipemate/core/data/mock_data.dart';
import 'package:recipemate/core/models/fridge_item.dart';
import 'package:recipemate/core/models/ingredient.dart';
import 'package:recipemate/core/models/recipe.dart';
import 'package:recipemate/core/models/user_profile.dart';
import 'package:recipemate/features/fridge/providers/fridge_provider.dart';
import 'package:recipemate/features/recommendations/models/recipe_match_result.dart';
import 'package:recipemate/features/recommendations/providers/recommendations_provider.dart';
import 'package:recipemate/features/recommendations/recommendations_screen.dart';
import 'package:recipemate/features/recommendations/services/gemini_recipe_service.dart';
import 'package:recipemate/features/recommendations/services/matching_service.dart';
import 'package:recipemate/features/recommendations/widgets/match_donut.dart';
import 'package:recipemate/features/recommendations/widgets/recipe_match_card.dart';

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _MockHttpClient();
}

class _MockHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  void addCredentials(
    Uri url,
    String realm,
    HttpClientCredentials credentials,
  ) {}

  @override
  void addProxyCredentials(
    String host,
    int port,
    String realm,
    HttpClientCredentials credentials,
  ) {}

  @override
  void close({bool force = false}) {}

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _MockHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _MockHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpHeaders implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  final Stream<List<int>> _stream = Stream<List<int>>.value(
    Uint8List.fromList(const <int>[
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x48,
      0x44,
      0x52,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x01,
      0x08,
      0x06,
      0x00,
      0x00,
      0x00,
      0x1F,
      0x15,
      0xC4,
      0x89,
      0x00,
      0x00,
      0x00,
      0x0A,
      0x49,
      0x44,
      0x41,
      0x54,
      0x78,
      0x9C,
      0x63,
      0x00,
      0x01,
      0x00,
      0x00,
      0x05,
      0x00,
      0x01,
      0x0D,
      0x0A,
      0x2D,
      0xB4,
      0x00,
      0x00,
      0x00,
      0x00,
      0x49,
      0x45,
      0x4E,
      0x44,
      0xAE,
      0x42,
      0x60,
      0x82,
    ]),
  );

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  int get statusCode => 200;
  @override
  int get contentLength => 67;
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;
  @override
  final HttpHeaders headers = _MockHttpHeaders();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DateTime _dayOffset(int days) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + days);
}

Recipe _buildRecipe({
  required String id,
  required String title,
  required List<RecipeIngredient> ingredients,
  int prepTimeMinutes = 10,
  int cookTimeMinutes = 10,
  int calories = 400,
  List<String> allergens = const <String>[],
  List<String> dietBadges = const <String>['Healthy'],
  List<String> instructions = const <String>['Étape 1', 'Étape 2'],
}) {
  return Recipe(
    id: id,
    title: title,
    description: 'Description de $title',
    imageUrl: 'https://example.com/$id.jpg',
    prepTimeMinutes: prepTimeMinutes,
    cookTimeMinutes: cookTimeMinutes,
    calories: calories,
    proteinGrams: 25,
    carbsGrams: 30,
    fatGrams: 12,
    dietBadges: dietBadges,
    allergens: allergens,
    ingredients: ingredients,
    instructions: instructions,
  );
}

FridgeItem _buildFridgeItem({
  required String id,
  required String ingredientId,
  required String name,
  IngredientCategory category = IngredientCategory.vegetables,
  int expiresInDays = 7,
}) {
  return FridgeItem(
    id: id,
    ingredient: Ingredient(id: ingredientId, name: name, category: category),
    quantity: 200,
    unit: 'g',
    expirationDate: _dayOffset(expiresInDays),
  );
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });

  tearDownAll(() {
    HttpOverrides.global = null;
  });

  group('MatchingService Unit Tests', () {
    const service = MatchingService();
    const baseUser = UserProfile(
      id: 'u1',
      name: 'Adem',
      email: 'adem@recipemate.app',
      diets: <String>['Healthy'],
    );

    test(
      'matches exact ingredient IDs and accent-insensitive French names',
      () {
        final recipe = _buildRecipe(
          id: 'r1',
          title: 'Poêlée méditerranéenne',
          ingredients: const <RecipeIngredient>[
            RecipeIngredient(
              ingredient: Ingredient(
                id: 'rec_id_chicken',
                name: 'Blancs de poulet',
                category: IngredientCategory.meat,
              ),
              quantity: 200,
              unit: 'g',
            ),
            RecipeIngredient(
              ingredient: Ingredient(
                id: 'rec_id_tomatoes',
                name: 'Tomates cerises',
                category: IngredientCategory.vegetables,
              ),
              quantity: 150,
              unit: 'g',
            ),
            RecipeIngredient(
              ingredient: Ingredient(
                id: 'rec_id_spinach',
                name: 'Epinards frais',
                category: IngredientCategory.vegetables,
              ),
              quantity: 100,
              unit: 'g',
            ),
            RecipeIngredient(
              ingredient: Ingredient(
                id: 'rec_id_feta',
                name: 'Feta AOP',
                category: IngredientCategory.dairy,
              ),
              quantity: 80,
              unit: 'g',
            ),
          ],
        );

        final fridge = <FridgeItem>[
          _buildFridgeItem(
            id: 'f1',
            ingredientId: 'rec_id_chicken',
            name: 'Volaille fermière',
            category: IngredientCategory.meat,
            expiresInDays: 6,
          ),
          _buildFridgeItem(
            id: 'f2',
            ingredientId: 'other_tomatoes',
            name: 'Tomates',
            expiresInDays: 5,
          ),
          _buildFridgeItem(
            id: 'f3',
            ingredientId: 'other_spinach',
            name: 'Épinards',
            expiresInDays: 5,
          ),
        ];

        final results = service.rankRecipes(
          recipes: <Recipe>[recipe],
          fridgeItems: fridge,
          userProfile: baseUser,
        );

        expect(results, hasLength(1));
        final match = results.first;
        expect(match.matchPercentage, 75);
        expect(match.matchedIngredients, <String>[
          'Poulet',
          'Tomates cerises',
          'Epinards',
        ]);
        expect(match.missingIngredients, <String>['Feta']);
        expect(match.usesExpiringSoonIngredient, isFalse);
        expect(match.difficultyLabel, 'Facile');
      },
    );

    test('matches singular and plural trimmed French ingredient roots', () {
      final recipe = _buildRecipe(
        id: 'r_plural',
        title: 'Poêlée de poireaux et tomates',
        ingredients: const <RecipeIngredient>[
          RecipeIngredient(
            ingredient: Ingredient(
              id: 'a',
              name: 'Tomate cerise',
              category: IngredientCategory.vegetables,
            ),
            quantity: 100,
            unit: 'g',
          ),
          RecipeIngredient(
            ingredient: Ingredient(
              id: 'b',
              name: 'Poireau',
              category: IngredientCategory.vegetables,
            ),
            quantity: 1,
            unit: 'pièce',
          ),
        ],
      );

      final fridge = <FridgeItem>[
        _buildFridgeItem(
          id: 'fa',
          ingredientId: 'fa_id',
          name: 'Tomates',
          expiresInDays: 8,
        ),
        _buildFridgeItem(
          id: 'fb',
          ingredientId: 'fb_id',
          name: 'Poireaux',
          expiresInDays: 8,
        ),
      ];

      final results = service.rankRecipes(
        recipes: <Recipe>[recipe],
        fridgeItems: fridge,
        userProfile: baseUser,
      );

      expect(results.first.matchPercentage, 100);
      expect(results.first.missingIngredients, isEmpty);
    });

    test(
      'applies +5 anti-waste bonus for expiring soon items clamped <= 100',
      () {
        final partialRecipe = _buildRecipe(
          id: 'r_partial',
          title: 'Bol épinards riz',
          ingredients: const <RecipeIngredient>[
            RecipeIngredient(
              ingredient: Ingredient(
                id: 'ing_spinach',
                name: 'Épinards frais',
                category: IngredientCategory.vegetables,
              ),
              quantity: 100,
              unit: 'g',
            ),
            RecipeIngredient(
              ingredient: Ingredient(
                id: 'ing_rice',
                name: 'Riz basmati',
                category: IngredientCategory.grains,
              ),
              quantity: 100,
              unit: 'g',
            ),
          ],
        );

        final fullRecipe = _buildRecipe(
          id: 'r_full',
          title: 'Salade d’épinards',
          ingredients: const <RecipeIngredient>[
            RecipeIngredient(
              ingredient: Ingredient(
                id: 'ing_spinach',
                name: 'Épinards frais',
                category: IngredientCategory.vegetables,
              ),
              quantity: 100,
              unit: 'g',
            ),
          ],
        );

        final fridge = <FridgeItem>[
          _buildFridgeItem(
            id: 'f_exp',
            ingredientId: 'ing_spinach',
            name: 'Épinards frais',
            expiresInDays: 1,
          ),
        ];

        final results = service.rankRecipes(
          recipes: <Recipe>[partialRecipe, fullRecipe],
          fridgeItems: fridge,
          userProfile: baseUser,
        );

        final fullMatch = results.firstWhere((r) => r.recipe.id == 'r_full');
        final partialMatch = results.firstWhere(
          (r) => r.recipe.id == 'r_partial',
        );

        expect(fullMatch.usesExpiringSoonIngredient, isTrue);
        expect(fullMatch.matchPercentage, 100);
        expect(partialMatch.usesExpiringSoonIngredient, isTrue);
        expect(partialMatch.matchPercentage, 55);
      },
    );

    test('excludes recipes matching user allergies or flags when kept', () {
      const allergicUser = UserProfile(
        id: 'u_allergy',
        name: 'Adem',
        email: 'adem@recipemate.app',
        allergies: <String>['Lait', 'Poisson'],
      );

      final excluded = service.rankRecipes(
        recipes: MockData.recipes,
        fridgeItems: MockData.initialFridgeItems,
        userProfile: allergicUser,
      );

      // rec_1 (Lait), rec_2 (Poisson), rec_3 (Lait), rec_5 (Lait) are excluded.
      expect(excluded.map((r) => r.recipe.id).toList(), <String>['rec_4']);

      final flagged = service.rankRecipes(
        recipes: MockData.recipes,
        fridgeItems: MockData.initialFridgeItems,
        userProfile: allergicUser,
        excludeAllergens: false,
      );

      expect(flagged, hasLength(MockData.recipes.length));
      final curry = flagged.firstWhere((r) => r.recipe.id == 'rec_4');
      final salade = flagged.firstWhere((r) => r.recipe.id == 'rec_1');
      final bowl = flagged.firstWhere((r) => r.recipe.id == 'rec_2');
      expect(curry.hasAllergyConflict, isFalse);
      expect(salade.hasAllergyConflict, isTrue);
      expect(bowl.hasAllergyConflict, isTrue);
    });

    test(
      'sorts correctly by Match, Temps, and Calories and computes difficulty',
      () {
        final rSlowHighCal = _buildRecipe(
          id: 'r_slow',
          title: 'Plat long',
          prepTimeMinutes: 20,
          cookTimeMinutes: 30,
          calories: 650,
          ingredients: const <RecipeIngredient>[
            RecipeIngredient(
              ingredient: Ingredient(
                id: 'i1',
                name: 'Carottes',
                category: IngredientCategory.vegetables,
              ),
              quantity: 100,
              unit: 'g',
            ),
          ],
        );
        final rMedium = _buildRecipe(
          id: 'r_med',
          title: 'Plat moyen',
          prepTimeMinutes: 15,
          cookTimeMinutes: 20,
          calories: 320,
          ingredients: const <RecipeIngredient>[
            RecipeIngredient(
              ingredient: Ingredient(
                id: 'i1',
                name: 'Carottes',
                category: IngredientCategory.vegetables,
              ),
              quantity: 100,
              unit: 'g',
            ),
            RecipeIngredient(
              ingredient: Ingredient(
                id: 'i2',
                name: 'Poivre',
                category: IngredientCategory.spices,
              ),
              quantity: 5,
              unit: 'g',
            ),
          ],
        );
        final rFastLowMatch = _buildRecipe(
          id: 'r_fast',
          title: 'Plat express',
          prepTimeMinutes: 5,
          cookTimeMinutes: 5,
          calories: 450,
          ingredients: const <RecipeIngredient>[
            RecipeIngredient(
              ingredient: Ingredient(
                id: 'i1',
                name: 'Carottes',
                category: IngredientCategory.vegetables,
              ),
              quantity: 100,
              unit: 'g',
            ),
            RecipeIngredient(
              ingredient: Ingredient(
                id: 'i2',
                name: 'Poivre',
                category: IngredientCategory.spices,
              ),
              quantity: 5,
              unit: 'g',
            ),
            RecipeIngredient(
              ingredient: Ingredient(
                id: 'i3',
                name: 'Crème',
                category: IngredientCategory.dairy,
              ),
              quantity: 50,
              unit: 'ml',
            ),
          ],
        );

        final fridge = <FridgeItem>[
          _buildFridgeItem(
            id: 'fi_carrots',
            ingredientId: 'i1',
            name: 'Carottes',
            expiresInDays: 8,
          ),
        ];

        final byMatch = service.rankRecipes(
          recipes: <Recipe>[rFastLowMatch, rMedium, rSlowHighCal],
          fridgeItems: fridge,
          userProfile: baseUser,
          sort: RecommendationSort.match,
        );
        expect(byMatch.map((r) => r.recipe.id).toList(), <String>[
          'r_slow',
          'r_med',
          'r_fast',
        ]);
        expect(byMatch[0].difficultyLabel, 'Avancé');
        expect(byMatch[1].difficultyLabel, 'Moyen');
        expect(byMatch[2].difficultyLabel, 'Facile');

        final byTime = service.rankRecipes(
          recipes: <Recipe>[rSlowHighCal, rMedium, rFastLowMatch],
          fridgeItems: fridge,
          userProfile: baseUser,
          sort: RecommendationSort.time,
        );
        expect(byTime.map((r) => r.recipe.id).toList(), <String>[
          'r_fast',
          'r_med',
          'r_slow',
        ]);

        final byCalories = service.rankRecipes(
          recipes: <Recipe>[rSlowHighCal, rFastLowMatch, rMedium],
          fridgeItems: fridge,
          userProfile: baseUser,
          sort: RecommendationSort.calories,
        );
        expect(byCalories.map((r) => r.recipe.id).toList(), <String>[
          'r_med',
          'r_fast',
          'r_slow',
        ]);
      },
    );

    test('countPossibleRecipes counts results with >= 50% match', () {
      final results = <RecipeMatchResult>[
        RecipeMatchResult(
          recipe: MockData.recipes[0],
          matchPercentage: 100,
          matchedIngredients: const <String>['Poulet'],
          missingIngredients: const <String>[],
          usesExpiringSoonIngredient: true,
          hasAllergyConflict: false,
          difficultyLabel: 'Facile',
        ),
        RecipeMatchResult(
          recipe: MockData.recipes[1],
          matchPercentage: 50,
          matchedIngredients: const <String>['Saumon'],
          missingIngredients: const <String>['Riz basmati'],
          usesExpiringSoonIngredient: false,
          hasAllergyConflict: false,
          difficultyLabel: 'Facile',
        ),
        RecipeMatchResult(
          recipe: MockData.recipes[2],
          matchPercentage: 49,
          matchedIngredients: const <String>['Fruits rouges'],
          missingIngredients: const <String>['Yaourt grec'],
          usesExpiringSoonIngredient: false,
          hasAllergyConflict: false,
          difficultyLabel: 'Facile',
        ),
      ];

      expect(service.countPossibleRecipes(results), 2);
      expect(service.countPossibleRecipes(const <RecipeMatchResult>[]), 0);
    });
  });

  group('GeminiRecipeService Unit Tests', () {
    test('local demo fallback returns French suggestion referencing expiring items when API key is empty', () async {
      final service = GeminiRecipeService(apiKey: '');
      addTearDown(service.dispose);

      expect(service.hasApiKey, isFalse);

      final fridge = <FridgeItem>[
        _buildFridgeItem(
          id: 'f1',
          ingredientId: 'ing_spinach',
          name: 'Épinards frais',
          expiresInDays: 1,
        ),
        _buildFridgeItem(
          id: 'f2',
          ingredientId: 'ing_feta',
          name: 'Feta AOP',
          expiresInDays: 2,
        ),
      ];

      final idea = await service.generateAntiWasteIdea(
        fridgeItems: fridge,
        profile: MockData.defaultUser,
      );

      expect(idea, contains('Épinards frais'));
      expect(idea, contains('Feta AOP'));
      expect(
        idea,
        contains(
          'Mode démonstration locale — ajoutez GEMINI_API_KEY via --dart-define pour activer Gemini live',
        ),
      );
    });

    test('returns parsed Gemini response when API key is provided and handles HTTP 500 gracefully', () async {
      late Uri capturedUri;
      late String capturedMethod;
      late Map<String, Object?> capturedBody;

      final successClient = MockClient((request) async {
        capturedUri = request.url;
        capturedMethod = request.method;
        capturedBody = jsonDecode(request.body) as Map<String, Object?>;

        return http.Response(
          jsonEncode(<String, Object?>{
            'candidates': <Map<String, Object?>>[
              <String, Object?>{
                'content': <String, Object?>{
                  'parts': <Map<String, String>>[
                    <String, String>{
                      'text': 'Poêlée dorée épinards, feta et œufs · 12 min\n1. Faites suer les épinards...',
                    },
                  ],
                },
              },
            ],
          }),
          200,
          headers: const <String, String>{
            'content-type': 'application/json; charset=utf-8',
          },
        );
      });

      final liveService = GeminiRecipeService(
        client: successClient,
        apiKey: 'demo_test_key',
      );
      addTearDown(liveService.dispose);

      expect(liveService.hasApiKey, isTrue);

      final fridge = <FridgeItem>[
        _buildFridgeItem(
          id: 'f1',
          ingredientId: 'ing_spinach',
          name: 'Épinards frais',
          expiresInDays: 1,
        ),
      ];

      final liveIdea = await liveService.generateAntiWasteIdea(
        fridgeItems: fridge,
        profile: MockData.defaultUser,
      );

      expect(capturedMethod, 'POST');
      expect(
        capturedUri.toString(),
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=demo_test_key',
      );
      expect(capturedBody['contents'], isNotNull);
      expect(
        liveIdea,
        equals(
          'Poêlée dorée épinards, feta et œufs · 12 min\n1. Faites suer les épinards...',
        ),
      );

      final errorService = GeminiRecipeService(
        client: MockClient((_) async => http.Response('Server Error', 500)),
        apiKey: 'demo_test_key',
      );
      addTearDown(errorService.dispose);

      final fallbackIdea = await errorService.generateAntiWasteIdea(
        fridgeItems: fridge,
        profile: MockData.defaultUser,
      );

      expect(fallbackIdea, contains('Épinards frais'));
      expect(fallbackIdea, contains('suggestion locale'));

      final offlineService = GeminiRecipeService(
        client: MockClient(
          (_) async => throw const SocketException('Pas de réseau'),
        ),
        apiKey: 'demo_test_key',
      );
      addTearDown(offlineService.dispose);

      final offlineIdea = await offlineService.generateAntiWasteIdea(
        fridgeItems: fridge,
        profile: MockData.defaultUser,
      );

      expect(offlineIdea, contains('Épinards frais'));
      expect(offlineIdea, contains('suggestion locale'));
    });
  });

  group('Recommendations Providers Tests', () {
    test('recommendationsProvider ranks recipes and reacts to fridge and sort changes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final byMatch = container.read(recommendationsProvider);
      expect(byMatch, hasLength(MockData.recipes.length));
      expect(container.read(possibleRecipesCountProvider), 5);
      expect(byMatch.first.matchPercentage, 100);

      container.read(recommendationSortProvider.notifier).state =
          RecommendationSort.time;
      final byTime = container.read(recommendationsProvider);
      expect(byTime.first.recipe.id, 'rec_3'); // 10 min

      container.read(recommendationSortProvider.notifier).state =
          RecommendationSort.calories;
      final byCalories = container.read(recommendationsProvider);
      expect(byCalories.first.recipe.id, 'rec_5'); // 310 kcal

      container.read(fridgeProvider.notifier).removeItem('fi_feta');
      final afterRemove = container.read(recommendationsProvider);
      final salade = afterRemove.firstWhere((r) => r.recipe.id == 'rec_1');
      expect(salade.missingIngredients, contains('Feta'));
    });
  });

  group('RecommendationsScreen Widget Tests', () {
    void setPhoneViewport(WidgetTester tester) {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
    }

    Widget buildTestApp({
      GoRouter? customRouter,
      List<Override> overrides = const <Override>[],
    }) {
      final router =
          customRouter ??
          GoRouter(
            initialLocation: '/recommendations',
            routes: <RouteBase>[
              GoRoute(
                path: '/fridge',
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('FridgeStub'))),
              ),
              GoRoute(
                path: '/recommendations',
                builder: (context, state) => const RecommendationsScreen(),
              ),
              GoRoute(
                path: '/recipe/:id',
                builder: (context, state) {
                  final id = state.pathParameters['id'] ?? '';
                  return Scaffold(
                    appBar: AppBar(),
                    body: Center(child: Text('RecipeDetail:$id')),
                  );
                },
              ),
            ],
          );
      if (customRouter == null) {
        addTearDown(router.dispose);
      }

      return ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets(
      'Renders curved French header, sort toggles, match donuts, and ingredient chips',
      (tester) async {
        setPhoneViewport(tester);
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        expect(
          find.text('Recettes que vous pouvez cuisiner !'),
          findsOneWidget,
        );
        expect(
          find.text('Selon ce qui est déjà dans votre frigo.'),
          findsOneWidget,
        );
        expect(find.text('Suggestions IA'), findsOneWidget);
        expect(find.text('14 ingrédients'), findsOneWidget);
        expect(find.text('Profil : Healthy'), findsOneWidget);
        expect(find.text('Objectif : 2100 kcal'), findsOneWidget);

        expect(find.text('Match'), findsOneWidget);
        expect(find.text('Temps'), findsOneWidget);
        expect(find.text('Calories'), findsOneWidget);

        expect(find.byType(MatchDonut), findsAtLeastNWidgets(1));
        expect(find.text('MATCH'), findsAtLeastNWidgets(1));
        expect(find.text('Vous avez'), findsAtLeastNWidgets(1));
        expect(
          find.text('Tous les ingrédients disponibles !'),
          findsAtLeastNWidgets(1),
        );

        // Scroll to a partial-match card to verify dashed "Il manque" chips.
        final missingSection = find.text('Il manque').first;
        await tester.scrollUntilVisible(
          missingSection,
          250,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(missingSection, findsOneWidget);
        expect(find.textContaining('+ '), findsAtLeastNWidgets(1));

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Tapping sort toggles reorders recipe cards cleanly', (
      tester,
    ) async {
      setPhoneViewport(tester);
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Temps'));
      await tester.pumpAndSettle();

      final firstCardAfterTime = tester.widget<RecipeMatchCard>(
        find.byType(RecipeMatchCard).first,
      );
      expect(firstCardAfterTime.result.recipe.id, 'rec_3');

      await tester.tap(find.text('Calories'));
      await tester.pumpAndSettle();

      final firstCardAfterCal = tester.widget<RecipeMatchCard>(
        find.byType(RecipeMatchCard).first,
      );
      expect(firstCardAfterCal.result.recipe.id, 'rec_5');
    });

    testWidgets(
      'Tapping "Idée Gemini IA" displays French suggestion in modal bottom sheet',
      (tester) async {
        setPhoneViewport(tester);
        final mockGemini = GeminiRecipeService(apiKey: '');
        addTearDown(mockGemini.dispose);

        await tester.pumpWidget(
          buildTestApp(
            overrides: <Override>[
              geminiRecipeServiceProvider.overrideWithValue(mockGemini),
            ],
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Idée Gemini IA'));
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheet), findsOneWidget);
        expect(find.text('Idée anti-gaspi Gemini IA'), findsOneWidget);
        expect(find.textContaining('Épinards frais'), findsAtLeastNWidgets(1));
        expect(find.text('Fermer'), findsOneWidget);

        await tester.tap(find.text('Fermer'));
        await tester.pumpAndSettle();
        expect(find.byType(BottomSheet), findsNothing);
      },
    );

    testWidgets(
      'Navigates to recipe detail on "Voir la recette" and back to /fridge',
      (tester) async {
        setPhoneViewport(tester);
        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        final firstViewButton = find.text('Voir la recette').first;
        await tester.scrollUntilVisible(
          firstViewButton,
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(firstViewButton);
        await tester.pumpAndSettle();

        expect(find.textContaining('RecipeDetail:'), findsOneWidget);

        // Return to /recommendations and test top-left back button -> /fridge.
        await tester.pageBack();
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.byTooltip('Retour au frigo'),
          -200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Retour au frigo'));
        await tester.pumpAndSettle();

        expect(find.text('FridgeStub'), findsOneWidget);
      },
    );

    testWidgets('Renders without overflow on compact 800x600 viewport', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Recettes que vous pouvez cuisiner !'), findsOneWidget);
      expect(find.byType(RecipeMatchCard), findsAtLeastNWidgets(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Renders empty state and navigates to /fridge when results empty',
      (tester) async {
        setPhoneViewport(tester);
        await tester.pumpWidget(
          buildTestApp(
            overrides: <Override>[
              recommendationsProvider.overrideWithValue(
                const <RecipeMatchResult>[],
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('0 recette trouvée'), findsOneWidget);
        expect(find.text('Aucune recette trouvée'), findsOneWidget);

        final fridgeCta = find.text('Gérer mon frigo');
        await tester.scrollUntilVisible(
          fridgeCta,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(fridgeCta);
        await tester.pumpAndSettle();
        expect(find.text('FridgeStub'), findsOneWidget);
      },
    );
  });
}
