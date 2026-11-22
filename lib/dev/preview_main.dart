import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipemate/core/services/startup_resolver.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/core/theme/app_theme.dart';
import 'package:recipemate/features/onboarding/onboarding_screen.dart';
import 'package:recipemate/features/splash/splash_screen.dart';
import 'package:recipemate/shared/widgets/app_buttons.dart';

/// Dev-only entry point: `flutter run -t lib/dev/preview_main.dart`.
///
/// Previews Splash -> Onboarding -> confirmation without changing the
/// application router or the main entry point used by the rest of the team.
void main() {
  runApp(const ProviderScope(child: PreviewApp()));
}

class PreviewApp extends StatefulWidget {
  const PreviewApp({super.key});

  @override
  State<PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<PreviewApp> {
  int _step = 0;

  void _goToOnboarding() => setState(() => _step = 1);

  void _goToDone() => setState(() => _step = 2);

  void _restart() => setState(() => _step = 0);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RecipeMate - Aperçu Splash / Onboarding',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: switch (_step) {
          0 => SplashScreen(
            key: const ValueKey<int>(0),
            resolveDestination: () async => SplashDestination.onboarding,
            onDestination: (_) => _goToOnboarding(),
          ),
          1 => OnboardingScreen(
            key: const ValueKey<int>(1),
            persistCompletion: () async {},
            onFinished: _goToDone,
            onSkip: _goToDone,
          ),
          _ => Scaffold(
            key: const ValueKey<int>(2),
            backgroundColor: AppColors.cream,
            body: Center(
              child: PrimaryButton(
                label: 'Onboarding terminé - Recommencer',
                icon: Icons.replay_rounded,
                onPressed: _restart,
              ),
            ),
          ),
        },
      ),
    );
  }
}
