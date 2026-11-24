import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipemate/core/services/preferences_service.dart';

/// Theme mode is global domain state, so it lives in Riverpod rather than in
/// a single widget's setState(). The chosen value is persisted locally.
/// Initial value injected by `main()` after reading SharedPreferences.
/// The default keeps widget tests independent from the native plugin.
final initialThemeModeProvider = Provider<ThemeMode>((ref) => ThemeMode.system);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(super.initial);

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await PreferencesService.setThemeMode(mode);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier(ref.watch(initialThemeModeProvider));
});
