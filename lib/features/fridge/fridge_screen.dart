import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:recipemate/core/data/mock_data.dart';
import 'package:recipemate/core/models/fridge_item.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/core/theme/app_text_styles.dart';

/// Anti-waste smart fridge management screen (Owner: Adem).
class FridgeScreen extends StatefulWidget {
  const FridgeScreen({super.key});

  @override
  State<FridgeScreen> createState() => _FridgeScreenState();
}

class _FridgeScreenState extends State<FridgeScreen> {
  late List<FridgeItem> _items;
  bool _filterExpiringOnly = false;

  @override
  void initState() {
    super.initState();
    _items = List.from(MockData.initialFridgeItems);
    _sortItems();
  }

  void _sortItems() {
    _items.sort(
      (a, b) => a.daysUntilExpiration.compareTo(b.daysUntilExpiration),
    );
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Aliment retiré du frigo'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedItems = _filterExpiringOnly
        ? _items.where((item) => item.isExpiringSoon).toList()
        : _items;

    final expiringCount = _items.where((i) => i.isExpiringSoon).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mon Frigo (${_items.length})',
          style: AppTextStyles.title.copyWith(fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            tooltip: 'Scanner un code-barres',
            onPressed: () => context.push('/scanner'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Anti-Waste Status Summary Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: Text('Expire bientôt ($expiringCount)'),
                  selected: _filterExpiringOnly,
                  selectedColor: AppColors.orangeContainer,
                  checkmarkColor: AppColors.orangeText,
                  labelStyle: AppTextStyles.captionMedium.copyWith(
                    color: _filterExpiringOnly
                        ? AppColors.orangeText
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: _filterExpiringOnly
                        ? AppColors.orangeAccent
                        : AppColors.borderSubtle,
                  ),
                  onSelected: (selected) {
                    setState(() => _filterExpiringOnly = selected);
                  },
                ),
                const Spacer(),
                Text(
                  'Trié par péremption',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Items List
          Expanded(
            child: displayedItems.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.kitchen_rounded,
                            size: 56,
                            color: AppColors.greyIcon,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _filterExpiringOnly
                                ? 'Aucun aliment n’expire bientôt ! 🎉'
                                : 'Votre frigo est vide',
                            style: AppTextStyles.subtitle,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Scannez vos produits ou ajoutez-les manuellement.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: displayedItems.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = displayedItems[index];
                      final isAlert = item.isExpiringSoon;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isAlert
                                ? AppColors.orangeAccent.withValues(alpha: 0.4)
                                : AppColors.borderSubtle,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isAlert
                                    ? AppColors.orangeContainer
                                    : AppColors.softGreenLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isAlert
                                    ? Icons.alarm_rounded
                                    : Icons.eco_rounded,
                                color: isAlert
                                    ? AppColors.orangeText
                                    : AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.ingredient.name,
                                    style: AppTextStyles.subtitle.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${item.quantity.toInt()} ${item.unit} · ${item.ingredient.category.label}',
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isAlert
                                        ? AppColors.orangeContainer
                                        : AppColors.softGreenLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item.expirationLabel,
                                    style: AppTextStyles.caption.copyWith(
                                      color: isAlert
                                          ? AppColors.orangeText
                                          : AppColors.primaryDark,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () => _removeItem(index),
                                  child: Text(
                                    'Consommé',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/scanner'),
        backgroundColor: AppColors.primary,
        tooltip: 'Ajouter par scan',
        child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
      ),
    );
  }
}
