import 'package:flutter/material.dart';
import 'package:recipemate/core/services/preferences_service.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/core/theme/app_text_styles.dart';
import 'package:recipemate/features/onboarding/widgets/onboarding_illustrations.dart';

/// 3-step welcome carousel. Owned by Farah.
///
/// [onFinished] and [onSkip] let the router (or a widget test) decide what
/// happens next, while the screen itself records that onboarding is done.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    this.onFinished,
    this.onSkip,
    this.persistCompletion = PreferencesService.setOnboardingCompleted,
  });

  final VoidCallback? onFinished;
  final VoidCallback? onSkip;
  final Future<void> Function() persistCompletion;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.illustration,
    required this.title,
    required this.description,
    this.badge,
  });

  final Widget illustration;
  final String title;
  final String description;
  final String? badge;
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static final List<_OnboardingPage> _pages = <_OnboardingPage>[
    _OnboardingPage(
      illustration: OnboardingIllustrations.logo(),
      title: 'Bienvenue sur RecipeMate',
      description: 'Mangez sainement. Cuisinez malin.',
    ),
    _OnboardingPage(
      illustration: OnboardingIllustrations.salad(),
      title: 'Des recettes pensées pour vous',
      description:
          'Végétarien, keto, sans gluten... RecipeMate s’adapte à vos '
          'préférences et à vos allergies.',
      badge: 'Végétarien – Sans gluten',
    ),
    _OnboardingPage(
      illustration: OnboardingIllustrations.fridge(),
      title: 'Cuisinez avec ce que vous avez déjà',
      description:
          'Ajoutez vos ingrédients ou scannez-les : nous trouvons les '
          'recettes qui collent à votre frigo.',
    ),
  ];

  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _goToPage(_currentPage + 1);
    } else {
      _complete(widget.onFinished);
    }
  }

  Future<void> _complete(VoidCallback? callback) async {
    try {
      await widget.persistCompletion();
    } on Object {
      // Local storage can fail in tests or in private mode: navigation must
      // still work.
    }
    callback?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: <Widget>[
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _complete(widget.onSkip),
                  child: Text(
                    'Passer',
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: AppColors.softGreen,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) =>
                      _OnboardingPageView(page: _pages[index]),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List<Widget>.generate(_pages.length, (index) {
                  final isActive = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.cream : AppColors.sage,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 22),
              Row(
                children: <Widget>[
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _goToPage(_currentPage - 1),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.cream,
                          side: const BorderSide(color: AppColors.softGreen),
                          minimumSize: const Size(0, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text('Retour', style: AppTextStyles.button),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cream,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        isLastPage ? 'Commencer' : 'Suivant',
                        style: AppTextStyles.button,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            page.illustration,
            const SizedBox(height: 24),
            if (page.badge != null) ...<Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.softGreen,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(page.badge!, style: AppTextStyles.badge),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              page.title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleLarge.copyWith(color: AppColors.cream),
            ),
            const SizedBox(height: 12),
            Text(
              page.description,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary.copyWith(
                color: AppColors.softGreen,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
