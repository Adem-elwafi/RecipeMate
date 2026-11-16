import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:recipemate/core/data/mock_data.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/core/theme/app_text_styles.dart';
import 'package:recipemate/shared/widgets/recipe_card.dart';

/// Favorites screen showing saved recipes (Owner: Farah).
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = MockData.recipes.where((r) => r.isFavorite).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mes Favoris (${favorites.length})',
          style: AppTextStyles.title.copyWith(fontSize: 20),
        ),
      ),
      body: favorites.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.favorite_border_rounded,
                      size: 64,
                      color: AppColors.greyIcon,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun favori pour le moment',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Explorez les recettes et touchez le cœur pour les retrouver ici.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: favorites.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final recipe = favorites[index];
                return RecipeCard(
                  recipe: recipe,
                  onTap: () => context.push('/recipe/${recipe.id}'),
                );
              },
            ),
    );
  }
}
