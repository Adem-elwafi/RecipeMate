import 'package:recipemate/core/models/recipe.dart';

/// Fake per-step timer durations (in seconds) derived from the recipe timings.
List<int> buildStepDurations(Recipe recipe) =>
    List<int>.generate(recipe.instructions.length, (index) {
      if (index == 0) return recipe.prepTimeMinutes * 60;
      if (index == 1) return recipe.cookTimeMinutes * 60;
      return 0;
    });

/// Builds a short title from the beginning of a mock instruction sentence.
String stepTitle(String instruction) {
  final firstPart = instruction.split(RegExp('[,;]')).first.trim();
  final words = firstPart.split(' ');
  if (words.length <= 5) return firstPart;
  return '${words.take(5).join(' ')}…';
}

/// Formats a duration as `mm:ss`.
String formatTimer(int seconds) {
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${rest.toString().padLeft(2, '0')}';
}
