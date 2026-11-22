import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipemate/core/models/fridge_item.dart';
import 'package:recipemate/core/models/ingredient.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/features/fridge/providers/fridge_provider.dart';

/// Card displaying a single fridge ingredient with expiration badge and actions.
class FridgeItemCard extends StatelessWidget {
  const FridgeItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final FridgeItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final (icon, thumbBg, thumbIconColor) = _categoryVisuals(
      item.ingredient.category,
    );
    final (badgeBg, badgeTextColor) = _expirationBadgeColors(item);
    final imageUrl = item.ingredient.imageUrl?.trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _buildThumbnail(
            imageUrl: imageUrl,
            icon: icon,
            thumbBg: thumbBg,
            thumbIconColor: thumbIconColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.ingredient.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      formatFridgeQuantity(item.quantity, item.unit),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: SizedBox(
                          height: 22,
                          child: Center(
                            widthFactor: 1,
                            child: Text(
                              item.shortExpirationLabel,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: badgeTextColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _CardActionButton(
            icon: Icons.edit_outlined,
            tooltip: 'Modifier',
            semanticsLabel: 'Modifier ${item.ingredient.name}',
            backgroundColor: AppColors.cream,
            iconColor: AppColors.textSecondary,
            onPressed: onEdit,
          ),
          const SizedBox(width: 6),
          _CardActionButton(
            icon: Icons.delete_outline,
            tooltip: 'Supprimer',
            semanticsLabel: 'Supprimer ${item.ingredient.name}',
            backgroundColor: AppColors.errorContainer,
            iconColor: AppColors.error,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail({
    required String? imageUrl,
    required IconData icon,
    required Color thumbBg,
    required Color thumbIconColor,
  }) {
    final fallbackBox = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: thumbBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, size: 24, color: thumbIconColor),
    );

    if (imageUrl == null || imageUrl.isEmpty) {
      return fallbackBox;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        imageUrl,
        width: 52,
        height: 52,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) =>
            loadingProgress == null ? child : fallbackBox,
        errorBuilder: (_, _, _) => fallbackBox,
      ),
    );
  }

  (IconData, Color, Color) _categoryVisuals(IngredientCategory category) {
    return switch (category) {
      IngredientCategory.vegetables => (
        Icons.eco_outlined,
        AppColors.freshBadgeBg,
        AppColors.primary,
      ),
      IngredientCategory.fruits => (
        Icons.apple_outlined,
        AppColors.orangeContainer,
        AppColors.orangeText,
      ),
      IngredientCategory.meat || IngredientCategory.fish => (
        Icons.set_meal_outlined,
        AppColors.orangeContainer,
        AppColors.orangeText,
      ),
      IngredientCategory.dairy => (
        Icons.egg_outlined,
        AppColors.cream,
        AppColors.textSecondary,
      ),
      IngredientCategory.grains ||
      IngredientCategory.spices ||
      IngredientCategory.bakery ||
      IngredientCategory.other => (
        Icons.inventory_2_outlined,
        AppColors.cream,
        AppColors.textSecondary,
      ),
    };
  }

  (Color, Color) _expirationBadgeColors(FridgeItem item) {
    if (!item.hasExpirationDate) {
      return (AppColors.neutralBadgeBg, AppColors.textSecondary);
    }
    if (item.isExpired) {
      return (AppColors.errorContainer, AppColors.error);
    }
    if (item.isExpiringSoon) {
      return (AppColors.orangeContainer, AppColors.orangeText);
    }
    return (AppColors.freshBadgeBg, AppColors.tonalGreenText);
  }
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.icon,
    required this.tooltip,
    required this.semanticsLabel,
    required this.backgroundColor,
    required this.iconColor,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final String semanticsLabel;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, size: 17, color: iconColor),
            ),
          ),
        ),
      ),
    );
  }
}
