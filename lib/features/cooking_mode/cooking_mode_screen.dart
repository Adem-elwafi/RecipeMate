import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:recipemate/core/data/mock_data.dart';
import 'package:recipemate/core/models/recipe.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/core/theme/app_text_styles.dart';
import 'package:recipemate/shared/widgets/app_buttons.dart';

/// Immersive step-by-step cooking mode (Owner: Molka).
class CookingModeScreen extends StatefulWidget {
  const CookingModeScreen({required this.recipeId, super.key});

  final String recipeId;

  @override
  State<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen> {
  int _currentStepIndex = 0;
  Timer? _timer;
  int _secondsRemaining = 300; // 5 minutes default step timer
  bool _isTimerRunning = false;

  Recipe get _recipe {
    try {
      return MockData.recipes.firstWhere((r) => r.id == widget.recipeId);
    } catch (_) {
      return MockData.recipes.first;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isTimerRunning) {
      _timer?.cancel();
      setState(() => _isTimerRunning = false);
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() => _secondsRemaining--);
        } else {
          timer.cancel();
          setState(() => _isTimerRunning = false);
        }
      });
      setState(() => _isTimerRunning = true);
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 300;
      _isTimerRunning = false;
    });
  }

  String get _formattedTimer {
    final mins = _secondsRemaining ~/ 60;
    final secs = _secondsRemaining % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final instructions = _recipe.instructions;
    final totalSteps = instructions.length;
    final currentStep = instructions[_currentStepIndex];
    final progress = (_currentStepIndex + 1) / totalSteps;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          'Mode Cuisine',
          style: AppTextStyles.title.copyWith(fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.softGreen,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Étape ${_currentStepIndex + 1} sur $totalSteps',
                    style: AppTextStyles.captionMedium.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(_recipe.title, style: AppTextStyles.caption),
                ],
              ),
              const SizedBox(height: 32),

              // Step Instruction Card
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.borderSubtle),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F000000),
                        blurRadius: 20,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.softGreenLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'ACTION ${_currentStepIndex + 1}',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            currentStep,
                            style: AppTextStyles.subtitle.copyWith(
                              fontSize: 22,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      // Optional Step Timer
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.softGreenLight,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              color: AppColors.primary,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _formattedTimer,
                              style: AppTextStyles.titleLarge.copyWith(
                                color: AppColors.primaryDark,
                                fontSize: 24,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: Icon(
                                _isTimerRunning
                                    ? Icons.pause_circle_rounded
                                    : Icons.play_circle_rounded,
                              ),
                              iconSize: 36,
                              color: AppColors.primary,
                              onPressed: _toggleTimer,
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded),
                              iconSize: 26,
                              color: AppColors.greyIcon,
                              onPressed: _resetTimer,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Navigation Buttons
              Row(
                children: [
                  if (_currentStepIndex > 0)
                    Expanded(
                      child: OutlineButtonWidget(
                        label: 'Précédent',
                        icon: Icons.arrow_back_rounded,
                        onPressed: () {
                          setState(() {
                            _currentStepIndex--;
                            _resetTimer();
                          });
                        },
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 16),
                  Expanded(
                    child: PrimaryButton(
                      label: _currentStepIndex < totalSteps - 1
                          ? 'Suivant'
                          : 'Terminer ! 🎉',
                      icon: _currentStepIndex < totalSteps - 1
                          ? Icons.arrow_forward_rounded
                          : Icons.check_circle_rounded,
                      onPressed: () {
                        if (_currentStepIndex < totalSteps - 1) {
                          setState(() {
                            _currentStepIndex++;
                            _resetTimer();
                          });
                        } else {
                          context.pop();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
