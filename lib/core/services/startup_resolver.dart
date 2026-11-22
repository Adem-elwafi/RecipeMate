import 'package:firebase_auth/firebase_auth.dart';
import 'package:recipemate/core/services/auth_service.dart';
import 'package:recipemate/core/services/firebase_service.dart';
import 'package:recipemate/core/services/preferences_service.dart';

/// Destination de l'application après l'animation du splash.
enum SplashDestination { onboarding, auth, home }

/// Logique de décision hors du widget, pour rester testable (point 1 et 10).
abstract final class StartupResolver {
  static Future<SplashDestination> resolve() async {
    final onboardingDone = await PreferencesService.isOnboardingCompleted();
    if (!onboardingDone) {
      return SplashDestination.onboarding;
    }

    if (!FirebaseService.isAvailable) {
      return SplashDestination.auth;
    }

    // Point 10 : le flag local SharedPreferences est un indice de confort,
    // jamais une preuve d'authentification. On vérifie TOUJOURS la session
    // Firebase réelle avant d'ouvrir l'accueil.
    final localUid = await PreferencesService.getLoggedInUid();
    final user = await _currentFirebaseUser();
    if (user == null) {
      // Session Firebase expirée : le flag local est obsolète, on le nettoie.
      if (localUid != null) {
        await PreferencesService.clearLoggedIn();
      }
      return SplashDestination.auth;
    }

    return SplashDestination.home;
  }

  /// Sur Web, Firebase restaure la session de façon asynchrone :
  /// `currentUser` peut encore être null pendant l'initialisation.
  static Future<User?> _currentFirebaseUser() async {
    try {
      final auth = AuthService();
      return auth.currentUser ??
          await auth.authStateChanges().first.timeout(
            const Duration(seconds: 3),
            onTimeout: () => null,
          );
    } on Object {
      return null;
    }
  }
}
