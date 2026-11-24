import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gives access to the device local storage.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return SharedPreferences.getInstance();
});

/// Whether the onboarding carousel has already been completed.
final onboardingCompletedProvider =
    AsyncNotifierProvider<OnboardingCompletedNotifier, bool>(
      OnboardingCompletedNotifier.new,
    );

/// Persists the onboarding completion flag on the device.
class OnboardingCompletedNotifier extends AsyncNotifier<bool> {
  static const String _storageKey = 'onboarding_completed';

  @override
  Future<bool> build() async {
    final preferences = await ref.watch(sharedPreferencesProvider.future);
    return preferences.getBool(_storageKey) ?? false;
  }

  /// Marks the onboarding as completed so it is not shown again.
  Future<void> complete() async {
    final preferences = await ref.read(sharedPreferencesProvider.future);
    await preferences.setBool(_storageKey, true);
    state = const AsyncValue<bool>.data(true);
  }
}
