import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipemate/core/data/mock_data.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/features/fridge/providers/fridge_provider.dart';
import 'package:recipemate/features/recommendations/providers/recommendations_provider.dart';
import 'package:recipemate/features/recommendations/services/matching_service.dart';
import 'package:recipemate/features/recommendations/widgets/gemini_idea_card.dart';
import 'package:recipemate/features/recommendations/widgets/recipe_match_card.dart';

/// AI Recommendations screen ("07 · Recettes IA") ranking recipes by fridge match.
class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  ConsumerState<RecommendationsScreen> createState() =>
      _RecommendationsScreenState();
}

class _RecommendationsScreenState extends ConsumerState<RecommendationsScreen> {
  bool _isGeneratingIdea = false;

  Future<void> _onGenerateGeminiIdea() async {
    if (_isGeneratingIdea) {
      return;
    }

    setState(() => _isGeneratingIdea = true);
    try {
      final fridgeItems = ref.read(fridgeProvider).items;
      final service = ref.read(geminiRecipeServiceProvider);
      final suggestion = await service.generateAntiWasteIdea(
        fridgeItems: fridgeItems,
        profile: MockData.defaultUser,
      );
      if (!mounted) {
        return;
      }

      setState(() => _isGeneratingIdea = false);

      final expiringNames = fridgeItems
          .where((item) => item.isExpiringSoon)
          .take(4)
          .map((item) => item.ingredient.name)
          .toList();

      await showGeminiIdeaBottomSheet(
        context,
        suggestion: suggestion,
        expiringIngredientNames: expiringNames,
        isLiveGemini: service.hasApiKey,
      );
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _isGeneratingIdea = false);
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Impossible de générer une idée pour le moment. Réessayez.',
            ),
          ),
        );
    }
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/fridge');
    }
  }

  @override
  Widget build(BuildContext context) {
    final fridgeState = ref.watch(fridgeProvider);
    final activeSort = ref.watch(recommendationSortProvider);
    final results = ref.watch(recommendationsProvider);
    const user = MockData.defaultUser;

    final ingredientLabel = fridgeState.totalCount == 1
        ? '1 ingrédient'
        : '${fridgeState.totalCount} ingrédients';
    final profilePill = user.allergies.isEmpty
        ? 'Profil : ${user.diets.firstOrNull ?? 'Équilibré'}'
        : 'Sans ${user.allergies.join(', ').toLowerCase()}';
    final caloriePill = 'Objectif : ${user.calorieGoal} kcal';

    final countLabel = results.length <= 1 ? 'recette' : 'recettes';
    final foundLabel = results.length <= 1 ? ' trouvée' : ' trouvées';

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _RecommendationsHeroHeader(
            ingredientPill: ingredientLabel,
            profilePill: profilePill,
            caloriePill: caloriePill,
            onBackPressed: _handleBack,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SortBarRow(
                  countText: '${results.length} $countLabel',
                  suffixText: foundLabel,
                  activeSort: activeSort,
                  onSortChanged: (sort) =>
                      ref.read(recommendationSortProvider.notifier).state =
                          sort,
                ),
                const SizedBox(height: 16),
                GeminiAntiWasteCard(
                  expiringCount: fridgeState.expiringSoonCount,
                  isLoading: _isGeneratingIdea,
                  onGeneratePressed: _onGenerateGeminiIdea,
                ),
                const SizedBox(height: 18),
                if (results.isEmpty)
                  _EmptyRecommendationsCard(
                    onGoToFridge: () => context.go('/fridge'),
                  )
                else
                  for (var i = 0; i < results.length; i++) ...[
                    RecipeMatchCard(
                      key: ValueKey(results[i].recipe.id),
                      result: results[i],
                      onViewRecipe: () =>
                          context.push('/recipe/${results[i].recipe.id}'),
                    ),
                    if (i < results.length - 1) const SizedBox(height: 18),
                  ],
                const SizedBox(height: 18),
                Text(
                  'Les recettes générées par IA sont signalées et à vérifier '
                  'avant de cuisiner. Valeurs nutritionnelles indicatives.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationsHeroHeader extends StatelessWidget {
  const _RecommendationsHeroHeader({
    required this.ingredientPill,
    required this.profilePill,
    required this.caloriePill,
    required this.onBackPressed,
  });

  final String ingredientPill;
  final String profilePill;
  final String caloriePill;
  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    final translucentBg = AppColors.cream.withValues(alpha: 0.14);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
      child: ColoredBox(
        color: AppColors.forestGreen,
        child: Stack(
          children: [
            Positioned(
              right: -60,
              top: -40,
              child: IgnorePointer(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Semantics(
                          button: true,
                          label: 'Retour au frigo',
                          child: Tooltip(
                            message: 'Retour au frigo',
                            child: Material(
                              color: translucentBg,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: onBackPressed,
                                child: const SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Icon(
                                    Icons.chevron_left_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: translucentBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                size: 14,
                                color: AppColors.sage,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Suggestions IA',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Recettes que vous pouvez cuisiner !',
                      style: GoogleFonts.poppins(
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Selon ce qui est déjà dans votre frigo.',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.softGreen,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _HeaderContextPill(
                          label: ingredientPill,
                          backgroundColor: translucentBg,
                        ),
                        _HeaderContextPill(
                          label: profilePill,
                          backgroundColor: translucentBg,
                        ),
                        _HeaderContextPill(
                          label: caloriePill,
                          backgroundColor: translucentBg,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderContextPill extends StatelessWidget {
  const _HeaderContextPill({
    required this.label,
    required this.backgroundColor,
  });

  final String label;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _SortBarRow extends StatelessWidget {
  const _SortBarRow({
    required this.countText,
    required this.suffixText,
    required this.activeSort,
    required this.onSortChanged,
  });

  final String countText;
  final String suffixText;
  final RecommendationSort activeSort;
  final ValueChanged<RecommendationSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: countText,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextSpan(
                  text: suffixText,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < RecommendationSort.values.length; i++) ...[
                _SortSegmentButton(
                  sort: RecommendationSort.values[i],
                  isSelected: RecommendationSort.values[i] == activeSort,
                  onTap: () => onSortChanged(RecommendationSort.values[i]),
                ),
                if (i < RecommendationSort.values.length - 1)
                  const SizedBox(width: 4),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SortSegmentButton extends StatelessWidget {
  const _SortSegmentButton({
    required this.sort,
    required this.isSelected,
    required this.onTap,
  });

  final RecommendationSort sort;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      label: 'Trier par ${sort.label}',
      child: Material(
        color: isSelected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            height: 36,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Center(
                child: Text(
                  sort.label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyRecommendationsCard extends StatelessWidget {
  const _EmptyRecommendationsCard({required this.onGoToFridge});

  final VoidCallback onGoToFridge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              size: 28,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Aucune recette trouvée',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ajoutez des ingrédients dans votre frigo ou essayez une idée '
            'sur mesure avec Gemini IA.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onGoToFridge,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Gérer mon frigo',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
