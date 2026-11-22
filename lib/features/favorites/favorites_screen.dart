import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipemate/core/models/recipe.dart';
import 'package:recipemate/core/providers/app_providers.dart';
import 'package:recipemate/core/utils/recipe_lookup.dart';
import 'package:recipemate/features/collections/add_to_collections_dialog.dart';
import 'package:recipemate/shared/widgets/app_snack_bar.dart';
import 'package:recipemate/shared/widgets/recipe_card.dart';
import 'package:recipemate/shared/widgets/secondary_app_bar.dart';

/// Point B1 : liste des favoris de l'utilisateur.
///
/// Les identifiants viennent de Firestore ; les recettes elles-mêmes sont
/// résolues depuis le catalogue, les recettes de l'utilisateur et les documents
/// partagés `recipes/{id}`. Le [RecipeCard] appelle le service partagé via une
/// seule implémentation de `toggleFavorite`.
class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(
        // Point B : même la version « déconnecté » doit rester quitteable.
        appBar: SecondaryAppBar(title: 'Mes favoris'),
        body: _FavoritesMessage(
          icon: Icons.lock_outline,
          message: 'Connectez-vous pour voir vos favoris.',
        ),
      );
    }

    final favoriteIdsAsync = ref.watch(favoriteIdsProvider(user.uid));
    final userRecipesAsync = ref.watch(userRecipesProvider(user.uid));
    final sharedRecipesAsync = ref.watch(sharedRecipesProvider);

    Future<void> toggleFavorite(String recipeId) async {
      try {
        await ref.read(favoritesServiceProvider).toggleFavorite(recipeId);
      } on Object catch (error, stackTrace) {
        debugPrint('[Favoris] bascule impossible : $error\n$stackTrace');
        if (context.mounted) {
          AppSnackBar.show(context, 'Impossible de modifier le favori.');
        }
      }
    }

    return Scaffold(
      // Point B : page secondaire avec retour standard.
      appBar: const SecondaryAppBar(title: 'Mes favoris'),
      body: favoriteIdsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _FavoritesMessage(
          icon: Icons.error_outline,
          message: 'Impossible de charger les favoris : $error',
        ),
        data: (ids) {
          if (ids.isEmpty) {
            return const _FavoritesMessage(
              icon: Icons.favorite_border,
              message: "Aucune recette en favori pour l'instant",
            );
          }

          final recipes = <Recipe>[];
          final allRecipes = RecipeLookup.all(
            userRecipesAsync.value ?? const <Recipe>[],
            sharedRecipesAsync.value ?? const <Recipe>[],
          );
          for (final id in ids) {
            final selected = allRecipes
                .where((Recipe item) => item.id == id)
                .firstOrNull;
            if (selected != null) {
              // Le flag local de l'asset ne fait pas foi : le stream Firestore
              // des favoris est la source de vérité sur cet écran.
              recipes.add(selected.copyWith(isFavorite: true));
            }
          }

          if (recipes.isEmpty) {
            return const _FavoritesMessage(
              icon: Icons.favorite_border,
              message: 'Ces recettes ne sont plus disponibles.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    RecipeCard(
                      recipe: recipe,
                      showMatchBar: false,
                      onFavoriteToggle: () => toggleFavorite(recipe.id),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => showAddToCollectionsDialog(
                          context: context,
                          ref: ref,
                          uid: user.uid,
                          recipeId: recipe.id,
                        ),
                        icon: const Icon(
                          Icons.create_new_folder_outlined,
                          size: 18,
                        ),
                        label: const Text('Ajouter à une collection'),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FavoritesMessage extends StatelessWidget {
  const _FavoritesMessage({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 64, color: colors.primary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
