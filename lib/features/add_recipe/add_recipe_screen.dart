import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recipemate/core/models/ingredient.dart';
import 'package:recipemate/core/models/recipe.dart';
import 'package:recipemate/core/providers/app_providers.dart';
import 'package:recipemate/core/services/auth_error_mapper.dart';
import 'package:recipemate/core/utils/recipe_keywords.dart';
import 'package:recipemate/features/add_recipe/utils/recipe_validators.dart';
import 'package:recipemate/shared/widgets/app_snack_bar.dart';
import 'package:recipemate/shared/widgets/app_text_field.dart';
import 'package:recipemate/shared/widgets/secondary_app_bar.dart';

/// Controls one dynamic ingredient row. Each row owns its controllers, and
/// the screen disposes all of them in dispose() (widget lifecycle course).
class _IngredientInput {
  _IngredientInput({String name = '', String quantity = '', String unit = 'g'})
    : nameController = TextEditingController(text: name),
      quantityController = TextEditingController(text: quantity),
      unitController = TextEditingController(text: unit);

  final TextEditingController nameController;
  final TextEditingController quantityController;
  final TextEditingController unitController;

  void dispose() {
    nameController.dispose();
    quantityController.dispose();
    unitController.dispose();
  }
}

/// Controls one dynamic preparation step row.
class _StepInput {
  _StepInput({String text = ''})
    : controller = TextEditingController(text: text);

  final TextEditingController controller;

  void dispose() => controller.dispose();
}

/// Add-recipe form owned by Farah. Uses the shared [Recipe] model and saves
/// through FirestoreService; no parallel model is introduced.
class AddRecipeScreen extends ConsumerStatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  ConsumerState<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends ConsumerState<AddRecipeScreen> {
  // Point B2 : catégories imposées par le cahier des charges (E11).
  static const List<String> _categories = <String>[
    'Entrées',
    'Plats',
    'Desserts',
    'Petit-déjeuner',
    'Snacks',
  ];

  static const List<String> _difficulties = <String>[
    'Facile',
    'Moyen',
    'Difficile',
  ];

  static const List<String> _dietOptions = <String>[
    'Végétarien',
    'Vegan',
    'Sans gluten',
    'Keto',
    'Pescétarien',
  ];

  static const List<String> _allergenOptions = <String>[
    'Gluten',
    'Lait',
    'Œufs',
    'Arachides',
    'Poisson',
    'Soja',
  ];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prepTimeController = TextEditingController(text: '15');
  final _cookTimeController = TextEditingController(text: '20');
  final _servingsController = TextEditingController(text: '2');
  final _caloriesController = TextEditingController(text: '350');
  final _proteinController = TextEditingController(text: '15');
  final _carbsController = TextEditingController(text: '40');
  final _fatController = TextEditingController(text: '12');
  // Point B2 : fibres par portion (facultatif mais validé si saisi).
  final _fiberController = TextEditingController();

  final List<_IngredientInput> _ingredients = <_IngredientInput>[
    _IngredientInput(),
  ];
  final List<_StepInput> _steps = <_StepInput>[_StepInput()];

  final Set<String> _selectedDiets = <String>{};
  final Set<String> _selectedAllergens = <String>{};
  String _category = 'Plats';
  // Point B2 : difficulté enregistrée dans `recipes/{id}`.
  String _difficulty = 'Facile';

  XFile? _pickedImage;
  bool _isSaving = false;
  // Point B2 : visibilité par défaut, modifiable depuis le formulaire.
  bool _isPublic = true;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _servingsController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    for (final ingredient in _ingredients) {
      ingredient.dispose();
    }
    for (final step in _steps) {
      step.dispose();
    }
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    // Point A4 : SnackBar Material themé, au-dessus de la navigation.
    AppSnackBar.show(context, message);
  }

  /// Point B2 : la photo peut venir de la galerie ou de l'appareil photo.
  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await ref
          .read(storageServiceProvider)
          .pickRecipeImage(source);
      if (file != null) {
        setState(() => _pickedImage = file);
      }
    } on Object catch (error) {
      _showMessage('Sélection de l’image impossible : $error');
    }
  }

  /// Point B2 : permutation de deux étapes sans perdre leurs contrôleurs.
  void _moveStep(int index, int offset) {
    final target = index + offset;
    if (target < 0 || target >= _steps.length) {
      return;
    }
    setState(() {
      final moved = _steps.removeAt(index);
      _steps.insert(target, moved);
    });
  }

  /// Point B2 : validation, upload, sauvegarde complète et redirection.
  ///
  /// En cas d'erreur réseau, aucun contrôleur n'est vidé : la saisie reste
  /// disponible et l'utilisateur peut réessayer immédiatement.
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final user = ref.read(currentUserProvider);
    if (user == null) {
      _showMessage('Connectez-vous pour ajouter une recette.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      var imageUrl = '';
      if (_pickedImage != null) {
        imageUrl = await ref
            .read(storageServiceProvider)
            .uploadRecipeImage(
              file: _pickedImage!,
              uid: user.uid,
              fileName: '${DateTime.now().microsecondsSinceEpoch}.jpg',
            );
      }

      final ingredients = _ingredients
          .map(
            (input) => RecipeIngredient(
              ingredient: Ingredient(
                id: input.nameController.text.trim().toLowerCase().replaceAll(
                  RegExp(r'\s+'),
                  '_',
                ),
                name: input.nameController.text.trim(),
                category: IngredientCategory.other,
                defaultUnit: input.unitController.text.trim(),
              ),
              quantity:
                  double.tryParse(
                    input.quantityController.text.replaceAll(',', '.'),
                  ) ??
                  0,
              unit: input.unitController.text.trim(),
            ),
          )
          .toList(growable: false);

      final fiberText = _fiberController.text.trim();
      final fiberGrams = fiberText.isEmpty
          ? 0.0
          : double.parse(fiberText.replaceAll(',', '.'));

      final recipe = Recipe(
        id: 'recipe_${DateTime.now().microsecondsSinceEpoch}',
        // Métadonnées demandées pour `recipes/{recipeId}`.
        authorId: user.uid,
        isPublic: _isPublic,
        ingredientKeywords: RecipeKeywords.fromIngredients(ingredients),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: imageUrl,
        prepTimeMinutes: int.parse(_prepTimeController.text.trim()),
        cookTimeMinutes: int.parse(_cookTimeController.text.trim()),
        calories: int.parse(_caloriesController.text.trim()),
        proteinGrams: double.parse(
          _proteinController.text.trim().replaceAll(',', '.'),
        ),
        carbsGrams: double.parse(
          _carbsController.text.trim().replaceAll(',', '.'),
        ),
        fatGrams: double.parse(_fatController.text.trim().replaceAll(',', '.')),
        fiberGrams: fiberGrams,
        ingredients: ingredients,
        instructions: _steps
            .map((step) => step.controller.text.trim())
            .where((text) => text.isNotEmpty)
            .toList(growable: false),
        // Point B2 : catégorie, difficulté et régimes sont des champs
        // explicites ; `dietBadges` est conservé pour les anciens écrans qui
        // affichent la catégorie comme premier badge.
        category: _category,
        difficulty: _difficulty,
        dietTags: _selectedDiets.toList(growable: false),
        dietBadges: <String>[_category, ..._selectedDiets],
        allergens: _selectedAllergens.toList(growable: false),
        servings: int.parse(_servingsController.text.trim()),
      );

      await ref
          .read(firestoreServiceProvider)
          .saveRecipe(uid: user.uid, recipe: recipe);

      if (!mounted) {
        return;
      }
      final choice = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Recette ajoutée !'),
          content: Text(
            '« ${recipe.title} » est maintenant dans vos recettes.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('done'),
              child: const Text('Terminer'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop('details'),
              child: const Text('Voir la recette'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop('again'),
              child: const Text('Ajouter une autre'),
            ),
          ],
        ),
      );
      if (!mounted) {
        return;
      }
      switch (choice) {
        case 'again':
          _resetForm();
        case 'details':
          // Point B : on empile le détail pour garder un retour fonctionnel.
          await context.push('/recipe/${recipe.id}');
        default:
          context.pop();
      }
    } on Object catch (error, stackTrace) {
      // Point A2/B2 : trace technique complète et message utilisateur clair.
      debugPrint('[Ajout recette] $error\n$stackTrace');
      _showMessage(
        '${AuthErrorMapper.message(error)} Vos données ont été conservées.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _descriptionController.clear();
    _fiberController.clear();
    setState(() {
      for (final ingredient in _ingredients) {
        ingredient.nameController.clear();
        ingredient.quantityController.clear();
        ingredient.unitController.text = 'g';
      }
      for (final step in _steps) {
        step.controller.clear();
      }
      _selectedDiets.clear();
      _selectedAllergens.clear();
      _pickedImage = null;
      _category = 'Plats';
      _difficulty = 'Facile';
      _isPublic = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Point B : page secondaire avec flèche retour.
      appBar: const SecondaryAppBar(title: 'Ajouter une recette'),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _SectionTitle(title: 'Informations générales'),
              AppTextField(
                controller: _titleController,
                labelText: 'Nom de la recette',
                hintText: 'Ex. Salade de quinoa',
                validator: (value) => RecipeValidators.minLength(
                  value,
                  'Le nom de la recette',
                  3,
                ),
              ),
              const SizedBox(height: 14),
              AppTextField(
                controller: _descriptionController,
                labelText: 'Description',
                hintText: 'Présentez votre recette en quelques mots',
                maxLines: 3,
                validator: (value) =>
                    RecipeValidators.minLength(value, 'La description', 10),
              ),
              const SizedBox(height: 14),
              // Point B2 : deux sources possibles pour la photo.
              const _SectionTitle(title: 'Photo de la recette'),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Galerie'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Appareil photo'),
                    ),
                  ),
                ],
              ),
              if (_pickedImage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Image sélectionnée : ${_pickedImage!.name}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map(
                      (value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _category = value ?? _categories.first),
              ),
              const SizedBox(height: 12),
              // Point B2 : difficulté obligatoire dans le document Firestore.
              DropdownButtonFormField<String>(
                initialValue: _difficulty,
                decoration: const InputDecoration(
                  labelText: 'Difficulté',
                  border: OutlineInputBorder(),
                ),
                items: _difficulties
                    .map(
                      (value) => DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _difficulty = value ?? _difficulties.first),
              ),
              const SizedBox(height: 12),
              // Point B2 : `isPublic` est enregistré dans `recipes/{id}` et
              // pilote la visibilité de la recette pour les autres membres.
              SwitchListTile(
                value: _isPublic,
                title: const Text('Recette publique'),
                subtitle: Text(
                  _isPublic
                      ? 'Les autres membres pourront la consulter.'
                      : 'La recette restera privée.',
                ),
                onChanged: (value) => setState(() => _isPublic = value),
              ),
              const SizedBox(height: 20),
              const _SectionTitle(title: 'Temps et portions'),
              Row(
                children: <Widget>[
                  Expanded(
                    child: AppTextField(
                      controller: _prepTimeController,
                      labelText: 'Préparation (min)',
                      keyboardType: TextInputType.number,
                      validator: (value) => RecipeValidators.positiveInteger(
                        value,
                        'La préparation',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _cookTimeController,
                      labelText: 'Cuisson (min)',
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          RecipeValidators.positiveInteger(value, 'La cuisson'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _servingsController,
                labelText: 'Nombre de portions',
                keyboardType: TextInputType.number,
                validator: (value) =>
                    RecipeValidators.positiveInteger(value, 'Les portions'),
              ),
              const SizedBox(height: 20),
              const _SectionTitle(
                title: 'Valeurs nutritionnelles (par portion)',
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    child: AppTextField(
                      controller: _caloriesController,
                      labelText: 'Calories',
                      keyboardType: TextInputType.number,
                      validator: (value) => RecipeValidators.positiveInteger(
                        value,
                        'Les calories',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _proteinController,
                      labelText: 'Protéines (g)',
                      keyboardType: TextInputType.number,
                      validator: (value) => RecipeValidators.positiveNumber(
                        value,
                        'Les protéines',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: AppTextField(
                      controller: _carbsController,
                      labelText: 'Glucides (g)',
                      keyboardType: TextInputType.number,
                      validator: (value) => RecipeValidators.positiveNumber(
                        value,
                        'Les glucides',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      controller: _fatController,
                      labelText: 'Lipides (g)',
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          RecipeValidators.positiveNumber(value, 'Les lipides'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Point B2 : les fibres sont facultatives mais validées si saisies.
              AppTextField(
                controller: _fiberController,
                labelText: 'Fibres (g, facultatif)',
                hintText: 'Ex. 4',
                keyboardType: TextInputType.number,
                validator: (value) => RecipeValidators.optionalPositiveNumber(
                  value,
                  'Les fibres',
                ),
              ),
              const SizedBox(height: 20),
              const _SectionTitle(title: 'Ingrédients'),
              ..._buildIngredientFields(),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _ingredients.add(_IngredientInput())),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un ingrédient'),
              ),
              const SizedBox(height: 12),
              const _SectionTitle(title: 'Étapes de préparation'),
              ..._buildStepFields(),
              TextButton.icon(
                onPressed: () => setState(() => _steps.add(_StepInput())),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une étape'),
              ),
              const SizedBox(height: 20),
              const _SectionTitle(title: 'Régime alimentaire'),
              Wrap(
                spacing: 8,
                children: _dietOptions
                    .map(
                      (diet) => FilterChip(
                        label: Text(diet),
                        selected: _selectedDiets.contains(diet),
                        onSelected: (selected) => setState(
                          () => selected
                              ? _selectedDiets.add(diet)
                              : _selectedDiets.remove(diet),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 18),
              const _SectionTitle(title: 'Allergènes'),
              Wrap(
                spacing: 8,
                children: _allergenOptions
                    .map(
                      (allergen) => FilterChip(
                        label: Text(allergen),
                        selected: _selectedAllergens.contains(allergen),
                        onSelected: (selected) => setState(
                          () => selected
                              ? _selectedAllergens.add(allergen)
                              : _selectedAllergens.remove(allergen),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: const Icon(Icons.check),
                label: Text(
                  _isSaving ? 'Enregistrement...' : 'Enregistrer la recette',
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildIngredientFields() {
    return <Widget>[
      for (var index = 0; index < _ingredients.length; index++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _IngredientField(
            input: _ingredients[index],
            index: index,
            canRemove: _ingredients.length > 1,
            onRemove: () => setState(() {
              _ingredients[index].dispose();
              _ingredients.removeAt(index);
            }),
          ),
        ),
    ];
  }

  List<Widget> _buildStepFields() {
    return <Widget>[
      for (var index = 0; index < _steps.length; index++)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _StepField(
            input: _steps[index],
            index: index,
            canRemove: _steps.length > 1,
            // Point B2 : réordonnancement des étapes.
            canMoveUp: index > 0,
            canMoveDown: index < _steps.length - 1,
            onMoveUp: () => _moveStep(index, -1),
            onMoveDown: () => _moveStep(index, 1),
            onRemove: () => setState(() {
              _steps[index].dispose();
              _steps.removeAt(index);
            }),
          ),
        ),
    ];
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _IngredientField extends StatelessWidget {
  const _IngredientField({
    required this.input,
    required this.index,
    required this.canRemove,
    required this.onRemove,
  });

  final _IngredientInput input;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            AppTextField(
              controller: input.nameController,
              labelText: 'Ingrédient ${index + 1}',
              hintText: 'Ex. Tomate',
              validator: (value) =>
                  RecipeValidators.required(value, 'L’ingrédient'),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: AppTextField(
                    controller: input.quantityController,
                    labelText: 'Quantité',
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        RecipeValidators.positiveNumber(value, 'La quantité'),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 90,
                  child: AppTextField(
                    controller: input.unitController,
                    labelText: 'Unité',
                    validator: (value) =>
                        RecipeValidators.required(value, 'L’unité'),
                  ),
                ),
                if (canRemove)
                  IconButton(
                    tooltip: 'Supprimer cet ingrédient',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onRemove,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepField extends StatelessWidget {
  const _StepField({
    required this.input,
    required this.index,
    required this.canRemove,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
  });

  final _StepInput input;
  final int index;
  final bool canRemove;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            CircleAvatar(radius: 14, child: Text('${index + 1}')),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                controller: input.controller,
                labelText: 'Étape ${index + 1}',
                hintText: 'Décrivez cette étape',
                maxLines: 3,
                validator: (value) =>
                    RecipeValidators.required(value, 'L’étape'),
              ),
            ),
            // Point B2 : flèches pour déplacer une étape vers le haut/bas.
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconButton(
                  tooltip: 'Monter cette étape',
                  icon: const Icon(Icons.arrow_upward),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 30,
                  ),
                  onPressed: canMoveUp ? onMoveUp : null,
                ),
                IconButton(
                  tooltip: 'Descendre cette étape',
                  icon: const Icon(Icons.arrow_downward),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 30,
                  ),
                  onPressed: canMoveDown ? onMoveDown : null,
                ),
              ],
            ),
            if (canRemove)
              IconButton(
                tooltip: 'Supprimer cette étape',
                icon: const Icon(Icons.delete_outline),
                onPressed: onRemove,
              ),
          ],
        ),
      ),
    );
  }
}
