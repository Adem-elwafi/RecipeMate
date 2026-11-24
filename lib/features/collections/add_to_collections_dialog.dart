import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipemate/core/models/recipe_collection.dart';
import 'package:recipemate/core/providers/app_providers.dart';
import 'package:recipemate/shared/widgets/app_snack_bar.dart';

/// Point B1 : ajoute une recette à plusieurs collections en une seule écriture.
///
/// Ce dialogue est partagé entre « Favoris » et « Collections » pour que le
/// geste soit identique partout, tout en restant dans le module Farah.
Future<void> showAddToCollectionsDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String uid,
  required String recipeId,
}) async {
  final collections =
      ref.read(collectionsProvider(uid)).value ?? const <RecipeCollection>[];
  if (collections.isEmpty) {
    AppSnackBar.show(context, 'Créez d’abord une collection.');
    return;
  }

  final selected = await showDialog<Set<String>>(
    context: context,
    builder: (dialogContext) =>
        _AddToCollectionsDialog(collections: collections),
  );
  if (selected == null || selected.isEmpty) {
    return;
  }

  try {
    await ref
        .read(firestoreServiceProvider)
        .addRecipeToCollections(uid, recipeId, selected);
    if (context.mounted) {
      AppSnackBar.show(
        context,
        selected.length == 1
            ? 'Recette ajoutée à 1 collection.'
            : 'Recette ajoutée à ${selected.length} collections.',
      );
    }
  } on Object catch (error, stackTrace) {
    // Point A2/B2 : on garde la trace complète pour le diagnostic sur mobile.
    debugPrint('[Collections] ajout impossible : $error\n$stackTrace');
    if (context.mounted) {
      AppSnackBar.show(context, 'Ajout impossible. Réessayez.');
    }
  }
}

class _AddToCollectionsDialog extends StatefulWidget {
  const _AddToCollectionsDialog({required this.collections});

  final List<RecipeCollection> collections;

  @override
  State<_AddToCollectionsDialog> createState() =>
      _AddToCollectionsDialogState();
}

class _AddToCollectionsDialogState extends State<_AddToCollectionsDialog> {
  final Set<String> _selected = <String>{};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter à des collections'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (final collection in widget.collections)
                CheckboxListTile(
                  value: _selected.contains(collection.id),
                  title: Text(collection.name),
                  subtitle: Text('${collection.recipeIds.length} recette(s)'),
                  onChanged: (checked) => setState(() {
                    if (checked ?? false) {
                      _selected.add(collection.id);
                    } else {
                      _selected.remove(collection.id);
                    }
                  }),
                ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.of(context).pop(Set<String>.from(_selected)),
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
