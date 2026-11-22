import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recipemate/core/models/user_profile.dart';
import 'package:recipemate/core/providers/app_providers.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/core/theme/app_text_styles.dart';
import 'package:recipemate/shared/widgets/app_snack_bar.dart';
import 'package:recipemate/shared/widgets/app_text_field.dart';
import 'package:recipemate/shared/widgets/recipemate_app_bar.dart';

/// Écran Profil (Farah).
///
/// Point 5 : aucune valeur inventée, les champs vides affichent « Non renseigné ».
/// Point 6 : le formulaire est découpé en sections avec des labels visibles.
/// Point 8 : la sécurité et le mot de passe sont déplacés vers Paramètres.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  ImageProvider? _getProfileImageProvider(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return null;
    }
    if (photoUrl.startsWith('data:')) {
      try {
        final commaIndex = photoUrl.indexOf(',');
        if (commaIndex != -1) {
          final bytes = base64Decode(photoUrl.substring(commaIndex + 1));
          return MemoryImage(bytes);
        }
      } on Object {
        // Image invalide : on retombe sur l'avatar par défaut.
      }
    }
    return NetworkImage(photoUrl);
  }

  Future<void> _changePhoto(UserProfile profile) async {
    try {
      final picked = await ref
          .read(storageServiceProvider)
          .pickImage(ImageSource.gallery);
      if (picked == null || !mounted) {
        return;
      }
      final url = await ref
          .read(storageServiceProvider)
          .uploadImage(
            file: picked,
            folder: 'profile_images',
            fileName: profile.id,
          );
      // Point 5/6 : chaque sauvegarde écrit réellement dans Firestore.
      await ref
          .read(firestoreServiceProvider)
          .saveUserProfile(profile.copyWith(photoUrl: url));
      _showMessage('Photo de profil mise à jour avec succès.');
    } on Object catch (error) {
      _showMessage('Envoi de la photo impossible. Réessayez. ($error)');
    }
  }

  void _showEditProfileSheet(BuildContext context, UserProfile profile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        key: const Key('edit_profile_sheet'),
        child: _EditProfileForm(profile: profile),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    // Point A4 : message Material themé, placé au-dessus de la navigation.
    AppSnackBar.show(context, message);
  }

  @override
  Widget build(BuildContext context) {
    // Point A/C : seul l'uid est nécessaire ; cela rend l'écran testable sans
    // construire un objet Firebase `User`.
    final uid = ref.watch(currentUidProvider);
    if (uid == null) {
      // Point 9 : titre présent même hors ligne pour rester cohérent.
      return Scaffold(
        appBar: AppBar(title: const Text('Mon profil')),
        backgroundColor: AppColors.cream,
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.go('/auth'),
            child: const Text('Se connecter'),
          ),
        ),
      );
    }

    final profileAsync = ref.watch(userProfileProvider(uid));
    final favoriteIdsAsync = ref.watch(favoriteIdsProvider(uid));
    final userRecipesAsync = ref.watch(userRecipesProvider(uid));

    final favoritesCount = favoriteIdsAsync.value?.length ?? 0;
    final recipesCount = userRecipesAsync.value?.length ?? 0;

    return Scaffold(
      // Point C : en-tête commun sur l'onglet Profil ; l'icône profil est
      // masquée puisqu'on est déjà sur cette page.
      appBar: const RecipeMateAppBar(showProfile: false),
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) =>
              const Center(child: Text('Impossible de charger le profil.')),
          data: (profile) {
            if (profile == null) {
              return const Center(
                child: Text('Profil introuvable. Reconnectez-vous.'),
              );
            }
            return _ProfileContent(
              profile: profile,
              favoritesCount: favoritesCount,
              recipesCount: recipesCount,
              imageProvider: _getProfileImageProvider(profile.photoUrl),
              onEdit: () => _showEditProfileSheet(context, profile),
              onPhoto: () => _changePhoto(profile),
              // Point B : ces pages sont secondaires, on les empile avec push
              // pour que la flèche retour ramène toujours au Profil.
              onSettings: () => context.push('/settings'),
              onReminders: () => context.push('/reminders'),
              // Point B1/B2 : Points d'entrée vers la bibliothèque (les routes
              // existaient déjà mais aucun bouton ne permettait d'y accéder).
              onFavorites: () => context.push('/favorites'),
              onCollections: () => context.push('/collections'),
              onAddRecipe: () => context.push('/add-recipe'),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.favoritesCount,
    required this.recipesCount,
    required this.imageProvider,
    required this.onEdit,
    required this.onPhoto,
    required this.onSettings,
    required this.onReminders,
    required this.onFavorites,
    required this.onCollections,
    required this.onAddRecipe,
  });

  final UserProfile profile;
  final int favoritesCount;
  final int recipesCount;
  final ImageProvider? imageProvider;
  final VoidCallback onEdit;
  final VoidCallback onPhoto;
  final VoidCallback onSettings;
  final VoidCallback onReminders;
  final VoidCallback onFavorites;
  final VoidCallback onCollections;
  final VoidCallback onAddRecipe;

  @override
  Widget build(BuildContext context) {
    final displayName = _valueOrPlaceholder(profile.name);
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Point C : l'ancien bandeau RecipeMate + réglages est retiré du
          // corps de la page : il est désormais fourni par RecipeMateAppBar
          // dans le Scaffold, sans duplication.

          // Carte de profil.
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: <Widget>[
                Stack(
                  alignment: Alignment.bottomRight,
                  children: <Widget>[
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.softGreen,
                      backgroundImage: imageProvider,
                      child: imageProvider == null
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: AppColors.primary,
                            )
                          : null,
                    ),
                    GestureDetector(
                      onTap: onPhoto,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(displayName, style: AppTextStyles.title),
                const SizedBox(height: 4),
                Text(
                  _valueOrPlaceholder(profile.email),
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 12),
                // Point 5 : bio vide → message explicite, jamais d'exemple.
                Text(
                  _valueOrPlaceholder(profile.bio),
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Modifier le profil'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Statistiques réelles (plus de valeurs inventées).
          Row(
            children: <Widget>[
              Expanded(
                child: _StatCard(
                  icon: Icons.restaurant_menu_rounded,
                  iconColor: AppColors.primary,
                  value: '$recipesCount',
                  label: 'Recettes',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.favorite_rounded,
                  iconColor: AppColors.error,
                  value: '$favoritesCount',
                  label: 'Favoris',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Informations personnelles.
          _InfoCard(
            title: 'Informations personnelles',
            rows: <MapEntry<String, String>>[
              MapEntry('Âge', _ageLabel(profile.age)),
              MapEntry('Poids', _weightLabel(profile.weight)),
              MapEntry('Taille', _heightLabel(profile.height)),
              MapEntry('Objectif', _valueOrPlaceholder(profile.goal)),
            ],
          ),
          const SizedBox(height: 16),

          // Régime alimentaire.
          _InfoCard(
            title: 'Régime alimentaire',
            rows: <MapEntry<String, String>>[
              MapEntry('Régimes', _listLabel(profile.diets)),
              MapEntry('Allergies', _listLabel(profile.allergies)),
              MapEntry(
                'Ingrédients exclus',
                _listLabel(profile.excludedIngredients),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Objectifs nutritionnels (point 5 : Non renseigné si absents).
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Objectifs nutritionnels', style: AppTextStyles.subtitle),
                const SizedBox(height: 12),
                _MacroRow(
                  label: 'Calories',
                  value: profile.calorieGoal == null
                      ? 'Non renseigné'
                      : '${profile.calorieGoal} kcal / jour',
                ),
                _MacroRow(
                  label: 'Protéines',
                  value: _gramLabel(profile.proteinGoal),
                ),
                _MacroRow(
                  label: 'Glucides',
                  value: _gramLabel(profile.carbsGoal),
                ),
                _MacroRow(label: 'Lipides', value: _gramLabel(profile.fatGoal)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Points B1/B2 : ces écrans existaient déjà dans le routeur mais
          // aucun bouton ne permettait d'y accéder. On regroupe les trois
          // entrées dans une carte claire, cohérente avec le reste du profil.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Ma bibliothèque',
                style: AppTextStyles.subtitle.copyWith(color: colors.onSurface),
              ),
              const SizedBox(height: 10),
              Card(
                color: colors.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _SettingTile(
                      icon: Icons.favorite_border_rounded,
                      title: 'Mes favoris',
                      subtitle: 'Recettes enregistrées',
                      onTap: onFavorites,
                      showDivider: true,
                    ),
                    _SettingTile(
                      icon: Icons.folder_outlined,
                      title: 'Mes collections',
                      subtitle: 'Dossiers personnalisés',
                      onTap: onCollections,
                      showDivider: true,
                    ),
                    _SettingTile(
                      icon: Icons.add_circle_outline_rounded,
                      title: 'Ajouter une recette',
                      subtitle: 'Créer une recette personnelle',
                      onTap: onAddRecipe,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Point A6 : une seule carte claire, deux lignes et un séparateur
          // fin, au lieu de deux blocs noirs espacés.
          Card(
            color: colors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _SettingTile(
                  icon: Icons.settings_outlined,
                  title: 'Paramètres',
                  subtitle: 'Apparence, sécurité et compte',
                  onTap: onSettings,
                  showDivider: true,
                ),
                _SettingTile(
                  icon: Icons.alarm_outlined,
                  title: 'Mes rappels',
                  subtitle: 'Rappels de repas et péremptions',
                  onTap: onReminders,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _valueOrPlaceholder(String? value) =>
    value == null || value.trim().isEmpty ? 'Non renseigné' : value;

String _ageLabel(int? value) => value == null ? 'Non renseigné' : '$value ans';

String _weightLabel(double? value) =>
    value == null ? 'Non renseigné' : '$value kg';

String _heightLabel(double? value) =>
    value == null ? 'Non renseigné' : '$value cm';

String _gramLabel(double? value) =>
    value == null ? 'Non renseigné' : '${value.toInt()} g';

String _listLabel(List<String> values) =>
    values.isEmpty ? 'Non renseigné' : values.join(', ');

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.title),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: AppTextStyles.captionMedium),
          Text(value, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.rows});

  final String title;
  final List<MapEntry<String, String>> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: AppTextStyles.subtitle),
          const SizedBox(height: 12),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(row.key, style: AppTextStyles.captionMedium),
                  Flexible(
                    child: Text(
                      row.value,
                      style: AppTextStyles.caption,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Point A6 : ligne claire avec icône colorée, titre, sous-titre et chevron.
///
/// Deux instances sont regroupées dans une même [Card] : un fin séparateur
/// entre elles remplace les anciens blocs noirs espacés. Le `Material`/
/// `InkWell` conserve l'effet ripple Material 3 au toucher.
class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: colors.onPrimaryContainer),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: AppTextStyles.subtitle.copyWith(
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: AppTextStyles.caption.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.78),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colors.onSurface.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 74,
            endIndent: 16,
            color: colors.outlineVariant,
          ),
      ],
    );
  }
}

/// Point 6 : formulaire clair, sections et unités, validation numérique.
class _EditProfileForm extends ConsumerStatefulWidget {
  const _EditProfileForm({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<_EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _ageController;
  late final TextEditingController _weightController;
  late final TextEditingController _heightController;
  late final TextEditingController _goalController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _nameController = TextEditingController(text: profile.name);
    _bioController = TextEditingController(text: profile.bio);
    _ageController = TextEditingController(text: profile.age?.toString() ?? '');
    _weightController = TextEditingController(
      text: profile.weight?.toString() ?? '',
    );
    _heightController = TextEditingController(
      text: profile.height?.toString() ?? '',
    );
    _goalController = TextEditingController(text: profile.goal ?? '');
    _caloriesController = TextEditingController(
      text: profile.calorieGoal?.toString() ?? '',
    );
    _proteinController = TextEditingController(
      text: profile.proteinGoal?.toString() ?? '',
    );
    _carbsController = TextEditingController(
      text: profile.carbsGoal?.toString() ?? '',
    );
    _fatController = TextEditingController(
      text: profile.fatGoal?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _goalController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  double? _parsePositive(String text) {
    final value = double.tryParse(text.trim().replaceAll(',', '.'));
    return value != null && value > 0 ? value : null;
  }

  String? _validatePositive(String? text, String label) {
    if (text == null || text.trim().isEmpty) {
      return null; // Champ facultatif : reste « Non renseigné ».
    }
    return _parsePositive(text) == null
        ? '$label doit être un nombre positif.'
        : null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      final updated = widget.profile.copyWith(
        name: _nameController.text.trim(),
        displayName: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
        weight: _parsePositive(_weightController.text),
        height: _parsePositive(_heightController.text),
        goal: _goalController.text.trim().isEmpty
            ? null
            : _goalController.text.trim(),
        calorieGoal: _parsePositive(_caloriesController.text)?.toInt(),
        proteinGoal: _parsePositive(_proteinController.text),
        carbsGoal: _parsePositive(_carbsController.text),
        fatGoal: _parsePositive(_fatController.text),
      );
      // Point 5 : écriture réelle dans Firestore, pas seulement en local.
      await ref.read(firestoreServiceProvider).saveUserProfile(updated);
      if (mounted) {
        Navigator.of(context).pop();
        AppSnackBar.show(context, 'Profil mis à jour avec succès.');
      }
    } on Object catch (error, stackTrace) {
      debugPrint('[Profil] mise à jour impossible : $error\n$stackTrace');
      if (mounted) {
        AppSnackBar.show(context, 'Erreur lors de la mise à jour. Réessayez.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Modifier le profil', style: AppTextStyles.titleLarge),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Informations personnelles', style: AppTextStyles.subtitle),
            const SizedBox(height: 8),
            AppTextField(
              controller: _nameController,
              labelText: 'Nom complet',
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Le nom est obligatoire.'
                  : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _bioController,
              labelText: 'Bio / Description',
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _ageController,
              labelText: 'Âge (années)',
              keyboardType: TextInputType.number,
              validator: (value) => _validatePositive(value, 'L’âge'),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _weightController,
              labelText: 'Poids (kg)',
              keyboardType: TextInputType.number,
              validator: (value) => _validatePositive(value, 'Le poids'),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _heightController,
              labelText: 'Taille (cm)',
              keyboardType: TextInputType.number,
              validator: (value) => _validatePositive(value, 'La taille'),
            ),
            const SizedBox(height: 20),
            Text('Régime alimentaire', style: AppTextStyles.subtitle),
            const SizedBox(height: 8),
            AppTextField(
              controller: _goalController,
              labelText: 'Objectif alimentaire',
              hintText: 'Ex. Perte de poids',
            ),
            const SizedBox(height: 20),
            Text('Objectifs nutritionnels', style: AppTextStyles.subtitle),
            const SizedBox(height: 8),
            AppTextField(
              controller: _caloriesController,
              labelText: 'Calories (kcal / jour)',
              keyboardType: TextInputType.number,
              validator: (value) => _validatePositive(value, 'Les calories'),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _proteinController,
              labelText: 'Protéines (g)',
              keyboardType: TextInputType.number,
              validator: (value) => _validatePositive(value, 'Les protéines'),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _carbsController,
              labelText: 'Glucides (g)',
              keyboardType: TextInputType.number,
              validator: (value) => _validatePositive(value, 'Les glucides'),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _fatController,
              labelText: 'Lipides (g)',
              keyboardType: TextInputType.number,
              validator: (value) => _validatePositive(value, 'Les lipides'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _isSaving
                    ? 'Enregistrement...'
                    : 'Enregistrer les modifications',
                style: AppTextStyles.button.copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
