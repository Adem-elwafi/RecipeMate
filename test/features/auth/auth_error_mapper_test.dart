import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  test('distingue les erreurs de configuration Google', () {
    expect(
      AuthErrorMapper.message(
        const GoogleSignInException(
          code: GoogleSignInExceptionCode.clientConfigurationError,
        ),
      ),
      contains('SHA-1/SHA-256'),
    );
    expect(
      AuthErrorMapper.message(
        const GoogleSignInException(
          code: GoogleSignInExceptionCode.providerConfigurationError,
        ),
      ),
      contains('fournisseur Google'),
    );
    expect(
      AuthErrorMapper.message(
        const GoogleSignInException(
          code: GoogleSignInExceptionCode.unknownError,
          description: 'network error',
        ),
      ),
      contains('connexion Internet'),
    );
  });
}
