import 'package:flutter/material.dart';
import 'package:recipemate/core/theme/app_colors.dart';

/// 5-item bottom navigation bar for RecipeMate.
/// Material 3 NavigationBar with softGreen pill indicator.
class AppNavBar extends StatelessWidget {
  const AppNavBar({required this.currentIndex, required this.onTap, super.key});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: AppColors.card,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.softGreen,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
          label: 'Accueil',
        ),
        NavigationDestination(
          icon: Icon(Icons.search_rounded),
          selectedIcon: Icon(Icons.search_rounded, color: AppColors.primary),
          label: 'Explorer',
        ),
        NavigationDestination(
          icon: Icon(Icons.kitchen_outlined),
          selectedIcon: Icon(Icons.kitchen_rounded, color: AppColors.primary),
          label: 'Mon frigo',
        ),
        NavigationDestination(
          icon: Icon(Icons.auto_awesome_outlined),
          selectedIcon: Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.primary,
          ),
          label: 'Recettes IA',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
          label: 'Profil',
        ),
      ],
    );
  }
}
