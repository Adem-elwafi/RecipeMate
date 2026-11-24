import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipemate/features/cooking_mode/step_durations.dart';
import 'package:recipemate/features/recipe_details/recipe_lookup.dart';

/// State of the immersive cooking flow for one recipe.
class CookingState {
  const CookingState({
    required this.currentStep,
    required this.totalSteps,
    required this.stepDurations,
    required this.remainingSeconds,
    this.isRunning = false,
    this.isCompleted = false,
  });

  final int currentStep;
  final int totalSteps;
  final List<int> stepDurations;
  final int remainingSeconds;
  final bool isRunning;
  final bool isCompleted;

  bool get hasTimer => stepDurations[currentStep] > 0;

  CookingState copyWith({
    int? currentStep,
    int? totalSteps,
    List<int>? stepDurations,
    int? remainingSeconds,
    bool? isRunning,
    bool? isCompleted,
  }) => CookingState(
    currentStep: currentStep ?? this.currentStep,
    totalSteps: totalSteps ?? this.totalSteps,
    stepDurations: stepDurations ?? this.stepDurations,
    remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    isRunning: isRunning ?? this.isRunning,
    isCompleted: isCompleted ?? this.isCompleted,
  );
}

/// Per-recipe controller driving steps and the countdown timer.
class CookingController extends FamilyNotifier<CookingState, String> {
  Timer? _timer;

  @override
  CookingState build(String recipeId) {
    final recipe = findRecipeById(recipeId);
    final durations = buildStepDurations(recipe);
    ref.onDispose(_stopTimer);
    return CookingState(
      currentStep: 0,
      totalSteps: recipe.instructions.length,
      stepDurations: durations,
      remainingSeconds: durations.first,
    );
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void goToStep(int index) {
    if (index < 0 || index >= state.totalSteps) return;
    _stopTimer();
    state = state.copyWith(
      currentStep: index,
      remainingSeconds: state.stepDurations[index],
      isRunning: false,
      isCompleted: false,
    );
  }

  void nextStep() {
    if (state.currentStep >= state.totalSteps - 1) {
      _stopTimer();
      state = state.copyWith(isRunning: false, isCompleted: true);
      return;
    }
    goToStep(state.currentStep + 1);
  }

  void previousStep() {
    if (state.currentStep <= 0) return;
    goToStep(state.currentStep - 1);
  }

  void toggleTimer() {
    if (state.isRunning) {
      _stopTimer();
      state = state.copyWith(isRunning: false);
      return;
    }
    if (state.remainingSeconds <= 0) {
      state = state.copyWith(
        remainingSeconds: state.stepDurations[state.currentStep],
      );
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = state.remainingSeconds - 1;
      if (remaining <= 0) {
        _stopTimer();
        state = state.copyWith(remainingSeconds: 0, isRunning: false);
      } else {
        state = state.copyWith(remainingSeconds: remaining);
      }
    });
    state = state.copyWith(isRunning: true);
  }

  void resetTimer() {
    _stopTimer();
    state = state.copyWith(
      remainingSeconds: state.stepDurations[state.currentStep],
      isRunning: false,
    );
  }

  void restart() {
    _stopTimer();
    state = state.copyWith(
      currentStep: 0,
      remainingSeconds: state.stepDurations.first,
      isRunning: false,
      isCompleted: false,
    );
  }
}

final cookingControllerProvider =
    NotifierProvider.family<CookingController, CookingState, String>(
      CookingController.new,
    );
