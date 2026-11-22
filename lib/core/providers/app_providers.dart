import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipemate/core/models/recipe.dart';
import 'package:recipemate/core/models/recipe_collection.dart';
import 'package:recipemate/core/models/reminder.dart';
import 'package:recipemate/core/models/user_profile.dart';
import 'package:recipemate/core/services/auth_service.dart';
import 'package:recipemate/core/services/favorites_service.dart';
import 'package:recipemate/core/services/firestore_service.dart';
import 'package:recipemate/core/services/notification_service.dart';
import 'package:recipemate/core/services/storage_service.dart';

/// Service providers. Widgets depend on these, never on Firebase directly.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(),
);

final storageServiceProvider = Provider<StorageService>(
  (ref) => StorageService(),
);

/// Point 4/7 : service de notifications locales.
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

/// Streams are provided by Riverpod so screens rebuild automatically when
/// the authenticated user or a Firestore document changes.
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authServiceProvider).authStateChanges(),
);

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

/// Point A : les écrans n'ont besoin que de l'identifiant, pas de l'objet
/// Firebase `User`. Ce provider facilite aussi les tests de widget sans
/// session Firebase réelle.
final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.uid;
});

final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  return FavoritesService(
    firestore: ref.watch(firestoreServiceProvider),
    currentUid: () => ref.read(currentUserProvider)?.uid,
  );
});

final userProfileProvider = StreamProvider.family<UserProfile?, String>((
  ref,
  uid,
) {
  return ref.watch(firestoreServiceProvider).watchUserProfile(uid);
});

final favoriteIdsProvider = StreamProvider.family<List<String>, String>((
  ref,
  uid,
) {
  return ref.watch(firestoreServiceProvider).watchFavoriteIds(uid);
});

final collectionsProvider =
    StreamProvider.family<List<RecipeCollection>, String>((ref, uid) {
      return ref.watch(firestoreServiceProvider).watchCollections(uid);
    });

final userRecipesProvider = StreamProvider.family<List<Recipe>, String>((
  ref,
  uid,
) {
  return ref.watch(firestoreServiceProvider).watchUserRecipes(uid);
});

/// Point B1 : recettes partagées `recipes/{id}`, utilisées pour résoudre les
/// identifiants présents dans les favoris et les collections.
final sharedRecipesProvider = StreamProvider<List<Recipe>>((ref) {
  return ref.watch(firestoreServiceProvider).watchSharedRecipes();
});

/// Point 4 : rappels à venir et passés, lus depuis Firestore.
final remindersProvider = StreamProvider.family<List<Reminder>, String>((
  ref,
  uid,
) {
  return ref.watch(firestoreServiceProvider).watchReminders(uid);
});
