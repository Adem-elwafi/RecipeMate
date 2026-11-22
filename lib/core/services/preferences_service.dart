import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Préférences locales uniquement.
///
/// Jamais de mot de passe ici : ce stockage clé/valeur sert uniquement aux
/// préférences d'interface et à l'indicateur de connexion local (point 10).
abstract final class PreferencesService {
  static const String _onboardingKey = 'onboarding_completed';
  static const String _themeModeKey = 'theme_mode';
  // Point 10 : indicateur local de connexion, jamais utilisé comme seule
  // preuve d'authentification (FirebaseAuth reste la source de vérité).
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _uidKey = 'uid';

  static SharedPreferences? _cached;

  static Future<SharedPreferences> get _prefs async {
    _cached ??= await SharedPreferences.getInstance();
    return _cached!;
  }

  static Future<bool> isOnboardingCompleted() async {
    final prefs = await _prefs;
    return prefs.getBool(_onboardingKey) ?? false;
  }

  static Future<void> setOnboardingCompleted() async {
    final prefs = await _prefs;
    await prefs.setBool(_onboardingKey, true);
  }

  static Future<ThemeMode> getThemeMode() async {
    final prefs = await _prefs;
    return switch (prefs.getString(_themeModeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await _prefs;
    await prefs.setString(_themeModeKey, mode.name);
  }

  /// Point 10 : enregistre l'indicateur local après une connexion réussie.
  static Future<void> setLoggedIn(String uid) async {
    final prefs = await _prefs;
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_uidKey, uid);
  }

  /// Point 10 : retourne l'UID mémorisé localement, ou null si absent.
  static Future<String?> getLoggedInUid() async {
    final prefs = await _prefs;
    if (prefs.getBool(_isLoggedInKey) != true) {
      return null;
    }
    return prefs.getString(_uidKey);
  }

  /// Point 10 : supprime l'indicateur local à la déconnexion.
  static Future<void> clearLoggedIn() async {
    final prefs = await _prefs;
    await prefs.setBool(_isLoggedInKey, false);
    await prefs.remove(_uidKey);
  }

  /// Utilisé par l'action « réinitialiser les données de démonstration ».
  static Future<void> resetOnboarding() async {
    final prefs = await _prefs;
    await prefs.remove(_onboardingKey);
  }
}
