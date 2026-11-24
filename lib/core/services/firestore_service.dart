import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipemate/core/models/ingredient.dart';
import 'package:recipemate/core/models/recipe.dart';
import 'package:recipemate/core/models/recipe_collection.dart';
import 'package:recipemate/core/models/reminder.dart';
import 'package:recipemate/core/models/user_profile.dart';
import 'package:recipemate/core/utils/allergy_labels.dart';
import 'package:recipemate/core/utils/recipe_keywords.dart';

/// Cloud Firestore reads and writes for Farah's features.
///
/// Firestore structure (shared with the team):
/// - `users/{uid}`                         -> UserProfile fields
/// - `users/{uid}/favorites/{recipeId}`    -> favorite flag
/// - `users/{uid}/collections/{id}`        -> RecipeCollection
/// - `users/{uid}/reminders/{id}`          -> rappels et historique
/// - `users/{uid}/pantry/{id}`             -> produits suivis (péremption)
/// - `recipes/{recipeId}`                  -> Recipe (shared model)
class FirestoreService {
  FirestoreService({this._firestore});

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _favorites(String uid) =>
      _userDoc(uid).collection('favorites');

  CollectionReference<Map<String, dynamic>> _collections(String uid) =>
      _userDoc(uid).collection('collections');

  CollectionReference<Map<String, dynamic>> _reminders(String uid) =>
      _userDoc(uid).collection('reminders');

  // --------------------------------------------------------------- Reminders

  /// Point 4 : écoute tous les rappels d'un utilisateur (à venir et passés).
  Stream<List<Reminder>> watchReminders(String uid) {
    return _reminders(uid)
        .orderBy('scheduledAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Reminder.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Point 4/7 : crée un rappel dans users/{uid}/reminders.
  Future<String> createReminder(String uid, Reminder reminder) async {
    final doc = _reminders(uid).doc();
    final stored = Reminder(
      id: doc.id,
      type: reminder.type,
      title: reminder.title,
      scheduledAt: reminder.scheduledAt,
      relatedId: reminder.relatedId,
      status: reminder.status,
      createdAt: reminder.createdAt,
      triggeredAt: reminder.triggeredAt,
    );
    await doc.set(stored.toMap());
    return doc.id;
  }

  /// Point 4 : met à jour le statut et ajoute triggeredAt quand la
  /// notification part, afin de conserver un historique fiable.
  Future<void> markReminderSent(
    String uid,
    String reminderId, {
    DateTime? triggeredAt,
  }) {
    return _reminders(uid).doc(reminderId).update(<String, Object?>{
      'status': ReminderStatus.sent.name,
      'triggeredAt': (triggeredAt ?? DateTime.now()).toIso8601String(),
    });
  }

  /// Point 7 : annule un rappel futur (il reste visible dans l'historique).
  Future<void> cancelReminder(String uid, String reminderId) {
    return _reminders(uid)
        .doc(reminderId)
        .update(<String, Object?>{'status': ReminderStatus.cancelled.name});
  }

  Future<void> deleteReminder(String uid, String reminderId) =>
      _reminders(uid).doc(reminderId).delete();

  // ---------------------------------------------------------------- Profile

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return _profileFromMap(uid, doc.data()!);
  }

  Stream<UserProfile?> watchUserProfile(String uid) {
    return _userDoc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return _profileFromMap(uid, doc.data()!);
    });
  }

  Future<void> saveUserProfile(UserProfile profile) {
    return _userDoc(profile.id)
        .set(_profileToMap(profile), SetOptions(merge: true));
  }

  /// Point 5 : à l'inscription, écrit un profil totalement vide (seul le nom
  /// est éventuellement pré-rempli) avec createdAt = serverTimestamp().
  Future<void> createEmptyProfile({
    required String uid,
    String? displayName,
    String? email,
    String? photoUrl,
  }) {
    return _userDoc(uid).set(<String, Object?>{
      'displayName': displayName,
      'name': displayName ?? '',
      'email': email ?? '',
      'photoUrl': photoUrl,
      'age': null,
      'weight': null,
      'height': null,
      'goal': null,
      'bio': '',
      'diets': <String>[],
      'allergies': <String>[],
      'excludedIngredients': <String>[],
      'dailyCalories': null,
      'dailyProtein': null,
      'dailyCarbs': null,
      'dailyFat': null,
      'calorieGoal': null,
      'proteinGoal': null,
      'carbsGoal': null,
      'fatGoal': null,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteUserProfile(String uid) => _userDoc(uid).delete();

  /// Firestore does not cascade deletes from the client: each subcollection
  /// document must be deleted explicitly before the user document.
  /// Called by the settings screen after the Firebase Auth account is removed.
  Future<void> deleteUserData(String uid) async {
    final batch = _db.batch();

    final favorites = await _favorites(uid).get();
    for (final doc in favorites.docs) {
      batch.delete(doc.reference);
    }

    final collections = await _collections(uid).get();
    for (final doc in collections.docs) {
      batch.delete(doc.reference);
    }

    final reminders = await _reminders(uid).get();
    for (final doc in reminders.docs) {
      batch.delete(doc.reference);
    }

    final pantry = await _userDoc(uid).collection('pantry').get();
    for (final doc in pantry.docs) {
      batch.delete(doc.reference);
    }

    final ownRecipes = await _db
        .collection('recipes')
        .where('creatorId', isEqualTo: uid)
        .get();
    for (final doc in ownRecipes.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(_userDoc(uid));
    await batch.commit();
  }

  Map<String, Object?> _profileToMap(UserProfile profile) => <String, Object?>{
    'displayName': profile.displayName ?? profile.name,
    'name': profile.name,
    'email': profile.email,
    'photoUrl': profile.photoUrl,
    'age': profile.age,
    'weight': profile.weight,
    'height': profile.height,
    'goal': profile.goal,
    'bio': profile.bio,
    'diets': profile.diets,
    // Point A5 : on répare « Guten » en « Gluten » avant chaque écriture.
    'allergies': AllergyLabels.correctAll(profile.allergies),
    'excludedIngredients': AllergyLabels.correctAll(
      profile.excludedIngredients,
    ),
    // Point 5 : les deux jeux de clés sont écrits pour rester compatibles
    // avec l'ancien code tout en exposant les champs demandés.
    'dailyCalories': profile.calorieGoal,
    'dailyProtein': profile.proteinGoal,
    'dailyCarbs': profile.carbsGoal,
    'dailyFat': profile.fatGoal,
    'calorieGoal': profile.calorieGoal,
    'proteinGoal': profile.proteinGoal,
    'carbsGoal': profile.carbsGoal,
    'fatGoal': profile.fatGoal,
  };

  UserProfile _profileFromMap(String uid, Map<String, dynamic> map) {
    // Point 5 : aucune valeur d'exemple. Les champs absents restent vides.
    final goal = map['calorieGoal'] as num? ?? map['dailyCalories'] as num?;
    final protein = map['proteinGoal'] as num? ?? map['dailyProtein'] as num?;
    final carbs = map['carbsGoal'] as num? ?? map['dailyCarbs'] as num?;
    final fat = map['fatGoal'] as num? ?? map['dailyFat'] as num?;
    final name = map['displayName'] as String? ?? map['name'] as String? ?? '';

    return UserProfile(
      id: uid,
      name: name,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      age: (map['age'] as num?)?.toInt(),
      weight: (map['weight'] as num?)?.toDouble(),
      height: (map['height'] as num?)?.toDouble(),
      goal: map['goal'] as String?,
      bio: map['bio'] as String? ?? '',
      diets: (map['diets'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic value) => value.toString())
          .toList(),
      // Point A5 : correction à la lecture pour les documents déjà enregistrés.
      allergies: AllergyLabels.correctAll(map['allergies'] as List<dynamic>?),
      excludedIngredients: AllergyLabels.correctAll(
        map['excludedIngredients'] as List<dynamic>?,
      ),
      calorieGoal: goal?.toInt(),
      proteinGoal: protein?.toDouble(),
      carbsGoal: carbs?.toDouble(),
      fatGoal: fat?.toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  // --------------------------------------------------------------- Favorites

  Stream<List<String>> watchFavoriteIds(String uid) {
    return _favorites(uid).snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => doc.data()['recipeId'] as String? ?? doc.id)
          .toList(),
    );
  }

  Future<bool> isFavorite(String uid, String recipeId) async {
    final doc = await _favorites(uid).doc(recipeId).get();
    return doc.exists;
  }

  /// Point B1 : bascule atomique du favori.
  ///
  /// Une transaction évite qu'un double tap ajoute puis supprime deux fois le
  /// même document : le stream Firestore met ensuite l'écran à jour sans
  /// rechargement manuel.
  Future<void> toggleFavorite(String uid, String recipeId) {
    return _db.runTransaction<void>((transaction) async {
      final reference = _favorites(uid).doc(recipeId);
      final snapshot = await transaction.get(reference);
      if (snapshot.exists) {
        transaction.delete(reference);
      } else {
        transaction.set(reference, <String, Object?>{
          'recipeId': recipeId,
          // Point B1 : horodatage serveur demandé pour les favoris.
          'addedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> setFavorite(String uid, String recipeId, bool isFavorite) {
    final doc = _favorites(uid).doc(recipeId);
    if (!isFavorite) {
      return doc.delete();
    }
    return doc.set(<String, Object?>{
      'recipeId': recipeId,
      'addedAt': FieldValue.serverTimestamp(),
      // Clé historique conservée pour les anciennes versions de l'application.
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ------------------------------------------------------------- Collections

  Stream<List<RecipeCollection>> watchCollections(String uid) {
    return _collections(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RecipeCollection.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<RecipeCollection> createCollection(String uid, String name) async {
    final doc = await _collections(uid).add(<String, Object?>{
      'name': name.trim(),
      'recipeIds': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return RecipeCollection(
      id: doc.id,
      name: name.trim(),
      recipeIds: const <String>[],
      createdAt: DateTime.now(),
    );
  }

  Future<void> deleteCollection(String uid, String collectionId) =>
      _collections(uid).doc(collectionId).delete();

  Future<void> renameCollection(String uid, String collectionId, String name) =>
      _collections(uid)
          .doc(collectionId)
          .update(<String, Object?>{'name': name.trim()});

  Future<void> updateRecipeIds(
    String uid,
    String collectionId,
    List<String> recipeIds,
  ) =>
      _collections(uid)
          .doc(collectionId)
          .update(<String, Object?>{'recipeIds': recipeIds});

  /// Point B1 : ajoute la même recette à plusieurs collections d'un coup.
  /// `arrayUnion` rend l'opération idempotente (pas de doublon sur un second
  /// tap) et le batch garantit que toutes les collections sont mises à jour.
  Future<void> addRecipeToCollections(
    String uid,
    String recipeId,
    Iterable<String> collectionIds,
  ) async {
    final batch = _db.batch();
    for (final collectionId in collectionIds) {
      batch.update(_collections(uid).doc(collectionId), <String, Object?>{
        'recipeIds': FieldValue.arrayUnion(<String>[recipeId]),
      });
    }
    await batch.commit();
  }

  // ----------------------------------------------------------------- Recipes

  /// Point B2 : enregistre tous les champs demandés dans `recipes/{id}`.
  ///
  /// `authorId` est imposé côté serveur de données avec l'UID connecté, et
  /// `creatorId` est conservé pour rester compatible avec les règles Firestore
  /// et les écrans existants. `createdAt` est un timestamp serveur.
  Future<void> saveRecipe({required String uid, required Recipe recipe}) {
    final stored = recipe.copyWith(authorId: uid);
    return _db.collection('recipes').doc(recipe.id).set(<String, Object?>{
      'creatorId': uid,
      'authorId': uid,
      'isPublic': stored.isPublic,
      'createdAt': FieldValue.serverTimestamp(),
      ..._recipeToMap(stored),
    }, SetOptions(merge: true));
  }

  Stream<List<Recipe>> watchUserRecipes(String uid) {
    return _db
        .collection('recipes')
        .where('creatorId', isEqualTo: uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _recipeFromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Point B1 : les favoris et collections peuvent référencer des recettes
  /// d'autres utilisateurs. On écoute donc tous les documents `recipes/{id}`
  /// pour résoudre ces identifiants sans recharger l'écran.
  Stream<List<Recipe>> watchSharedRecipes() {
    return _db
        .collection('recipes')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _recipeFromMap(doc.id, doc.data()))
              .toList(growable: false),
        );
  }

  Map<String, Object?> _recipeToMap(Recipe recipe) => <String, Object?>{
    'authorId': recipe.authorId,
    'isPublic': recipe.isPublic,
    'title': recipe.title,
    'ingredientKeywords': recipe.ingredientKeywords,
    'description': recipe.description,
    'imageUrl': recipe.imageUrl,
    'prepTimeMinutes': recipe.prepTimeMinutes,
    'cookTimeMinutes': recipe.cookTimeMinutes,
    'calories': recipe.calories,
    'proteinGrams': recipe.proteinGrams,
    'carbsGrams': recipe.carbsGrams,
    'fatGrams': recipe.fatGrams,
    'dietBadges': recipe.dietBadges,
    // Point B2 : champs explicites attendus par le cahier des charges. La
    // catégorie reste aussi dans `dietBadges` pour les anciens écrans qui s'en
    // servent comme badge d'affichage.
    'category': recipe.category,
    'difficulty': recipe.difficulty,
    'dietTags': recipe.dietTags,
    'fiberGrams': recipe.fiberGrams,
    // Point A5 : mêmes corrections que pour le profil.
    'allergens': AllergyLabels.correctAll(recipe.allergens),
    'ingredients': recipe.ingredients
        .map(
          (item) => <String, Object?>{
            'name': item.ingredient.name,
            'category': item.ingredient.category.name,
            'defaultUnit': item.ingredient.defaultUnit,
            'quantity': item.quantity,
            'unit': item.unit,
            'notes': item.notes,
          },
        )
        .toList(),
    'instructions': recipe.instructions,
    'servings': recipe.servings,
    'rating': recipe.rating,
  };

  Recipe _recipeFromMap(String id, Map<String, dynamic> map) {
    final ingredients =
        (map['ingredients'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map<dynamic, dynamic>>()
            .map((dynamic raw) {
              final item = raw as Map<String, dynamic>;
              final categoryName = item['category'] as String? ?? 'other';
              final category = IngredientCategory.values.firstWhere(
                (value) => value.name == categoryName,
                orElse: () => IngredientCategory.other,
              );
              final name = item['name'] as String? ?? '';
              return RecipeIngredient(
                ingredient: Ingredient(
                  id: name,
                  name: name,
                  category: category,
                  defaultUnit: item['defaultUnit'] as String? ?? 'g',
                ),
                quantity: (item['quantity'] as num?)?.toDouble() ?? 0,
                unit: item['unit'] as String? ?? 'g',
                notes: item['notes'] as String?,
              );
            })
            .toList();

    final rawKeywords = map['ingredientKeywords'] as List<dynamic>?;
    final badges = (map['dietBadges'] as List<dynamic>? ?? const <dynamic>[])
        .map((dynamic value) => value.toString())
        .toList();
    // Point B2 : compatibilité avec les documents écrits avant l'ajout des
    // champs explicites (la catégorie était alors le premier badge).
    final category =
        map['category'] as String? ?? (badges.isEmpty ? '' : badges.first);
    final rawDietTags = map['dietTags'] as List<dynamic>?;
    final dietTags = rawDietTags == null || rawDietTags.isEmpty
        ? badges.where((String tag) => tag != category).toList()
        : rawDietTags.map((dynamic value) => value.toString()).toList();
    return Recipe(
      id: id,
      authorId: map['authorId'] as String? ?? map['creatorId'] as String? ?? '',
      isPublic: map['isPublic'] as bool? ?? true,
      // Compatibilité avec les recettes créées avant l'ajout du champ.
      ingredientKeywords: rawKeywords == null || rawKeywords.isEmpty
          ? RecipeKeywords.fromNames(
              ingredients.map((item) => item.ingredient.name),
            )
          : rawKeywords.map((dynamic value) => value.toString()).toList(),
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      imageUrl: map['imageUrl'] as String? ?? '',
      prepTimeMinutes: (map['prepTimeMinutes'] as num?)?.toInt() ?? 0,
      cookTimeMinutes: (map['cookTimeMinutes'] as num?)?.toInt() ?? 0,
      calories: (map['calories'] as num?)?.toInt() ?? 0,
      proteinGrams: (map['proteinGrams'] as num?)?.toDouble() ?? 0,
      carbsGrams: (map['carbsGrams'] as num?)?.toDouble() ?? 0,
      fatGrams: (map['fatGrams'] as num?)?.toDouble() ?? 0,
      dietBadges: badges,
      category: category,
      difficulty: map['difficulty'] as String? ?? 'Facile',
      dietTags: dietTags,
      fiberGrams: (map['fiberGrams'] as num?)?.toDouble() ?? 0,
      allergens: AllergyLabels.correctAll(map['allergens'] as List<dynamic>?),
      ingredients: ingredients,
      instructions: (map['instructions'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic value) => value.toString())
          .toList(),
      servings: (map['servings'] as num?)?.toInt() ?? 2,
      rating: (map['rating'] as num?)?.toDouble() ?? 4.8,
    );
  }
}
