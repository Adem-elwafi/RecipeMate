import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/core/theme/app_text_styles.dart';
import 'package:recipemate/shared/widgets/app_buttons.dart';

/// 3-step onboarding carousel (Owner: Farah).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Gérez votre frigo & évitez le gaspillage',
      'description': 'Suivez vos stocks en temps réel avec des alertes de péremption pour cuisiner malin et économique.',
      'icon': Icons.kitchen_rounded,
    },
    {
      'title': 'Scannez vos produits alimentaires',
      'description': 'Scannez les codes-barres pour obtenir instantanément Nutri-Score, Eco-Score et ajouter vos achats en un clic.',
      'icon': Icons.qr_code_scanner_rounded,
    },
    {
      'title': 'Des recettes sur mesure selon vos stocks',
      'description': 'Découvrez des idées de repas délicieuses qui utilisent exactement ce que vous avez déjà dans vos placards.',
      'icon': Icons.auto_awesome_rounded,
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Passer'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    final item = _pages[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 130,
                          height: 130,
                          decoration: const BoxDecoration(
                            color: AppColors.softGreen,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            size: 64,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          item['title'] as String,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.display.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item['description'] as String,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySecondary.copyWith(
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Indicators & Button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) {
                  final isCurrent = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isCurrent ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isCurrent ? AppColors.primary : AppColors.sage,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              PrimaryButton(
                label: _currentPage == _pages.length - 1
                    ? 'Commencer l’aventure'
                    : 'Suivant',
                isFullWidth: true,
                onPressed: _onNext,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
