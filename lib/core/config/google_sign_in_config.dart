import 'package:flutter/foundation.dart';

/// Point A2 : configuration Google Sign-In injectée au lancement.
///
/// Aucun client ID n'est codé en dur. En l'absence de `--dart-define`, le
/// plugin lit la configuration native (`google-services.json` sur Android et
/// `GoogleService-Info.plist` sur iOS). Les valeurs transmises ici prennent le
/// pas sur ces fichiers, ce qui permet de corriger rapidement un fingerprint
/// oublié sans republier le fichier natif.
abstract final class GoogleSignInConfig {
  /// Client Web de type « xxx.apps.googleusercontent.com » (Android + Web).
  static const String webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  /// Client iOS ("xxx.apps.googleusercontent.com").
  static const String iosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );

  static bool get hasWebClientId => webClientId.trim().isNotEmpty;

  static bool get hasIosClientId => iosClientId.trim().isNotEmpty;

  /// Paramètres attendus par `GoogleSignIn.initialize()`.
  static ({String? clientId, String? serverClientId}) get initializeParameters {
    if (kIsWeb) {
      return (clientId: null, serverClientId: null);
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return (
        clientId: hasIosClientId ? iosClientId.trim() : null,
        serverClientId: null,
      );
    }
    return (
      clientId: null,
      serverClientId: hasWebClientId ? webClientId.trim() : null,
    );
  }

  /// Trace utile quand le téléphone renvoie une erreur de configuration.
  static void logConfiguration() {
    final parameters = initializeParameters;
    debugPrint(
      '[Google] clientId=${parameters.clientId ?? "(natif)"} '
      'serverClientId=${parameters.serverClientId ?? "(natif)"}',
    );

    // Point A2 : sur Android, google_sign_in 7 a besoin d'un client OAuth de
    // type Web (serverClientId). Si le `google-services.json` téléchargé a une
    // liste `oauth_client` vide, la connexion échoue avec
    // `clientConfigurationError` (ex-ApiException code 10). On le signale
    // clairement dans la console au lieu de laisser une erreur générique.
    if (defaultTargetPlatform == TargetPlatform.android && !hasWebClientId) {
      debugPrint(
        '[Google] Attention : aucun GOOGLE_WEB_CLIENT_ID fourni. Si '
        'android/app/google-services.json contient "oauth_client": [], '
        'téléchargez-le à nouveau depuis Firebase Console après avoir '
        'enregistré les empreintes SHA-1/SHA-256, ou lancez avec '
        '--dart-define=GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com',
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS && !hasIosClientId) {
      debugPrint(
        '[Google] Attention : aucun GOOGLE_IOS_CLIENT_ID fourni. Vérifiez '
        'ios/Runner/GoogleService-Info.plist (à régénérer avec '
        '`flutterfire configure`).',
      );
    }
  }
}
