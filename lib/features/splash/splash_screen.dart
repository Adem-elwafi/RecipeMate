import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:recipemate/core/config/app_assets.dart';
import 'package:recipemate/core/config/app_config.dart';
import 'package:recipemate/core/services/startup_resolver.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/core/theme/app_text_styles.dart';

/// Écran de lancement affiché pendant que l'application décide où aller.
/// Propriété de Farah. La décision est déléguée à [StartupResolver].
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    // Point 1 : durée configurable, 6 secondes par défaut.
    this.duration = AppConfig.splashDurationSeconds,
    this.resolveDestination = StartupResolver.resolve,
    this.onDestination,
  });

  final Duration duration;
  final Future<SplashDestination> Function() resolveDestination;
  final void Function(SplashDestination)? onDestination;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  late final Animation<double> _scale = Tween<double>(
    begin: 0.86,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  Timer? _timer;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, _navigate);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    if (_isNavigating) {
      return;
    }
    _isNavigating = true;

    SplashDestination destination;
    try {
      destination = await widget.resolveDestination();
    } on Object {
      // Si les préférences sont indisponibles, l'onboarding reste la valeur
      // la plus sûre (aucune session Firebase n'est supposée).
      destination = SplashDestination.onboarding;
    }
    if (!mounted) {
      return;
    }

    final callback = widget.onDestination;
    if (callback != null) {
      callback(destination);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Logo officiel sur fond crème (le SVG porte son propre fond
                  // arrondi et reste cohérent avec le splash natif Android).
                  SvgPicture.asset(
                    appSplashLogoAssetPath,
                    width: 160,
                    height: 160,
                    // Point 9 : texte alternatif en français.
                    semanticsLabel: 'Logo RecipeMate',
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'RecipeMate',
                    style: AppTextStyles.display.copyWith(
                      color: AppColors.cream,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Mangez sainement. Cuisinez malin.',
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: AppColors.softGreen,
                    ),
                  ),
                  const SizedBox(height: 36),
                  const SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.softGreen,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
