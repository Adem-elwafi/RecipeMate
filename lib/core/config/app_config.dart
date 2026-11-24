/// Point 1 : configuration globale de l'application.
///
/// Les valeurs d'interface configurables sont regroupées ici pour éviter les
/// durées « magiques » dispersées dans les widgets.
abstract final class AppConfig {
  /// Durée d'affichage du splash Flutter (fixée à 6 secondes).
  static const Duration splashDurationSeconds = Duration(seconds: 6);

  /// Nombre de jours avant la péremption d'un produit où une notification
  /// doit être planifiée (point 4a). Valeur modifiable depuis les préférences.
  static const int expiryReminderLeadDays = 3;
}
