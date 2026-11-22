import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipemate/core/models/fridge_item.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/features/fridge/providers/fridge_provider.dart';
import 'package:recipemate/features/fridge/widgets/fridge_edit_sheet.dart';
import 'package:recipemate/features/fridge/widgets/fridge_item_card.dart';
import 'package:recipemate/features/fridge/widgets/fridge_quick_add_card.dart';
import 'package:recipemate/features/fridge/widgets/fridge_stats_banner.dart';
import 'package:recipemate/features/recommendations/providers/recommendations_provider.dart';

/// Main Mon Frigo screen for managing available ingredients and expirations.
class FridgeScreen extends ConsumerStatefulWidget {
  const FridgeScreen({super.key});

  @override
  ConsumerState<FridgeScreen> createState() => _FridgeScreenState();
}

class _FridgeScreenState extends ConsumerState<FridgeScreen> {
  Future<void> _editItem(FridgeItem item) async {
    final updated = await showFridgeEditSheet(context, item: item);
    if (!mounted || updated == null) {
      return;
    }
    ref.read(fridgeProvider.notifier).updateItem(updated);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text('${updated.ingredient.name} mis à jour')),
      );
  }

  void _deleteItem(FridgeItem item) {
    final notifier = ref.read(fridgeProvider.notifier)..removeItem(item.id);

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('${item.ingredient.name} supprimé du frigo'),
          action: SnackBarAction(
            label: 'Annuler',
            onPressed: () => notifier.restoreItem(item),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fridgeProvider);
    final notifier = ref.read(fridgeProvider.notifier);
    final possibleRecipesCount = ref.watch(possibleRecipesCountProvider);
    final groupedItems = state.groupedItems;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.only(top: 20, bottom: 28),
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mon frigo',
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gérez vos ingrédients disponibles.',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Semantics(
                    button: true,
                    label: 'Scanner un code-barres',
                    child: Tooltip(
                      message: 'Scanner un code-barres',
                      child: Material(
                        color: AppColors.textPrimary,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => context.push('/scanner'),
                          child: const SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(
                              Icons.qr_code_scanner_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Green Stats Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FridgeStatsBanner(
                totalCount: state.totalCount,
                expiringSoonCount: state.expiringSoonCount,
                possibleRecipesCount: possibleRecipesCount,
              ),
            ),

            const SizedBox(height: 20),

            // Quick-Add Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FridgeQuickAddCard(
                onAddItem: notifier.addItem,
                onScanPressed: () => context.push('/scanner'),
              ),
            ),

            const SizedBox(height: 20),

            // Category Filter Tabs
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: FridgeCategoryFilter.values.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final filter = FridgeCategoryFilter.values[index];
                  final isSelected = state.selectedCategory == filter;
                  return _CategoryFilterPill(
                    label: filter.label,
                    isSelected: isSelected,
                    onTap: () => notifier.selectCategory(filter),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Grouped Ingredient List or Empty State
            if (groupedItems.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _EmptyFridgeCard(
                  isFiltered:
                      state.selectedCategory != FridgeCategoryFilter.all,
                  onResetFilter: () =>
                      notifier.selectCategory(FridgeCategoryFilter.all),
                ),
              )
            else
              for (final entry in groupedItems.entries) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.key.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${entry.value.length} article${entry.value.length > 1 ? 's' : ''}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      for (var i = 0; i < entry.value.length; i++) ...[
                        FridgeItemCard(
                          key: ValueKey(entry.value[i].id),
                          item: entry.value[i],
                          onEdit: () => _editItem(entry.value[i]),
                          onDelete: () => _deleteItem(entry.value[i]),
                        ),
                        if (i < entry.value.length - 1)
                          const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

            if (groupedItems.isEmpty) const SizedBox(height: 20),

            // Bottom CTA Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => context.go('/recommendations'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Trouver des recettes avec mes ingrédients',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilterPill extends StatelessWidget {
  const _CategoryFilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: isSelected ? AppColors.textPrimary : AppColors.card,
        shape: StadiumBorder(
          side: BorderSide(
            color: isSelected ? AppColors.textPrimary : AppColors.chipBorder,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(
              height: 40,
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
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

class _EmptyFridgeCard extends StatelessWidget {
  const _EmptyFridgeCard({
    required this.isFiltered,
    required this.onResetFilter,
  });

  final bool isFiltered;
  final VoidCallback onResetFilter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.kitchen_outlined,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Aucun ingrédient dans cette catégorie',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ajoutez un ingrédient ci-dessus ou scannez un produit pour enrichir votre frigo.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          if (isFiltered) ...[
            const SizedBox(height: 14),
            TextButton(
              onPressed: onResetFilter,
              child: Text(
                'Voir tous les ingrédients',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
