# Graph Report - RecipeMate  (2026-11-16)

## Corpus Check
- 62 files · ~28,319 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 373 nodes · 486 edges · 23 communities detected
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 5 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `776952a5`
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

## God Nodes (most connected - your core abstractions)
1. `package:flutter/material.dart` - 29 edges
2. `package:recipemate/core/theme/app_colors.dart` - 24 edges
3. `package:recipemate/core/theme/app_text_styles.dart` - 22 edges
4. `package:go_router/go_router.dart` - 14 edges
5. `package:recipemate/shared/widgets/feature_placeholder.dart` - 14 edges
6. `package:recipemate/core/data/mock_data.dart` - 11 edges
7. `package:google_fonts/google_fonts.dart` - 7 edges
8. `package:recipemate/core/models/recipe.dart` - 6 edges
9. `Create()` - 6 edges
10. `Destroy()` - 6 edges

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

## Communities (34 total, 6 thin omitted)

### Community 0 - "Community 0"
Cohesion: 0.06
Nodes (37): IconThemeData, ThemeData, build, Container, FavoriteButton, OutlineButtonWidget, PrimaryButton, SizedBox (+29 more)

### Community 1 - "Community 1"
Cohesion: 0.06
Nodes (34): build, ChoiceChip, dispose, ExploreScreen, _ExploreScreenState, FeaturePlaceholder, RecipeCard, Scaffold (+26 more)

### Community 2 - "Community 2"
Cohesion: 0.06
Nodes (33): addCredentials, addProxyCredentials, close, createHttpClient, Function, main, _MockHttpClient, _MockHttpClientRequest (+25 more)

### Community 3 - "Community 3"
Cohesion: 0.06
Nodes (29): AddRecipeScreen, _AddRecipeScreenState, build, dispose, FeaturePlaceholder, _save, Scaffold, SizedBox (+21 more)

### Community 4 - "Community 4"
Cohesion: 0.11
Nodes (19): RegisterPlugins(), FlutterWindow(), OnCreate(), Create(), Destroy(), EnableFullDpiSupportIfAvailable(), GetClientArea(), GetThisFromHandle() (+11 more)

### Community 5 - "Community 5"
Cohesion: 0.08
Nodes (22): build, ColoredBox, Column, DecoratedBox, FeaturePlaceholder, initState, _metricItem, Padding (+14 more)

### Community 6 - "Community 6"
Cohesion: 0.1
Nodes (19): CookingModeScreen, ProductScreen, RecipeDetailsScreen, Scaffold, package:recipemate/features/add_recipe/add_recipe_screen.dart, package:recipemate/features/auth/auth_screen.dart, package:recipemate/features/collections/collections_screen.dart, package:recipemate/features/cooking_mode/cooking_mode_screen.dart (+11 more)

### Community 7 - "Community 7"
Cohesion: 0.11
Nodes (16): Recipe, build, Container, FeaturePlaceholder, FridgeScreen, _FridgeScreenState, Icon, initState (+8 more)

### Community 8 - "Community 8"
Cohesion: 0.12
Nodes (13): copyWith, DateFormat, FridgeItem, Ingredient, IngredientCategory, RecipeIngredient, copyWith, Recipe (+5 more)

### Community 9 - "Community 9"
Cohesion: 0.15
Nodes (12): _addToFridge, build, Container, FeaturePlaceholder, Icon, ProductScreen, _ProductScreenState, Scaffold (+4 more)

### Community 10 - "Community 10"
Cohesion: 0.15
Nodes (12): build, CookingModeScreen, _CookingModeScreenState, dispose, FeaturePlaceholder, Icon, _resetTimer, Scaffold (+4 more)

### Community 11 - "Community 11"
Cohesion: 0.15
Nodes (12): build, Center, dispose, FeaturePlaceholder, Icon, _onDetect, _openManualEntry, Scaffold (+4 more)

### Community 12 - "Community 12"
Cohesion: 0.17
Nodes (11): build, DietBadge, Divider, FeaturePlaceholder, _goalRow, Material, ProfileScreen, _quickLinkCard (+3 more)

### Community 13 - "Community 13"
Cohesion: 0.2
Nodes (9): build, CollectionsScreen, _CollectionsScreenState, Container, _deleteCollection, FeaturePlaceholder, Scaffold, SizedBox (+1 more)

### Community 14 - "Community 14"
Cohesion: 0.29
Nodes (6): build, main, RecipeMateApp, package:flutter_riverpod/flutter_riverpod.dart, package:recipemate/core/router/app_router.dart, package:recipemate/core/theme/app_theme.dart

### Community 15 - "Community 15"
Cohesion: 0.33
Nodes (3): FlutterAppDelegate, FlutterImplicitEngineDelegate, AppDelegate

### Community 16 - "Community 16"
Cohesion: 0.47
Nodes (4): wWinMain(), CreateAndAttachConsole(), GetCommandLineArguments(), Utf8FromUtf16()

## Knowledge Gaps
- **250 isolated node(s):** `MainActivity`, `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `FlutterAppDelegate`, `FlutterImplicitEngineDelegate`, `-registerWithRegistry` (+245 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Community 0` to `Community 1`, `Community 2`, `Community 3`, `Community 5`, `Community 6`, `Community 7`, `Community 9`, `Community 10`, `Community 11`, `Community 12`, `Community 13`, `Community 14`?**
  _High betweenness centrality (0.247) - this node is a cross-community bridge._
- **Why does `package:recipemate/core/theme/app_colors.dart` connect `Community 0` to `Community 1`, `Community 3`, `Community 5`, `Community 7`, `Community 9`, `Community 10`, `Community 11`, `Community 12`, `Community 13`?**
  _High betweenness centrality (0.092) - this node is a cross-community bridge._
- **Why does `package:recipemate/core/theme/app_text_styles.dart` connect `Community 0` to `Community 1`, `Community 3`, `Community 5`, `Community 7`, `Community 9`, `Community 10`, `Community 11`, `Community 12`, `Community 13`?**
  _High betweenness centrality (0.084) - this node is a cross-community bridge._
- **What connects `MainActivity`, `Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages.`, `FlutterAppDelegate` to the rest of the system?**
  _250 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.06 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.06 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.06 - nodes in this community are weakly interconnected._