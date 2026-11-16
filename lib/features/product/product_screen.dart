import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/core/theme/app_text_styles.dart';
import 'package:recipemate/shared/widgets/app_buttons.dart';

/// Scanned food product detail sheet (Owner: Adem).
class ProductScreen extends StatefulWidget {
  const ProductScreen({required this.barcode, super.key});

  final String barcode;

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  DateTime _expirationDate = DateTime.now().add(const Duration(days: 7));
  double _quantity = 1;
  final String _unit = 'pièce';

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _expirationDate = picked);
    }
  }

  void _addToFridge() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Aliment ajouté au frigo avec succès ! 🌱'),
        duration: Duration(seconds: 2),
      ),
    );
    context.go('/fridge');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fiche Produit')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          // Product Header Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: AppColors.softGreenLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    size: 38,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Produit scanné',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Feta Grecque AOP Bio',
                        style: AppTextStyles.subtitle.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Code : ${widget.barcode}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Scores Row (Nutri-Score, Eco-Score, Nova)
          Row(
            children: [
              Expanded(
                child: _scoreCard(
                  title: 'Nutri-Score',
                  badge: 'D',
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _scoreCard(
                  title: 'Eco-Score',
                  badge: 'B',
                  color: Colors.lightGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _scoreCard(
                  title: 'Groupe Nova',
                  badge: '3',
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Expiration & Fridge Config
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ajout à votre frigo',
                  style: AppTextStyles.subtitle.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 16),

                // Expiration Date Picker Row
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.softGreenLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date de péremption',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              DateFormat(
                                'EEEE d MMMM yyyy',
                                'fr_FR',
                              ).format(_expirationDate),
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: AppColors.greyIcon,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Quantity Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Quantité :', style: AppTextStyles.bodyMedium),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                        ),
                        Text(
                          '${_quantity.toInt()} $_unit',
                          style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => setState(() => _quantity++),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          PrimaryButton(
            label: 'Ajouter au frigo',
            icon: Icons.add_shopping_cart_rounded,
            isFullWidth: true,
            onPressed: _addToFridge,
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Module développé par Adem',
              style: AppTextStyles.caption,
            ),
          ),
        ],
      ),
    );
  }

  Widget _scoreCard({
    required String title,
    required String badge,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badge,
              style: AppTextStyles.title.copyWith(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTextStyles.caption.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
