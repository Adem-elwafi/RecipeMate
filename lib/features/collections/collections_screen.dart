import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipemate/core/models/recipe.dart';
import 'package:recipemate/core/models/recipe_collection.dart';
import 'package:recipemate/core/providers/app_providers.dart';
import 'package:recipemate/core/utils/recipe_lookup.dart';
import 'package:recipemate/features/collections/add_to_collections_dialog.dart';
import 'package:recipemate/shared/widgets/app_snack_bar.dart';
import 'package:recipemate/shared/widgets/recipe_card.dart';
import 'package:recipemate/shared/widgets/secondary_app_bar.dart';

/// Collections screen owned by Farah.
///
/// Collections are stored in `users/{uid}/collections` (see FirestoreService).
/// Local UI state (which collection is open, dialogs) uses setState(), while
/// the collection list itself comes from the shared Riverpod stream provider.
class CollectionsScreen extends ConsumerStatefulWidget {
  const CollectionsScreen({super.key});

  @override
  ConsumerState<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends ConsumerState<CollectionsScreen> {
  String? _openCollectionId;

  void _openCollection(String id) => setState(() => _openCollectionId = id);

  void _closeCollection() => setState(() => _openCollectionId = null);

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    // Point A4 : un seul style de SnackBar dans tout le module.
    AppSnackBar.show(context, message);
  }

  /// Point B1 : choisit une recette puis coche plusieurs collections à la fois.
  Future<void> _addRecipeToCollections(String uid) async {
    final userRecipes = ref.read(userRecipesProvider(uid)).value ?? <Recipe>[];
    final sharedRecipes =
        ref.read(sharedRecipesProvider).value ?? const <Recipe>[];
    final allRecipes = RecipeLookup.all(userRecipes, sharedRecipes);
    if (allRecipes.isEmpty) {
      _showMessage('Aucune recette disponible pour le moment.');
      return;
    }

    final recipeId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Choisir une recette'),
        children: allRecipes
            .map(
              (recipe) => SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop(recipe.id),
                child: Text(recipe.title),
              ),
            )
            .toList(),
      ),
    );
    if (recipeId == null || !mounted) {
      return;
    }
    await showAddToCollectionsDialog(
      context: context,
      ref: ref,
      uid: uid,
      recipeId: recipeId,
    );
  }

  Future<String?> _askForName({
    String title = 'Nom de la collection',
    String? initial,
  }) {
    // Point A : le dialog possède désormais son contrôleur et sa clé de form.
    // Les disposer ici (juste après showDialog) les rendait invalides pendant
    // l'animation de sortie : le TextFormField se reconstruisait avec un
    // contrôleur dispose, ce qui cascadait en `_dependents.isEmpty`.
    return showDialog<String>(
      context: context,
      builder: (_) => _CollectionNameDialog(title: title, initial: initial),
    );
  }

  Future<void> _createCollection(String uid) async {
    final name = await _askForName();
    // Point A : l'écran peut avoir été quitté pendant l'attente du dialog.
    if (name == null || !mounted) {
      return;
    }
    try {
      await ref.read(firestoreServiceProvider).createCollection(uid, name);
      _showMessage('Collection « $name » créée.');
    } on Object catch (error, stackTrace) {
      debugPrint('[Collections] opération impossible : $error\n$stackTrace');
      _showMessage('Création impossible : $error');
    }
  }

  Future<void> _renameCollection(
    String uid,
    RecipeCollection collection,
  ) async {
    final name = await _askForName(
      title: 'Renommer la collection',
      initial: collection.name,
    );
    // Point A : garde-fou après l'attente du dialog de renommage.
    if (name == null || !mounted) {
      return;
    }
    try {
      await ref
          .read(firestoreServiceProvider)
          .renameCollection(uid, collection.id, name);
      _showMessage('Collection renommée.');
    } on Object catch (error, stackTrace) {
      debugPrint('[Collections] opération impossible : $error\n$stackTrace');
      _showMessage('Renommage impossible : $error');
    }
  }

  Future<void> _deleteCollection(
    String uid,
    RecipeCollection collection,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer cette collection ?'),
        content: Text(
          'La collection « ${collection.name} » sera supprimée. '
          'Les recettes elles-mêmes ne sont pas supprimées.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    // Point A : ne plus toucher au context ni au State après un await si
    // l'utilisateur a quitté l'écran entre-temps.
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      await ref
          .read(firestoreServiceProvider)
          .deleteCollection(uid, collection.id);
      if (!mounted) {
        return;
      }
      _closeCollection();
      _showMessage('Collection supprimée.');
    } on Object catch (error, stackTrace) {
      debugPrint('[Collections] opération impossible : $error\n$stackTrace');
      _showMessage('Suppression impossible : $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Point A : on ne dépend que de l'uid, ce qui rend l'écran testable sans
    // objet Firebase `User`.
    final uid = ref.watch(currentUidProvider);
    if (uid == null) {
      return const Scaffold(
        appBar: SecondaryAppBar(title: 'Mes collections'),
        body: Center(child: Text('Connectez-vous pour voir vos collections.')),
      );
    }

    final collectionsAsync = ref.watch(collectionsProvider(uid));
    final userRecipesAsync = ref.watch(userRecipesProvider(uid));
    final sharedRecipesAsync = ref.watch(sharedRecipesProvider);
    final allRecipes = RecipeLookup.all(
      userRecipesAsync.value ?? const <Recipe>[],
      sharedRecipesAsync.value ?? const <Recipe>[],
    );

    return Scaffold(
      // Point B : la liste est une page secondaire (retour au Profil) ;
      // le détail d'une collection utilise son propre retour interne.
      appBar: SecondaryAppBar(
        title: _openCollectionId == null
            ? 'Mes collections'
            : 'Détail de la collection',
        onBack: _openCollectionId == null ? null : _closeCollection,
      ),
      floatingActionButton: collectionsAsync.when(
        data: (collections) => Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FloatingActionButton.small(
              heroTag: 'multi_collections',
              tooltip: 'Ajouter à plusieurs collections',
              onPressed: () => _addRecipeToCollections(uid),
              child: const Icon(Icons.create_new_folder_outlined),
            ),
            const SizedBox(height: 12),
            FloatingActionButton(
              heroTag: _openCollectionId == null
                  ? 'create_collection'
                  : 'add_recipe_collection',
              tooltip: _openCollectionId == null
                  ? 'Créer une collection'
                  : 'Ajouter une recette',
              onPressed: _openCollectionId == null
                  ? () => _createCollection(uid)
                  : () => _showAddRecipeDialog(
                      uid: uid,
                      collections: collections,
                      allRecipes: allRecipes,
                    ),
              child: Icon(
                _openCollectionId == null ? Icons.add : Icons.add_link,
              ),
            ),
          ],
        ),
        loading: () => null,
        error: (_, __) => null,
      ),
      body: collectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur : $error')),
        data: (collections) {
          if (_openCollectionId != null) {
            RecipeCollection? collection;
            for (final item in collections) {
              if (item.id == _openCollectionId) {
                collection = item;
                break;
              }
            }
            final current = collection;
            if (current == null) {
              return const Center(child: Text('Collection introuvable.'));
            }
            return _CollectionDetailView(
              collection: current,
              recipes: current.recipeIds
                  .map((id) => RecipeLookup.find(id, allRecipes))
                  .whereType<Recipe>()
                  .toList(),
              onRemove: (recipeId) => _removeRecipe(
                uid: uid,
                collection: current,
                recipeId: recipeId,
              ),
              onRename: () => _renameCollection(uid, current),
              onDelete: () => _deleteCollection(uid, current),
            );
          }

          if (collections.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.folder_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Aucune collection pour l'instant",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Créez-en une avec le bouton + pour organiser vos '
                      'recettes.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface
                            .withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: collections.length,
            itemBuilder: (context, index) {
              final collection = collections[index];
              // Point A : clé unique par collection. Sans cela, l'ajout d'une
              // collection réutilise les éléments par index et peut laisser des
              // dépendances InheritedWidget orphelines (_dependents.isEmpty).
              return Card(
                key: ValueKey<String>('collection_${collection.id}'),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.folder_special_outlined),
                  title: Text(collection.name),
                  subtitle: Text('${collection.recipeIds.length} recette(s)'),
                  onTap: () => _openCollection(collection.id),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _removeRecipe({
    required String uid,
    required RecipeCollection collection,
    required String recipeId,
  }) async {
    final updated = collection.recipeIds
        .where((id) => id != recipeId)
        .toList(growable: false);
    try {
      await ref
          .read(firestoreServiceProvider)
          .updateRecipeIds(uid, collection.id, updated);
      _showMessage('Recette retirée de la collection.');
    } on Object catch (error, stackTrace) {
      debugPrint('[Collections] opération impossible : $error\n$stackTrace');
      _showMessage('Retrait impossible : $error');
    }
  }

  Future<void> _showAddRecipeDialog({
    required String uid,
    required List<RecipeCollection> collections,
    required List<Recipe> allRecipes,
  }) async {
    RecipeCollection? collection;
    for (final item in collections) {
      if (item.id == _openCollectionId) {
        collection = item;
        break;
      }
    }
    final current = collection;
    if (current == null) {
      return;
    }

    final available = allRecipes
        .where((recipe) => !current.recipeIds.contains(recipe.id))
        .toList(growable: false);
    if (available.isEmpty) {
      _showMessage('Toutes les recettes sont déjà dans cette collection.');
      return;
    }

    final selectedId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Ajouter une recette'),
        children: available
            .map(
              (recipe) => SimpleDialogOption(
                onPressed: () => Navigator.of(dialogContext).pop(recipe.id),
                child: Text(recipe.title),
              ),
            )
            .toList(),
      ),
    );
    // Point A : garde-fou après le second dialog (choix de la recette).
    if (selectedId == null || !mounted) {
      return;
    }
    try {
      await ref.read(firestoreServiceProvider).updateRecipeIds(
        uid,
        current.id,
        <String>[...current.recipeIds, selectedId],
      );
      _showMessage('Recette ajoutée à la collection.');
    } on Object catch (error, stackTrace) {
      debugPrint('[Collections] opération impossible : $error\n$stackTrace');
      _showMessage('Ajout impossible : $error');
    }
  }
}

/// Point A : dialog de saisie du nom de collection.
///
/// Le contrôleur et la clé de formulaire sont créés par instance, puis libérés
/// dans `dispose()` : le widget reste monté pendant toute l'animation de sortie
/// du dialog, donc plus aucun `TextEditingController was used after disposed`.
class _CollectionNameDialog extends StatefulWidget {
  const _CollectionNameDialog({required this.title, this.initial});

  final String title;
  final String? initial;

  @override
  State<_CollectionNameDialog> createState() => _CollectionNameDialogState();
}

class _CollectionNameDialogState extends State<_CollectionNameDialog> {
  late final TextEditingController _controller;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nom',
            hintText: 'Ex. Recettes du dimanche',
          ),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'Le nom est obligatoire.'
              : null,
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_controller.text.trim());
            }
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

class _CollectionDetailView extends StatelessWidget {
  const _CollectionDetailView({
    required this.collection,
    required this.recipes,
    required this.onRemove,
    required this.onRename,
    required this.onDelete,
  });

  final RecipeCollection collection;
  final List<Recipe> recipes;
  final void Function(String recipeId) onRemove;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  collection.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Renommer',
                icon: const Icon(Icons.edit_outlined),
                onPressed: onRename,
              ),
              IconButton(
                tooltip: 'Supprimer',
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
        Expanded(
          child: recipes.isEmpty
              ? const Center(
                  child: Text(
                    'Collection vide. Utilisez le bouton + pour ajouter '
                    'une recette.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: recipes.length,
                  itemBuilder: (context, index) {
                    final recipe = recipes[index];
                    // Point A : même précaution pour la liste du détail.
                    return Padding(
                      key: ValueKey<String>('recipe_${recipe.id}'),
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Stack(
                        alignment: Alignment.topRight,
                        children: <Widget>[
                          RecipeCard(recipe: recipe, showMatchBar: false),
                          IconButton(
                            tooltip: 'Retirer de la collection',
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => onRemove(recipe.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
