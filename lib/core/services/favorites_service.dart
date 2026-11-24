import 'package:recipemate/core/services/firestore_service.dart';

/// Point B1 : API de favoris partagée avec le reste de l'équipe.
///
/// Molka peut appeler
/// `ref.read(favoritesServiceProvider).toggleFavorite(recipeId)` depuis
/// l'accueil ou le détail d'une recette : il n'existe qu'une seule
/// implémentation, stockée par utilisateur dans Firestore.
class FavoritesService {
  FavoritesService({required this.firestore, required this.currentUid});

  final FirestoreService firestore;
  final String? Function() currentUid;

  /// Bascule le favori sans rechargement : le stream `favoriteIdsProvider`
  /// reconstruit automatiquement les écrans après l'écriture Firestore.
  Future<void> toggleFavorite(String recipeId) async {
    final uid = _requireUid();
    await firestore.toggleFavorite(uid, recipeId);
  }

  Future<void> addFavorite(String recipeId) async {
    final uid = _requireUid();
    await firestore.setFavorite(uid, recipeId, true);
  }

  Future<void> removeFavorite(String recipeId) async {
    final uid = _requireUid();
    await firestore.setFavorite(uid, recipeId, false);
  }

  Future<bool> isFavorite(String recipeId) async {
    final uid = _requireUid();
    return firestore.isFavorite(uid, recipeId);
  }

  String _requireUid() {
    final uid = currentUid();
    if (uid == null) {
      throw StateError('Connectez-vous pour utiliser les favoris.');
    }
    return uid;
  }
}
