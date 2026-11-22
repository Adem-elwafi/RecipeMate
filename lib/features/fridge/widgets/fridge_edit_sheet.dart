import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:recipemate/core/models/fridge_item.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/features/fridge/providers/fridge_provider.dart';

/// Opens a modal bottom sheet to edit a [FridgeItem]'s quantity, unit, or date.
Future<FridgeItem?> showFridgeEditSheet(
  BuildContext context, {
  required FridgeItem item,
}) {
  return showModalBottomSheet<FridgeItem>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => _FridgeEditSheetContent(item: item),
  );
}

class _FridgeEditSheetContent extends StatefulWidget {
  const _FridgeEditSheetContent({required this.item});

  final FridgeItem item;

  @override
  State<_FridgeEditSheetContent> createState() =>
      _FridgeEditSheetContentState();
}

class _FridgeEditSheetContentState extends State<_FridgeEditSheetContent> {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  late double _quantity;
  late String _unit;
  late DateTime _expirationDate;
  late bool _hasExpirationDate;
  late List<String> _unitOptions;

  @override
  void initState() {
    super.initState();
    _quantity = widget.item.quantity;
    _unit = widget.item.unit;
    _expirationDate = widget.item.expirationDate;
    _hasExpirationDate = widget.item.hasExpirationDate;
    _unitOptions = [
      ...kFridgeUnitOptions,
      if (!kFridgeUnitOptions.contains(widget.item.unit)) widget.item.unit,
    ];
  }

  double _stepForUnit(String unit) =>
      (unit == 'g' || unit == 'ml') ? 50.0 : 1.0;

  void _decrement() {
    final step = _stepForUnit(_unit);
    setState(() {
      _quantity = (_quantity - step).clamp(step, 9999.0);
    });
  }

  void _increment() {
    final step = _stepForUnit(_unit);
    setState(() {
      _quantity = (_quantity + step).clamp(step, 9999.0);
    });
  }

  void _selectUnit(String nextUnit) {
    if (_unit == nextUnit) {
      return;
    }
    setState(() {
      final wasBulk = _unit == 'g' || _unit == 'ml';
      final isBulk = nextUnit == 'g' || nextUnit == 'ml';
      _unit = nextUnit;
      if (!wasBulk && isBulk && _quantity < 50) {
        _quantity = nextUnit == 'g' ? 200 : 250;
      } else if (wasBulk && !isBulk && _quantity >= 20) {
        _quantity = nextUnit == 'boîte' ? 1 : 2;
      }
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1);
    final lastDate = DateTime(now.year + 5);
    final initial = _expirationDate.isBefore(firstDate)
        ? now
        : _expirationDate.isAfter(lastDate)
        ? lastDate
        : _expirationDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: "Date d'expiration",
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );

    if (picked != null && mounted) {
      setState(() {
        _expirationDate = DateTime(picked.year, picked.month, picked.day);
        _hasExpirationDate = true;
      });
    }
  }

  void _save() {
    final updated = widget.item.copyWith(
      quantity: _quantity,
      unit: _unit,
      expirationDate: _expirationDate,
      hasExpirationDate: _hasExpirationDate,
    );
    Navigator.of(context).pop(updated);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.sheetHandle,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Modifier ${widget.item.ingredient.name}',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.item.ingredient.category.label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // Quantity stepper
            Text(
              'Quantité',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _SheetStepperButton(
                    icon: Icons.remove_rounded,
                    tooltip: 'Diminuer',
                    backgroundColor: AppColors.card,
                    iconColor: AppColors.textPrimary,
                    onPressed: _decrement,
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        formatFridgeQuantity(_quantity, _unit),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  _SheetStepperButton(
                    icon: Icons.add_rounded,
                    tooltip: 'Augmenter',
                    backgroundColor: AppColors.primary,
                    iconColor: Colors.white,
                    onPressed: _increment,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Unit selection
            Text(
              'Unité',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final unitOption in _unitOptions)
                  ChoiceChip(
                    label: Text(
                      unitOption,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _unit == unitOption
                            ? AppColors.tonalGreenText
                            : AppColors.textPrimary,
                      ),
                    ),
                    selected: _unit == unitOption,
                    showCheckmark: false,
                    selectedColor: AppColors.softGreen,
                    backgroundColor: AppColors.cream,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onSelected: (_) => _selectUnit(unitOption),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Expiration date + no-date toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    "Date d'expiration",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _hasExpirationDate = !_hasExpirationDate;
                    });
                  },
                  child: Text(
                    _hasExpirationDate
                        ? 'Marquer sans date'
                        : 'Définir une date',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            Material(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _pickDate,
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _hasExpirationDate
                              ? _dateFormat.format(_expirationDate)
                              : 'Sans date',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _hasExpirationDate
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Footer buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.chipBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Annuler',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Enregistrer',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
    );
  }
}

class _SheetStepperButton extends StatelessWidget {
  const _SheetStepperButton({
    required this.icon,
    required this.tooltip,
    required this.backgroundColor,
    required this.iconColor,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, size: 18, color: iconColor),
          ),
        ),
      ),
    );
  }
}
