import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:recipemate/core/data/mock_data.dart';
import 'package:recipemate/core/models/fridge_item.dart';
import 'package:recipemate/core/models/ingredient.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/features/fridge/providers/fridge_provider.dart';
import 'package:recipemate/features/product/models/scanned_product.dart';
import 'package:recipemate/features/product/providers/product_provider.dart';
import 'package:recipemate/features/product/services/open_food_facts_service.dart';
import 'package:recipemate/shared/widgets/app_buttons.dart';

/// Displays detailed nutritional, allergen, ingredient, and fridge-addition
/// controls for a product identified by [barcode].
class ProductScreen extends ConsumerStatefulWidget {
  const ProductScreen({
    required this.barcode,
    super.key,
    @visibleForTesting this.userAllergies,
  });

  /// EAN/barcode of the product to display.
  final String barcode;

  /// Optional override for the user's declared allergies in tests.
  final List<String>? userAllergies;

  @override
  ConsumerState<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends ConsumerState<ProductScreen> {
  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  int _packCount = 1;
  DateTime? _selectedExpirationDate;

  @override
  void didUpdateWidget(covariant ProductScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.barcode != widget.barcode) {
      _packCount = 1;
      _selectedExpirationDate = null;
    }
  }

  DateTime _defaultExpirationDate(ScannedProduct product) {
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: product.estimatedShelfLifeDays));
  }

  DateTime _effectiveExpirationDate(ScannedProduct product) {
    return _selectedExpirationDate ?? _defaultExpirationDate(product);
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/scanner');
    }
  }

  void _decrementPackCount() {
    if (_packCount <= 1) {
      return;
    }
    setState(() {
      _packCount--;
    });
  }

  void _incrementPackCount() {
    if (_packCount >= 99) {
      return;
    }
    setState(() {
      _packCount++;
    });
  }

  Future<void> _pickExpirationDate(ScannedProduct product) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(now.year + 5);
    final current = _effectiveExpirationDate(product);
    final initial = current.isBefore(today)
        ? today
        : current.isAfter(lastDate)
        ? lastDate
        : current;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: lastDate,
      helpText: 'À consommer avant',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedExpirationDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
        );
      });
    }
  }

  void _addToFridge(ScannedProduct product) {
    final expirationDate = _effectiveExpirationDate(product);
    final item = FridgeItem(
      id: 'fi_${product.barcode}_${DateTime.now().millisecondsSinceEpoch}',
      ingredient: product.toIngredient(),
      quantity: product.numericQuantity * _packCount,
      unit: product.unit,
      expirationDate: expirationDate,
    );

    ref.read(fridgeProvider.notifier).addItem(item);

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('${product.name} ajouté à votre frigo'),
          behavior: SnackBarBehavior.floating,
        ),
      );

    context.go('/fridge');
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productByBarcodeProvider(widget.barcode));

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: productAsync.when(
        loading: () => _ProductLoadingView(onBack: _handleBack),
        error: (error, stackTrace) => _ProductErrorView(
          message: _resolveErrorMessage(error),
          onRetry: () =>
              ref.invalidate(productByBarcodeProvider(widget.barcode)),
          onBack: _handleBack,
        ),
        data: (product) => _buildLoadedContent(context, product),
      ),
    );
  }

  Widget _buildLoadedContent(BuildContext context, ScannedProduct product) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final expirationDate = _effectiveExpirationDate(product);
    final userAllergies =
        widget.userAllergies ?? MockData.defaultUser.allergies;

    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            child: Stack(
              children: [
                _ProductHeroHeader(product: product, onBack: _handleBack),
                Padding(
                  padding: const EdgeInsets.only(top: 242),
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      20,
                      22,
                      20,
                      120 + bottomPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ProductTitleBlock(product: product),
                        const SizedBox(height: 18),
                        _NutriScoreCard(product: product),
                        const SizedBox(height: 18),
                        _NutritionCard(product: product),
                        const SizedBox(height: 18),
                        _AllergensCard(
                          allergens: product.allergens,
                          userAllergies: userAllergies,
                        ),
                        const SizedBox(height: 18),
                        _IngredientsCard(
                          ingredientsText: product.ingredientsText,
                          allergens: product.allergens,
                        ),
                        const SizedBox(height: 18),
                        _FridgeOptionsCard(
                          quantityLabel: product.quantityLabel,
                          packCount: _packCount,
                          formattedExpirationDate: _dateFormat.format(
                            expirationDate,
                          ),
                          onDecrement: _decrementPackCount,
                          onIncrement: _incrementPackCount,
                          onPickDate: () =>
                              unawaited(_pickExpirationDate(product)),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Source : base collaborative Open Food Facts.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _StickyAddToFridgeBar(onPressed: () => _addToFridge(product)),
        ),
      ],
    );
  }

  static String _resolveErrorMessage(Object error) {
    if (error is ProductNotFoundException) {
      return error.message;
    }
    return 'Impossible de récupérer les informations de ce produit.';
  }
}

class _HeroBackButton extends StatelessWidget {
  const _HeroBackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Retour',
      child: Tooltip(
        message: 'Retour',
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: AppColors.textPrimary.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: onPressed,
              child: const Center(
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductLoadingView extends StatelessWidget {
  const _ProductLoadingView({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 18),
                Text(
                  'Recherche sur Open Food Facts...',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(left: 20, top: 12),
              child: _HeroBackButton(onPressed: onBack),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductErrorView extends StatelessWidget {
  const _ProductErrorView({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.error,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Produit introuvable',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 22),
                PrimaryButton(
                  label: 'Réessayer',
                  icon: Icons.refresh_rounded,
                  isFullWidth: true,
                  onPressed: onRetry,
                ),
                const SizedBox(height: 10),
                OutlineButtonWidget(
                  label: 'Retour',
                  icon: Icons.arrow_back_rounded,
                  isFullWidth: true,
                  onPressed: onBack,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductHeroHeader extends StatelessWidget {
  const _ProductHeroHeader({required this.product, required this.onBack});

  final ScannedProduct product;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl?.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Container(
      height: 270,
      width: double.infinity,
      color: AppColors.productHeroBg,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Center(
              child: Container(
                width: 164,
                height: 164,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(36),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[AppColors.card, AppColors.softGreenLight],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.15),
                      blurRadius: 32,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(36),
                  child: hasImage
                      ? Image.network(
                          imageUrl,
                          width: 164,
                          height: 164,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _ProductCategoryPlaceholder(
                                category: product.suggestedCategory,
                              ),
                        )
                      : _ProductCategoryPlaceholder(
                          category: product.suggestedCategory,
                        ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(left: 20, top: 12),
                child: _HeroBackButton(onPressed: onBack),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCategoryPlaceholder extends StatelessWidget {
  const _ProductCategoryPlaceholder({required this.category});

  final IngredientCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.card, AppColors.freshBadgeBg],
        ),
      ),
      child: Center(
        child: Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            color: AppColors.softGreen.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            _iconForCategory(category),
            size: 40,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  static IconData _iconForCategory(IngredientCategory category) {
    return switch (category) {
      IngredientCategory.dairy => Icons.local_drink_rounded,
      IngredientCategory.vegetables => Icons.eco_rounded,
      IngredientCategory.fruits => Icons.apple_outlined,
      IngredientCategory.meat => Icons.set_meal_rounded,
      IngredientCategory.fish => Icons.phishing_rounded,
      IngredientCategory.grains => Icons.grain_rounded,
      IngredientCategory.spices => Icons.spa_rounded,
      IngredientCategory.bakery => Icons.bakery_dining_rounded,
      IngredientCategory.other => Icons.inventory_2_outlined,
    };
  }
}

class _ProductTitleBlock extends StatelessWidget {
  const _ProductTitleBlock({required this.product});

  final ScannedProduct product;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.brand,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.tonalGreenText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          product.name,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            height: 1.22,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${product.quantityLabel} · ${product.formattedEan}',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        if (product.isFromDemoFallback) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.neutralBadgeBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.chipBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Données de démonstration hors ligne',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _NutriScoreCard extends StatelessWidget {
  const _NutriScoreCard({required this.product});

  static const List<String> _grades = <String>['a', 'b', 'c', 'd', 'e'];

  final ScannedProduct product;

  @override
  Widget build(BuildContext context) {
    final activeGrade = product.nutriScoreGrade.toLowerCase();
    final descriptionColor = _descriptionColorForGrade(activeGrade);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Nutri-Score',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  product.nutriScoreDescription,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: descriptionColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Semantics(
            label: _grades.contains(activeGrade)
                ? 'Nutri-Score ${activeGrade.toUpperCase()}'
                : 'Nutri-Score non renseigné',
            excludeSemantics: true,
            child: Row(
              children: [
                for (var i = 0; i < _grades.length; i++) ...[
                  if (i > 0) const SizedBox(width: 4),
                  Expanded(
                    child: _NutriScoreGradeBlock(
                      grade: _grades[i],
                      isActive: _grades[i] == activeGrade,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Color _descriptionColorForGrade(String grade) {
    return switch (grade) {
      'a' => AppColors.nutriScoreA,
      'b' => AppColors.nutriScoreB,
      'c' => AppColors.nutriScoreC,
      'd' => AppColors.nutriScoreD,
      'e' => AppColors.nutriScoreE,
      _ => AppColors.textSecondary,
    };
  }
}

class _NutriScoreGradeBlock extends StatelessWidget {
  const _NutriScoreGradeBlock({required this.grade, required this.isActive});

  final String grade;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final background = _backgroundColor(grade);
    final foreground = grade == 'c' ? AppColors.textPrimary : Colors.white;
    final letter = grade.toUpperCase();

    if (isActive) {
      return Container(
        height: 52,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: background, width: 2),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            letter,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.0,
              color: foreground,
            ),
          ),
        ),
      );
    }

    return Opacity(
      opacity: 0.55,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          letter,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.0,
            color: foreground,
          ),
        ),
      ),
    );
  }

  static Color _backgroundColor(String grade) {
    return switch (grade) {
      'a' => AppColors.nutriScoreA,
      'b' => AppColors.nutriScoreB,
      'c' => AppColors.nutriScoreC,
      'd' => AppColors.nutriScoreD,
      'e' => AppColors.nutriScoreE,
      _ => AppColors.neutralBadgeBg,
    };
  }
}

class _NutritionCard extends StatelessWidget {
  const _NutritionCard({required this.product});

  final ScannedProduct product;

  @override
  Widget build(BuildContext context) {
    final rows = <_NutritionRowData>[
      _NutritionRowData(
        label: 'Énergie',
        dotColor: AppColors.primary,
        value: _formatNutrientValue(product.energyKcal, unit: 'kcal'),
      ),
      _NutritionRowData(
        label: 'Protéines',
        dotColor: AppColors.sage,
        value: _formatNutrientValue(product.proteins, unit: 'g'),
      ),
      _NutritionRowData(
        label: 'Glucides',
        dotColor: AppColors.orangeAccent,
        value: _formatNutrientValue(product.carbs, unit: 'g'),
      ),
      _NutritionRowData(
        label: 'dont sucres',
        dotColor: AppColors.macroSugars,
        value: _formatNutrientValue(product.sugars, unit: 'g'),
      ),
      _NutritionRowData(
        label: 'Lipides',
        dotColor: AppColors.greyIcon,
        value: _formatNutrientValue(product.fat, unit: 'g'),
      ),
      _NutritionRowData(
        label: 'Sel',
        dotColor: AppColors.macroSalt,
        value: _formatNutrientValue(product.salt, unit: 'g', decimals: 2),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Valeurs nutritionnelles',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'pour 100 g',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < rows.length; i++) ...[
            _NutritionRow(data: rows[i]),
            if (i < rows.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.dividerLight,
              ),
          ],
        ],
      ),
    );
  }

  static String _formatNutrientValue(
    double? value, {
    required String unit,
    int decimals = 1,
  }) {
    if (value == null || !value.isFinite) {
      return '—';
    }
    var cleaned = value.toStringAsFixed(decimals);
    if (cleaned.contains('.')) {
      cleaned = cleaned.replaceFirst(RegExp(r'0+$'), '');
      if (cleaned.endsWith('.')) {
        cleaned = cleaned.substring(0, cleaned.length - 1);
      }
    }
    final french = cleaned.replaceAll('.', ',');
    return '$french $unit';
  }
}

class _NutritionRowData {
  const _NutritionRowData({
    required this.label,
    required this.dotColor,
    required this.value,
  });

  final String label;
  final Color dotColor;
  final String value;
}

class _NutritionRow extends StatelessWidget {
  const _NutritionRow({required this.data});

  final _NutritionRowData data;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: data.dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                data.label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              data.value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllergensCard extends StatelessWidget {
  const _AllergensCard({required this.allergens, required this.userAllergies});

  final List<String> allergens;
  final List<String> userAllergies;

  @override
  Widget build(BuildContext context) {
    final hasConflict = _hasAllergyConflict(allergens, userAllergies);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Allergènes',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (allergens.isEmpty)
            Container(
              constraints: const BoxConstraints(minHeight: 32),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.freshBadgeBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 14,
                    color: AppColors.tonalGreenText,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Aucun allergène déclaré',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.tonalGreenText,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final allergen in allergens)
                  Container(
                    constraints: const BoxConstraints(minHeight: 32),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.orangeContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 14,
                          color: AppColors.allergenText,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            allergen,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.allergenText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                hasConflict ? Icons.warning_amber_rounded : Icons.check_rounded,
                size: 16,
                color: hasConflict ? AppColors.error : AppColors.tonalGreenText,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hasConflict
                      ? 'Attention : contient un allergène de votre profil'
                      : 'Compatible avec vos allergies déclarées',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: hasConflict ? FontWeight.w600 : FontWeight.w400,
                    color: hasConflict
                        ? AppColors.error
                        : AppColors.tonalGreenText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static bool _hasAllergyConflict(
    List<String> productAllergens,
    List<String> userAllergies,
  ) {
    if (productAllergens.isEmpty || userAllergies.isEmpty) {
      return false;
    }

    for (final allergen in productAllergens) {
      final normalizedAllergen = allergen.trim().toLowerCase();
      if (normalizedAllergen.isEmpty) {
        continue;
      }
      for (final userAllergy in userAllergies) {
        final normalizedUser = userAllergy.trim().toLowerCase();
        if (normalizedUser.isEmpty) {
          continue;
        }
        if (normalizedAllergen.contains(normalizedUser) ||
            normalizedUser.contains(normalizedAllergen)) {
          return true;
        }
      }
    }

    return false;
  }
}

class _IngredientsCard extends StatelessWidget {
  const _IngredientsCard({
    required this.ingredientsText,
    required this.allergens,
  });

  final String ingredientsText;
  final List<String> allergens;

  static const List<String> _baseAllergenKeywords = <String>[
    'lait',
    'gluten',
    'blé',
    'soja',
    'arachide',
    'arachides',
    'noisette',
    'noisettes',
    'amande',
    'amandes',
    'noix',
    'œuf',
    'œufs',
    'oeuf',
    'oeufs',
    'poisson',
    'poissons',
    'crustacé',
    'crustacés',
    'sésame',
    'moutarde',
    'céleri',
    'lupin',
    'mollusque',
    'mollusques',
    'sulfite',
    'sulfites',
  ];

  @override
  Widget build(BuildContext context) {
    final baseStyle = GoogleFonts.inter(
      fontSize: 14,
      height: 1.55,
      color: AppColors.textSecondary,
    );
    final highlightStyle = GoogleFonts.inter(
      fontSize: 14,
      height: 1.55,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ingrédients',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: baseStyle,
              children: _buildHighlightedSpans(
                ingredientsText,
                allergens,
                highlightStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<InlineSpan> _buildHighlightedSpans(
    String text,
    List<String> allergens,
    TextStyle highlightStyle,
  ) {
    final keywords = <String>{
      ..._baseAllergenKeywords,
      for (final allergen in allergens)
        if (allergen.trim().isNotEmpty) allergen.trim().toLowerCase(),
    }.toList()..sort((a, b) => b.length.compareTo(a.length));

    final escaped = keywords.map(RegExp.escape).join('|');
    if (escaped.isEmpty) {
      return <InlineSpan>[TextSpan(text: text)];
    }

    final pattern = RegExp(
      '(?<![a-zA-ZÀ-ÿ])($escaped)(?![a-zA-ZÀ-ÿ])',
      caseSensitive: false,
    );

    final spans = <InlineSpan>[];
    var lastIndex = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }
      spans.add(
        TextSpan(
          text: text.substring(match.start, match.end),
          style: highlightStyle,
        ),
      );
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return spans.isEmpty ? <InlineSpan>[TextSpan(text: text)] : spans;
  }
}

class _FridgeOptionsCard extends StatelessWidget {
  const _FridgeOptionsCard({
    required this.quantityLabel,
    required this.packCount,
    required this.formattedExpirationDate,
    required this.onDecrement,
    required this.onIncrement,
    required this.onPickDate,
  });

  final String quantityLabel;
  final int packCount;
  final String formattedExpirationDate;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final labelStyle = GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quantité', style: labelStyle),
                const SizedBox(height: 6),
                Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _StepperButton(
                        icon: Icons.remove_rounded,
                        tooltip: 'Diminuer la quantité',
                        enabled: packCount > 1,
                        onTap: onDecrement,
                      ),
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '$packCount × $quantityLabel',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      _StepperButton(
                        icon: Icons.add_rounded,
                        tooltip: 'Augmenter la quantité',
                        enabled: packCount < 99,
                        onTap: onIncrement,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('À consommer avant', style: labelStyle),
                const SizedBox(height: 6),
                Tooltip(
                  message: "Choisir la date d'expiration",
                  child: Material(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: onPickDate,
                      child: SizedBox(
                        height: 46,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    formattedExpirationDate,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: enabled ? onTap : null,
            child: SizedBox(
              width: 34,
              height: 46,
              child: Icon(
                icon,
                size: 18,
                color: enabled ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StickyAddToFridgeBar extends StatelessWidget {
  const _StickyAddToFridgeBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            AppColors.cream.withValues(alpha: 0),
            AppColors.cream,
          ],
          stops: const <double>[0.0, 0.3],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                onTap: onPressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.kitchen_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'Ajouter à mon frigo',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
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
    );
  }
}
