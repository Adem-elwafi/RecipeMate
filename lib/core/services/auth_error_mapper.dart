import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Convertit les codes d'erreur techniques Firebase en messages français.
/// Classe hors des widgets pour être testable unitairement (point 9).
abstract final class AuthErrorMapper {
  static String message(Object error) {
    // Point A2 : on garde la trace technique même quand l'utilisateur ne voit
    // qu'un message court (les logs sont consultables dans Android Studio).
    debugPrint('[Auth] ${error.runtimeType} : $error');

    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'invalid-email' => 'Cette adresse e-mail est invalide.',
        'user-disabled' => 'Ce compte a été désactivé.',
        'user-not-found' =>
          'Aucun compte ne correspond à cette adresse e-mail.',
        'wrong-password' => 'Mot de passe incorrect.',
        'invalid-credential' => 'E-mail ou mot de passe incorrect.',
        'email-already-in-use' => 'Cette adresse e-mail est déjà utilisée.',
        'requires-recent-login' =>
          'Pour cette action, reconnectez-vous puis réessayez.',
        'weak-password' =>
          'Le mot de passe est trop faible (6 caractères minimum).',
        'too-many-requests' =>
          'Trop de tentatives. Réessayez dans quelques minutes.',
        'network-request-failed' =>
          'Pas de connexion Internet. Vérifiez votre réseau.',
        'operation-not-allowed' =>
          'Cette méthode de connexion n’est pas activée dans Firebase.',
        'popup-closed-by-user' => 'La fenêtre de connexion a été fermée.',
        'popup-blocked' => 'La fenêtre Google a été bloquée. Autorisez les fenêtres surgissantes.',
        'auth/popup-blocked' => 'La fenêtre Google a été bloquée. Autorisez les fenêtres surgissantes.',
        'auth/cancelled-popup-request' => 'Connexion Google annulée.',
        'auth/unauthorized-domain' =>
          'Ce domaine n’est pas autorisé dans la configuration Firebase.',
        'account-exists-with-different-credential' =>
          'Un compte existe déjà avec cette adresse e-mail.',
        'auth/account-exists-with-different-credential' =>
          'Un compte existe déjà avec cette adresse e-mail.',
        // Point 3 : erreurs spécifiques à la réinitialisation du mot de passe.
        'missing-email' => 'Veuillez saisir votre adresse e-mail.',
        'invalid-recipient-email' => 'Cette adresse e-mail est invalide.',
        'expired-action-code' =>
          'Ce lien de réinitialisation a expiré. Demandez-en un nouveau.',
        'invalid-action-code' =>
          'Ce lien de réinitialisation est invalide. Demandez-en un nouveau.',
        _ => 'Une erreur est survenue (${error.code}). Réessayez.',
      };
    }
    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' =>
          'Accès refusé par les règles de sécurité Firestore.',
        'not-found' => 'Base de données Firestore introuvable. Veuillez l’activer dans la console Firebase.',
        'unavailable' =>
          'Service momentanément indisponible. Réessayez dans un instant.',
        _ =>
          'Erreur base de données (${error.code}) : ${error.message ?? 'Réessayez.'}',
      };
    }
    if (error is GoogleSignInException) {
      final description = error.description?.toLowerCase() ?? '';
      if (description.contains('network') ||
          description.contains('internet') ||
          description.contains('timeout')) {
        return 'Pas de connexion Internet. Vérifiez votre réseau.';
      }
      if (description.contains('no account') ||
          description.contains('aucun compte')) {
        return 'Aucun compte Google n’est disponible sur cet appareil.';
      }
      return switch (error.code) {
        GoogleSignInExceptionCode.canceled => 'Connexion Google annulée.',
        GoogleSignInExceptionCode.interrupted =>
          'Connexion Google interrompue.',
        GoogleSignInExceptionCode.uiUnavailable =>
          'La connexion Google n’est pas disponible sur cet appareil.',
        GoogleSignInExceptionCode.clientConfigurationError =>
          'Configuration Google incomplète : vérifiez le client ID et les '
              'empreintes SHA-1/SHA-256 dans Firebase.',
        GoogleSignInExceptionCode.providerConfigurationError =>
          'Le fournisseur Google n’est pas activé dans Firebase '
              'Authentication.',
        GoogleSignInExceptionCode.userMismatch =>
          'Le compte Google ne correspond pas au compte connecté.',
        _ => 'Impossible de se connecter avec Google. Réessayez.',
      };
    }
    return 'Une erreur inattendue est survenue. Réessayez.';
  }
}
