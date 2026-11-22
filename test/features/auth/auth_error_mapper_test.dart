import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipemate/core/services/auth_error_mapper.dart';

void main() {
  test('convertit les codes Firebase en messages français', () {
    expect(
      AuthErrorMapper.message(FirebaseAuthException(code: 'wrong-password')),
      'Mot de passe incorrect.',
    );
    expect(
      AuthErrorMapper.message(
        FirebaseAuthException(code: 'email-already-in-use'),
      ),
      'Cette adresse e-mail est déjà utilisée.',
    );
    expect(
      AuthErrorMapper.message(FirebaseAuthException(code: 'user-not-found')),
      contains('Aucun compte'),
    );
  });

  test('gère une erreur inconnue', () {
    expect(
      AuthErrorMapper.message(StateError('erreur')),
      contains('inattendue'),
    );
  });
}
