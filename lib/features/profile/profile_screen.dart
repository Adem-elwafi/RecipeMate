import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:recipemate/core/data/mock_data.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/core/theme/app_text_styles.dart';
import 'package:recipemate/shared/widgets/diet_badge.dart';

/// User profile and settings screen (Owner: Farah).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const user = MockData.defaultUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mon Profil',
          style: AppTextStyles.title.copyWith(fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          // User Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.softGreen,
                  child: Text(
                    user.name.split(' ').map((n) => n[0]).take(2).join(),
                    style: AppTextStyles.title.copyWith(
                      color: AppColors.primaryDark,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: AppTextStyles.title.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 2),
                      Text(user.email, style: AppTextStyles.caption),
                      const SizedBox(height: 8),
                      const DietBadge(
                        label: 'Membre Gourmet',
                        isSmall: true,
                        backgroundColor: AppColors.softGreenLight,
                        textColor: AppColors.primaryDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick Links
          Row(
            children: [
              Expanded(
                child: _quickLinkCard(
                  icon: Icons.favorite_rounded,
                  iconColor: AppColors.error,
                  label: 'Favoris',
                  count:
                      '${MockData.recipes.where((r) => r.isFavorite).length}',
                  onTap: () => context.push('/favorites'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _quickLinkCard(
                  icon: Icons.bookmark_rounded,
                  iconColor: AppColors.primary,
                  label: 'Collections',
                  count: '3',
                  onTap: () => context.push('/collections'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Nutrition Goals
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mes objectifs nutritionnels',
                  style: AppTextStyles.subtitle.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 16),
                _goalRow(
                  'Calories cibles',
                  '${user.calorieGoal} kcal / jour',
                  AppColors.macroCalories,
                ),
                const Divider(height: 20),
                _goalRow(
                  'Protéines',
                  '${user.proteinGoal.toInt()} g',
                  AppColors.macroProtein,
                ),
                const Divider(height: 20),
                _goalRow(
                  'Glucides',
                  '${user.carbsGoal.toInt()} g',
                  AppColors.macroCarbs,
                ),
                const Divider(height: 20),
                _goalRow(
                  'Lipides',
                  '${user.fatGoal.toInt()} g',
                  AppColors.macroFat,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Team Member Attribution
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.softGreenLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Module Profil & Réglages développé par Farah',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickLinkCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String count,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(height: 12),
              Text(
                count,
                style: AppTextStyles.titleLarge.copyWith(fontSize: 22),
              ),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _goalRow(String title, String value, Color indicatorColor) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: indicatorColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: AppTextStyles.body)),
        Text(
          value,
          style: AppTextStyles.captionMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
