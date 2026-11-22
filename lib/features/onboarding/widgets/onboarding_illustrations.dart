import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:recipemate/core/config/app_assets.dart';
import 'package:recipemate/core/theme/app_colors.dart';

/// Simple vector illustrations built with Flutter widgets only.
///
/// They follow the reference mockups (salad plate, fridge, brand logo) and
/// avoid adding random stock images to the project.
abstract final class OnboardingIllustrations {
  static Widget logo() {
    // Ancien placeholder (Icons.eco_rounded) remplacé par le mark officiel.
    return Container(
      width: 132,
      height: 132,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(32),
      ),
      child: SvgPicture.asset(
        appLogoAssetPath,
        fit: BoxFit.contain,
        semanticsLabel: 'Logo RecipeMate',
      ),
    );
  }

  static Widget salad() {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cream,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
          Container(
            width: 150,
            height: 150,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.card,
            ),
          ),
          const Positioned(
            left: 58,
            top: 66,
            child: _Leaf(color: AppColors.sage),
          ),
          const Positioned(
            right: 56,
            top: 78,
            child: _Leaf(color: AppColors.primaryLight),
          ),
          const Positioned(
            left: 84,
            top: 108,
            child: _Leaf(color: AppColors.softGreen),
          ),
          const Positioned(right: 82, bottom: 58, child: _Tomato()),
        ],
      ),
    );
  }

  static Widget fridge() {
    return Container(
      width: 190,
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Icon(Icons.apple, color: AppColors.error, size: 34),
                  Icon(Icons.eco, color: AppColors.orangeAccent, size: 34),
                  Icon(Icons.spa, color: AppColors.primary, size: 34),
                ],
              ),
            ),
          ),
          Container(height: 3, color: AppColors.sage),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 14),
                  child: Icon(Icons.drag_handle, color: AppColors.sage),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Leaf extends StatelessWidget {
  const _Leaf({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
    );
  }
}

class _Tomato extends StatelessWidget {
  const _Tomato();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.orangeText,
      ),
    );
  }
}
