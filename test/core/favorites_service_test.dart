import 'package:flutter_test/flutter_test.dart';
import 'package:recipemate/core/services/favorites_service.dart';
import 'package:recipemate/core/services/firestore_service.dart';

void main() {
  test('toggleFavorite refuse d’agir sans utilisateur connecté', () async {
    final service = FavoritesService(
      firestore: FirestoreService(),
      currentUid: () => null,
    );

    expect(service.toggleFavorite('rec_1'), throwsA(isA<StateError>()));
  });

  test('addFavorite refuse d’agir sans utilisateur connecté', () async {
    final service = FavoritesService(
      firestore: FirestoreService(),
      currentUid: () => null,
    );

    expect(service.addFavorite('rec_1'), throwsA(isA<StateError>()));
  });
}
