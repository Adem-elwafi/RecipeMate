# Graph Report - RecipeMate  (2026-11-22)

## Corpus Check
- 83 files · ~53,301 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 705 nodes · 970 edges · 42 communities detected
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 5 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `7ccea932`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 23|Community 23]]
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 26|Community 26]]
- [[_COMMUNITY_Community 27|Community 27]]
- [[_COMMUNITY_Community 28|Community 28]]
- [[_COMMUNITY_Community 29|Community 29]]
- [[_COMMUNITY_Community 30|Community 30]]
- [[_COMMUNITY_Community 31|Community 31]]
- [[_COMMUNITY_Community 32|Community 32]]
- [[_COMMUNITY_Community 33|Community 33]]
- [[_COMMUNITY_Community 34|Community 34]]
- [[_COMMUNITY_Community 35|Community 35]]
- [[_COMMUNITY_Community 36|Community 36]]
- [[_COMMUNITY_Community 37|Community 37]]
- [[_COMMUNITY_Community 38|Community 38]]
- [[_COMMUNITY_Community 39|Community 39]]
- [[_COMMUNITY_Community 40|Community 40]]
- [[_COMMUNITY_Community 41|Community 41]]

## God Nodes (most connected - your core abstractions)
1. `package:flutter/material.dart` - 41 edges
2. `package:recipemate/core/theme/app_colors.dart` - 34 edges
3. `package:recipemate/core/theme/app_text_styles.dart` - 23 edges
4. `package:go_router/go_router.dart` - 19 edges
5. `package:google_fonts/google_fonts.dart` - 19 edges
6. `package:recipemate/core/data/mock_data.dart` - 17 edges
7. `package:flutter_riverpod/flutter_riverpod.dart` - 14 edges
8. `package:recipemate/core/models/ingredient.dart` - 14 edges
9. `package:recipemate/shared/widgets/feature_placeholder.dart` - 14 edges
10. `package:recipemate/core/models/fridge_item.dart` - 12 edges

## Surprising Connections (you probably didn't know these)
- `OnCreate()` --calls--> `RegisterPlugins()`  [INFERRED]
  windows/runner/flutter_window.cpp → windows/flutter/generated_plugin_registrant.cc
- `OnCreate()` --calls--> `GetClientArea()`  [INFERRED]
  windows/runner/flutter_window.cpp → windows/runner/win32_window.cpp
- `OnCreate()` --calls--> `SetChildContent()`  [INFERRED]
  windows/runner/flutter_window.cpp → windows/runner/win32_window.cpp
- `wWinMain()` --calls--> `CreateAndAttachConsole()`  [INFERRED]
  windows/runner/main.cpp → windows/runner/utils.cpp
- `wWinMain()` --calls--> `GetCommandLineArguments()`  [INFERRED]
  windows/runner/main.cpp → windows/runner/utils.cpp

## Communities (53 total, 6 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.04
Nodes (51): _addToFridge, _AllergensCard, _backgroundColor, build, _buildLoadedContent, CircularProgressIndicator, Column, ConstrainedBox (+43 more)

### Community 1 - "Community 1"
Cohesion: 0.06
Nodes (45): _decodeResponseBody, _demoFallbackOrThrow, dispose, OpenFoodFactsService, ProductNotFoundException, toString, _buildLocalDemoSuggestion, _buildPrompt (+37 more)

### Community 2 - "Community 2"
Cohesion: 0.05
Nodes (43): build, ChoiceChip, dispose, ExploreScreen, _ExploreScreenState, FeaturePlaceholder, RecipeCard, Scaffold (+35 more)

### Community 3 - "Community 3"
Cohesion: 0.05
Nodes (42): build, Center, ClipRRect, _closeScanner, Container, _CornerBracketsPainter, _DemoBarcodeChip, _DetectedProductCard (+34 more)

### Community 4 - "Community 4"
Cohesion: 0.06
Nodes (32): build, _CategoryFilterPill, Container, _deleteItem, _EmptyFridgeCard, FeaturePlaceholder, FridgeScreen, _FridgeScreenState (+24 more)

### Community 5 - "Community 5"
Cohesion: 0.06
Nodes (33): build, _buildBadgesCard, _buildButtonsCard, _buildColorsGrid, _buildMacroRingsCard, _buildMatchBarCard, _buildRecipeCardsSection, _buildSectionHeader (+25 more)

### Community 6 - "Community 6"
Cohesion: 0.06
Nodes (30): AddRecipeScreen, _AddRecipeScreenState, build, dispose, FeaturePlaceholder, _save, Scaffold, SizedBox (+22 more)

### Community 7 - "Community 7"
Cohesion: 0.07
Nodes (28): addCredentials, addProxyCredentials, close, createHttpClient, Function, main, _MockHttpClient, _MockHttpClientRequest (+20 more)

### Community 8 - "Community 8"
Cohesion: 0.11
Nodes (19): RegisterPlugins(), FlutterWindow(), OnCreate(), Create(), Destroy(), EnableFullDpiSupportIfAvailable(), GetClientArea(), GetThisFromHandle() (+11 more)

### Community 9 - "Community 9"
Cohesion: 0.07
Nodes (25): build, MatchDonut, _MatchDonutPainter, paint, Semantics, shouldRepaint, SizedBox, _AllIngredientsAvailablePill (+17 more)

### Community 10 - "Community 10"
Cohesion: 0.08
Nodes (24): build, Container, _cycleUnit, DateTime, _decrementQuantity, _defaultExpirationDate, dispose, FridgeQuickAddCard (+16 more)

### Community 11 - "Community 11"
Cohesion: 0.08
Nodes (23): addCredentials, addProxyCredentials, _buildFridgeItem, _buildRecipe, buildTestApp, close, createHttpClient, DateTime (+15 more)

### Community 12 - "Community 12"
Cohesion: 0.09
Nodes (22): build, ClipRRect, Container, _EmptyRecommendationsCard, FeaturePlaceholder, _handleBack, _HeaderContextPill, Icon (+14 more)

### Community 13 - "Community 13"
Cohesion: 0.11
Nodes (17): copyWith, defaultShelfLifeForCategory, _formatUnknownTag, Ingredient, _isAmbiguousOrSubstituteTag, _mapCategory, _matchesBakery, _matchesDairy (+9 more)

### Community 14 - "Community 14"
Cohesion: 0.11
Nodes (17): CookingModeScreen, ProductScreen, RecipeDetailsScreen, Scaffold, package:recipemate/features/add_recipe/add_recipe_screen.dart, package:recipemate/features/auth/auth_screen.dart, package:recipemate/features/collections/collections_screen.dart, package:recipemate/features/cooking_mode/cooking_mode_screen.dart (+9 more)

### Community 15 - "Community 15"
Cohesion: 0.12
Nodes (15): addItem, build, computePossibleRecipesCount, copyWith, dayOffset, formatFridgeQuantity, FridgeCategoryFilter, FridgeNotifier (+7 more)

### Community 16 - "Community 16"
Cohesion: 0.13
Nodes (14): build, _decrement, _FridgeEditSheetContent, _FridgeEditSheetContentState, Icon, _increment, initState, SafeArea (+6 more)

### Community 17 - "Community 17"
Cohesion: 0.15
Nodes (12): Recipe, _compareResults, _computeDifficultyLabel, countPossibleRecipes, _hasAllergyConflict, _ingredientsMatch, MatchingService, RecommendationSort (+4 more)

### Community 18 - "Community 18"
Cohesion: 0.15
Nodes (12): build, ColoredBox, Column, DecoratedBox, FeaturePlaceholder, initState, _metricItem, Padding (+4 more)

### Community 19 - "Community 19"
Cohesion: 0.18
Nodes (10): AnimatedContainer, build, Column, dispose, FeaturePlaceholder, OnboardingScreen, _OnboardingScreenState, _onNext (+2 more)

### Community 20 - "Community 20"
Cohesion: 0.2
Nodes (9): build, CollectionsScreen, _CollectionsScreenState, Container, _deleteCollection, FeaturePlaceholder, Scaffold, SizedBox (+1 more)

### Community 21 - "Community 21"
Cohesion: 0.22
Nodes (8): build, Column, Container, GeminiAntiWasteCard, Icon, Row, SafeArea, SizedBox

### Community 22 - "Community 22"
Cohesion: 0.25
Nodes (7): IconThemeData, ThemeData, build, Container, DietBadge, package:recipemate/core/theme/app_colors.dart, package:recipemate/core/theme/app_text_styles.dart

### Community 23 - "Community 23"
Cohesion: 0.22
Nodes (7): copyWith, DateFormat, FridgeItem, copyWith, Recipe, package:intl/intl.dart, package:recipemate/core/models/ingredient.dart

### Community 24 - "Community 24"
Cohesion: 0.25
Nodes (7): build, Container, FavoriteButton, OutlineButtonWidget, PrimaryButton, SizedBox, TonalButton

### Community 25 - "Community 25"
Cohesion: 0.25
Nodes (6): Ingredient, IngredientCategory, RecipeIngredient, copyWith, UserProfile, package:flutter/foundation.dart

### Community 26 - "Community 26"
Cohesion: 0.29
Nodes (6): build, _CardActionButton, Container, FridgeItemCard, Semantics, SizedBox

### Community 27 - "Community 27"
Cohesion: 0.29
Nodes (5): AppTextField, build, Column, SizedBox, package:google_fonts/google_fonts.dart

### Community 28 - "Community 28"
Cohesion: 0.29
Nodes (6): build, Column, Container, FridgeStatsBanner, SizedBox, _StatColumn

### Community 29 - "Community 29"
Cohesion: 0.33
Nodes (3): FlutterAppDelegate, FlutterImplicitEngineDelegate, AppDelegate

### Community 30 - "Community 30"
Cohesion: 0.33
Nodes (5): build, Column, Icon, MatchBar, SizedBox

### Community 31 - "Community 31"
Cohesion: 0.33
Nodes (4): AppNavBar, build, NavigationBar, package:flutter/material.dart

### Community 32 - "Community 32"
Cohesion: 0.47
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

### Community 33 - "Community 33"
Cohesion: 0.4
Nodes (4): build, Column, MacroRing, SizedBox

### Community 34 - "Community 34"
Cohesion: 0.4
Nodes (4): package:recipemate/features/fridge/providers/fridge_provider.dart, package:recipemate/features/recommendations/models/recipe_match_result.dart, package:recipemate/features/recommendations/services/gemini_recipe_service.dart, package:recipemate/features/recommendations/services/matching_service.dart

### Community 37 - "Community 37"
Cohesion: 0.5
Nodes (3): identical, RecipeMatchResult, package:recipemate/core/models/recipe.dart

## Knowledge Gaps
- **539 isolated node(s):** `MainActivity`, `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `FlutterAppDelegate`, `FlutterImplicitEngineDelegate`, `-registerWithRegistry` (+534 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Community 31` to `Community 0`, `Community 1`, `Community 2`, `Community 3`, `Community 4`, `Community 5`, `Community 6`, `Community 7`, `Community 9`, `Community 10`, `Community 11`, `Community 12`, `Community 14`, `Community 16`, `Community 18`, `Community 19`, `Community 20`, `Community 21`, `Community 22`, `Community 24`, `Community 26`, `Community 27`, `Community 28`, `Community 30`, `Community 33`?**
  _High betweenness centrality (0.224) - this node is a cross-community bridge._
- **Why does `package:recipemate/core/theme/app_colors.dart` connect `Community 22` to `Community 0`, `Community 1`, `Community 2`, `Community 3`, `Community 4`, `Community 5`, `Community 6`, `Community 9`, `Community 10`, `Community 12`, `Community 16`, `Community 18`, `Community 19`, `Community 20`, `Community 21`, `Community 24`, `Community 26`, `Community 27`, `Community 28`, `Community 30`, `Community 31`, `Community 33`?**
  _High betweenness centrality (0.122) - this node is a cross-community bridge._
- **Why does `package:recipemate/core/models/ingredient.dart` connect `Community 23` to `Community 0`, `Community 1`, `Community 4`, `Community 10`, `Community 11`, `Community 13`, `Community 15`, `Community 17`, `Community 26`?**
  _High betweenness centrality (0.066) - this node is a cross-community bridge._
- **What connects `MainActivity`, `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `FlutterAppDelegate` to the rest of the system?**
  _539 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.06 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._