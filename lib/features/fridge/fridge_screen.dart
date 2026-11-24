import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipemate/core/data/recipe_database.dart';
import 'package:recipemate/core/models/fridge_item.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/core/theme/app_text_styles.dart';

/// Fridge stock listing. Quantities are deducted when a recipe is finished
/// (see `RecipeDatabaseController.recordRecipeCompletion`).
/// Owned by Adem.
class FridgeScreen extends ConsumerWidget {
  const FridgeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(recipeDatabaseProvider).fridgeItems;

    return items.isEmpty
        ? Center(
            child: Text(
              'Votre frigo est vide.',
              style: AppTextStyles.bodySecondary,
            ),
          )
        : ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) => _FridgeRow(item: items[index]),
          );
  }
}

class _FridgeRow extends StatelessWidget {
  const _FridgeRow({required this.item});

  final FridgeItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.kitchen_rounded,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.ingredient.name, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  item.expirationLabel,
                  style: AppTextStyles.caption.copyWith(
                    color: item.isExpired
                        ? AppColors.error
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${item.quantity.toStringAsFixed(1)} ${item.unit}',
            style: AppTextStyles.captionMedium,
          ),
        ],
      ),
    );
  }
}
