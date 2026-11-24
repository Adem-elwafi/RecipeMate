import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipemate/core/data/recipe_database.dart';
import 'package:recipemate/core/models/recipe.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/core/theme/app_text_styles.dart';
import 'package:recipemate/features/cooking_mode/controllers/cooking_controller.dart';
import 'package:recipemate/features/cooking_mode/step_durations.dart';
import 'package:recipemate/features/recipe_details/recipe_lookup.dart';
import 'package:recipemate/shared/widgets/app_buttons.dart';

/// Immersive step-by-step cooking screen with a per-step timer.
/// Owned by Molka.
class CookingModeScreen extends ConsumerWidget {
  const CookingModeScreen({this.recipeId, super.key});

  final String? recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipe = findRecipeById(recipeId ?? 'rec_1');
    final state = ref.watch(cookingControllerProvider(recipe.id));
    final controller = ref.read(cookingControllerProvider(recipe.id).notifier);
    final instruction = recipe.instructions[state.currentStep];
    final isLastStep = state.currentStep == state.totalSteps - 1;

    ref.listen(cookingControllerProvider(recipe.id), (previous, next) {
      if (next.isCompleted) {
        _completeRecipe(context, ref, recipe);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              recipe.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.captionMedium,
            ),
            Text(
              'Étape ${state.currentStep + 1} sur ${state.totalSteps}',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 14,
                  color: AppColors.tonalGreenText,
                ),
                const SizedBox(width: 4),
                Text(
                  'Écran actif',
                  style: AppTextStyles.badge.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
      body: state.isCompleted
          ? _completionView(context, recipe, controller)
          : _stepView(
              context,
              recipe,
              instruction,
              state,
              controller,
              isLastStep,
            ),
    );
  }

  Widget _stepView(
    BuildContext context,
    Recipe recipe,
    String instruction,
    CookingState state,
    CookingController controller,
    bool isLastStep,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        children: [
          _progressBar(state),
          const SizedBox(height: 20),
          _stepImage(recipe, state.currentStep),
          const SizedBox(height: 22),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(stepTitle(instruction), style: AppTextStyles.title),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(instruction, style: AppTextStyles.bodySecondary),
          ),
          const SizedBox(height: 24),
          if (state.hasTimer) _timerCard(state, controller) else _noTimerCard(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlineButtonWidget(
                  label: 'Précédent',
                  icon: Icons.arrow_back_rounded,
                  isFullWidth: true,
                  onPressed: state.currentStep == 0
                      ? null
                      : controller.previousStep,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: isLastStep ? 'Terminer' : 'Suivant',
                  icon: isLastStep
                      ? Icons.check_rounded
                      : Icons.arrow_forward_rounded,
                  isFullWidth: true,
                  onPressed: controller.nextStep,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _progressBar(CookingState state) {
    return Row(
      children: [
        for (var i = 0; i < state.totalSteps; i++)
          Expanded(
            child: Container(
              height: 6,
              margin: EdgeInsets.only(right: i == state.totalSteps - 1 ? 0 : 6),
              decoration: BoxDecoration(
                color: i <= state.currentStep
                    ? AppColors.primary
                    : AppColors.softGreen,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
      ],
    );
  }

  Widget _stepImage(Recipe recipe, int stepIndex) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 190,
            width: double.infinity,
            child: Image.network(
              recipe.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: AppColors.softGreen,
                child: Center(
                  child: Icon(
                    Icons.restaurant_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 12,
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              (stepIndex + 1).toString().padLeft(2, '0'),
              style: AppTextStyles.button.copyWith(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _timerCard(CookingState state, CookingController controller) {
    final status = state.isRunning
        ? 'En cours'
        : (state.remainingSeconds == 0 ? 'Terminé' : 'Prêt à démarrer');
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14292D27),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            formatTimer(state.remainingSeconds),
            style: GoogleFonts.poppins(
              fontSize: 44,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.02 * 44,
              color: state.isRunning
                  ? AppColors.primary
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Minuteur', style: AppTextStyles.captionMedium),
              Text(' · ', style: AppTextStyles.caption),
              Text(status, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: controller.resetTimer,
                icon: const Icon(Icons.restart_alt_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.softGreenLight,
                  foregroundColor: AppColors.primary,
                ),
              ),
              const SizedBox(width: 20),
              Material(
                color: AppColors.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: controller.toggleTimer,
                  child: SizedBox(
                    width: 58,
                    height: 58,
                    child: Icon(
                      state.isRunning
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _noTimerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.softGreenLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(
            'Cette étape ne nécessite pas de minuteur.',
            style: AppTextStyles.bodySecondary,
          ),
        ],
      ),
    );
  }

  /// Marks the recipe as finished: deducts used ingredients from the fridge
  /// and adds the nutrition to today's totals (see `RecipeDatabase`).
  void _completeRecipe(BuildContext context, WidgetRef ref, Recipe recipe) {
    ref.read(recipeDatabaseProvider.notifier).recordRecipeCompletion(recipe);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Recette terminée — ingrédients retirés du frigo et nutrition '
            'ajoutée à vos repas du jour.',
          ),
        ),
      );
  }

  Widget _completionView(
    BuildContext context,
    Recipe recipe,
    CookingController controller,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.softGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.celebration_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 22),
            Text('Bravo, c’est prêt !', style: AppTextStyles.titleLarge),
            const SizedBox(height: 10),
            Text(
              'Vous avez terminé « ${recipe.title} ».\nBon appétit !',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: 26),
            PrimaryButton(
              label: 'Retour à la recette',
              icon: Icons.arrow_back_rounded,
              onPressed: () => context.pop(),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: controller.restart,
              child: const Text('Recommencer'),
            ),
          ],
        ),
      ),
    );
  }
}
