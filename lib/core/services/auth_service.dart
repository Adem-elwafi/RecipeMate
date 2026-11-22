import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:recipemate/core/config/google_sign_in_config.dart';
import 'package:recipemate/core/services/preferences_service.dart';

/// Toutes les opérations Firebase Authentication sont regroupées ici.
///
/// Les widgets n'appellent jamais FirebaseAuth directement : ils passent par
/// ce service via un provider Riverpod, ce qui garde les écrans testables.
class AuthService {
  AuthService({this._auth, this._googleSignIn});

  final FirebaseAuth? _auth;
  final GoogleSignIn? _googleSignIn;

  /// google_sign_in 7 exige un `initialize()` unique et terminé avant tout
  /// `authenticate()` / `signOut()`. On mémorise le futur pour garantir cela.
  static Future<void>? _googleInitialization;

  FirebaseAuth get _firebaseAuth => _auth ?? FirebaseAuth.instance;
  GoogleSignIn get _google => _googleSignIn ?? GoogleSignIn.instance;

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  /// Point 10 : mémorise l'indicateur local après une connexion réussie.
  Future<void> _rememberSession(User? user) async {
    if (user != null) {
      await PreferencesService.setLoggedIn(user.uid);
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await _rememberSession(credential.user);
    return credential;
  }

  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(name);
    await credential.user?.reload();
    await _rememberSession(credential.user);
    return credential;
  }

  /// Point 3 : envoie réellement l'e-mail de réinitialisation via Firebase.
  ///
  /// Firebase ne renvoie jamais le mot de passe (il est haché) : il envoie un
  /// lien permettant d'en choisir un nouveau. Le template doit être activé
  /// dans la console Firebase > Authentication > Templates.
  Future<void> sendPasswordResetEmail(String email) {
    return _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  Future<UserCredential?> signInWithGoogle() async {
    // Sur Chrome/Web, google_sign_in 7.x ne permet pas de connexion
    // interactive : FirebaseAuth ouvre lui-même la fenêtre Google.
    if (kIsWeb) {
      try {
        final credential = await _firebaseAuth.signInWithPopup(
          GoogleAuthProvider(),
        );
        await _rememberSession(credential.user);
        return credential;
      } on FirebaseAuthException catch (error, stackTrace) {
        debugPrint('[Google/Web] ${error.code} : $error\n$stackTrace');
        if (_isPopupCanceled(error.code)) {
          return null;
        }
        rethrow;
      }
    }

    try {
      await _initializeGoogleIfNeeded();
      final account = await _google.authenticate();
      final googleAuth = account.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final result = await _firebaseAuth.signInWithCredential(credential);
      await _rememberSession(result.user);
      return result;
    } on GoogleSignInException catch (error, stackTrace) {
      // Point A2 : trace complète pour comprendre l'échec sur le téléphone
      // (client ID absent, SHA-1/SHA-256 non enregistré, provider désactivé).
      debugPrint('[Google/Firebase] ${error.code} : $error\n$stackTrace');
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    } on Object catch (error, stackTrace) {
      debugPrint('[Google/Firebase] erreur inattendue : $error\n$stackTrace');
      rethrow;
    }
  }

  /// Initialise le singleton Google une seule fois avec les client IDs
  /// injectés, ou avec la configuration native si aucun n'est fourni.
  Future<void> _initializeGoogleIfNeeded() async {
    // Un faux GoogleSignIn injecté dans les tests n'a pas besoin du singleton.
    if (_googleSignIn != null) {
      return;
    }
    final pending = _googleInitialization;
    if (pending != null) {
      return pending;
    }

    GoogleSignInConfig.logConfiguration();
    final parameters = GoogleSignInConfig.initializeParameters;
    final future = GoogleSignIn.instance.initialize(
      clientId: parameters.clientId,
      serverClientId: parameters.serverClientId,
    );
    _googleInitialization = future;
    try {
      await future;
    } on Object {
      _googleInitialization = null;
      rethrow;
    }
  }

  /// Codes Firebase quand l'utilisateur ferme ou annule la fenêtre.
  static bool _isPopupCanceled(String code) {
    return code == 'popup-closed-by-user' ||
        code == 'canceled-popup' ||
        code == 'auth/popup-closed-by-user' ||
        code == 'auth/cancelled-popup-request';
  }

  Future<void> deleteAccount() async {
    await _firebaseAuth.currentUser?.delete();
    // Point 10 : suppression de l'indicateur local après la suppression.
    await PreferencesService.clearLoggedIn();
  }

  Future<void> signOut() async {
    // GoogleSignIn n'est initialisé que sur les plateformes natives, et
    // seulement après une tentative de connexion Google : l'appeler avant
    // `initialize()` provoquait une erreur sur les comptes e-mail/mot de passe.
    if (!kIsWeb && (_googleSignIn != null || _googleInitialization != null)) {
      try {
        await _google.signOut();
      } on Object catch (error, stackTrace) {
        debugPrint('[Google] déconnexion ignorée : $error\n$stackTrace');
      }
    }
    await _firebaseAuth.signOut();
    // Point 10 : suppression de l'indicateur local à la déconnexion.
    await PreferencesService.clearLoggedIn();
  }
}
