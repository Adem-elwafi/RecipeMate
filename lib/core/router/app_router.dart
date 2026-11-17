import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:recipemate/features/add_recipe/add_recipe_screen.dart';
import 'package:recipemate/features/auth/auth_screen.dart';
import 'package:recipemate/features/collections/collections_screen.dart';
import 'package:recipemate/features/cooking_mode/cooking_mode_screen.dart';
import 'package:recipemate/features/explore/explore_screen.dart';
import 'package:recipemate/features/favorites/favorites_screen.dart';
import 'package:recipemate/features/fridge/fridge_screen.dart';
import 'package:recipemate/features/home/home_screen.dart';
import 'package:recipemate/features/onboarding/onboarding_screen.dart';
import 'package:recipemate/features/playground/playground_screen.dart';
import 'package:recipemate/features/product/product_screen.dart';
import 'package:recipemate/features/profile/profile_screen.dart';
import 'package:recipemate/features/recipe_details/recipe_details_screen.dart';
import 'package:recipemate/features/recommendations/recommendations_screen.dart';
import 'package:recipemate/features/scanner/scanner_screen.dart';
import 'package:recipemate/shared/widgets/app_nav_bar.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

/// Central GoRouter configuration for RecipeMate.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    // Shell Route for 5 Bottom Bar Tabs
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: AppNavBar(
            currentIndex: navigationShell.currentIndex,
            onTap: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
          ),
        );
      },
      branches: [
        // Tab 0: Accueil (Molka)
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          ],
        ),

        // Tab 1: Explorer (Molka)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/explore',
              builder: (context, state) => const ExploreScreen(),
            ),
          ],
        ),

        // Tab 2: Mon Frigo (Adem)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/fridge',
              builder: (context, state) => const FridgeScreen(),
            ),
          ],
        ),

        // Tab 3: Recettes IA (Adem)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/recommendations',
              builder: (context, state) => const RecommendationsScreen(),
            ),
          ],
        ),

        // Tab 4: Profil (Farah)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),

    // Recipe Details (Molka)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/recipe/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? 'rec_1';
        return RecipeDetailsScreen(recipeId: id);
      },
    ),

    // Cooking Mode Step-by-Step (Molka)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/cooking/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? 'rec_1';
        return CookingModeScreen(recipeId: id);
      },
    ),

    // Barcode Scanner (Adem)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/scanner',
      builder: (context, state) => const ScannerScreen(),
    ),

    // Product Detail (Adem)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/product/:barcode',
      builder: (context, state) {
        final barcode = state.pathParameters['barcode'] ?? '';
        return ProductScreen(barcode: barcode);
      },
    ),

    // Onboarding (Farah)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    // Auth (Farah)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),

    // Favorites (Farah)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/favorites',
      builder: (context, state) => const FavoritesScreen(),
    ),

    // Collections (Farah)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/collections',
      builder: (context, state) => const CollectionsScreen(),
    ),

    // Add Recipe (Farah)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/add-recipe',
      builder: (context, state) => const AddRecipeScreen(),
    ),

    // Design System Playground
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/playground',
      builder: (context, state) => const PlaygroundScreen(),
    ),
  ],
);
