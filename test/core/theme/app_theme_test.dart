import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:recipemate/core/theme/app_colors.dart';

void main() {
  test('la palette utilise exactement les couleurs de référence', () {
    expect(AppColors.primary, const Color(0xFF527C43));
    expect(AppColors.sage, const Color(0xFFA8C982));
    expect(AppColors.softGreen, const Color(0xFFDDEBCB));
    expect(AppColors.cream, const Color(0xFFF5F2E9));
    expect(AppColors.card, const Color(0xFFFFFFFF));
    expect(AppColors.textPrimary, const Color(0xFF292D27));
    expect(AppColors.greyIcon, const Color(0xFF858B7D));
    expect(AppColors.textSecondary, const Color(0xFF5E6457));
    expect(AppColors.orangeAccent, const Color(0xFFE9A65A));
    expect(AppColors.orangeText, const Color(0xFF9A5A12));
    expect(AppColors.error, const Color(0xFFB3261E));

    // Les alias sémantiques ne doivent jamais introduire une autre nuance.
    expect(AppColors.tonalGreenText, AppColors.textPrimary);
    expect(AppColors.primaryDark, AppColors.primary);
    expect(AppColors.primaryLight, AppColors.primary);
    expect(AppColors.softGreenLight, AppColors.softGreen);
    expect(AppColors.favoriteIcon, AppColors.orangeAccent);
    expect(AppColors.errorContainer, AppColors.card);
    expect(AppColors.orangeContainer, AppColors.cream);
  });
}
