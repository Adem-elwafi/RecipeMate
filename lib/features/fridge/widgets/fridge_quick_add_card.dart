import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:recipemate/core/models/fridge_item.dart';
import 'package:recipemate/core/models/ingredient.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/features/fridge/providers/fridge_provider.dart';

/// Quick-add card allowing rapid ingredient entry, suggestions, and barcode scan.
class FridgeQuickAddCard extends StatefulWidget {
  const FridgeQuickAddCard({
    required this.onAddItem,
    required this.onScanPressed,
    super.key,
  });

  final ValueChanged<FridgeItem> onAddItem;
  final VoidCallback onScanPressed;

  @override
  State<FridgeQuickAddCard> createState() => _FridgeQuickAddCardState();
}

class _FridgeQuickAddCardState extends State<FridgeQuickAddCard> {
  final TextEditingController _nameController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  Ingredient? _selectedSuggestion;
  double _quantity = 2;
  String _unit = 'pièce';
  bool _hasExpirationDate = true;
  late DateTime _expirationDate;

  @override
  void initState() {
    super.initState();
    _expirationDate = _defaultExpirationDate();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  DateTime _defaultExpirationDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 5);
  }

  List<Ingredient> _filteredSuggestions() {
    final query = normalizeIngredientName(_nameController.text);
    if (query.isEmpty) {
      return kFridgeIngredientSuggestions.take(6).toList();
    }

    final startsWith = <Ingredient>[];
    final contains = <Ingredient>[];

    for (final suggestion in kFridgeIngredientSuggestions) {
      final normalized = normalizeIngredientName(suggestion.name);
      if (normalized.startsWith(query)) {
        startsWith.add(suggestion);
      } else if (normalized.contains(query)) {
        contains.add(suggestion);
      }
    }

    return [...startsWith, ...contains].take(6).toList();
  }

  void _onQueryChanged(String value) {
    setState(() {
      if (_selectedSuggestion != null &&
          normalizeIngredientName(value) !=
              normalizeIngredientName(_selectedSuggestion!.name)) {
        _selectedSuggestion = null;
      }
    });
  }

  void _selectSuggestion(Ingredient suggestion) {
    setState(() {
      _selectedSuggestion = suggestion;
      _nameController
        ..text = suggestion.name
        ..selection = TextSelection.collapsed(offset: suggestion.name.length);
      _unit = suggestion.defaultUnit;
      _quantity = switch (suggestion.defaultUnit) {
        'g' => 200,
        'ml' => 250,
        'boîte' => 1,
        _ => 2,
      };
    });
  }

  double _stepForUnit(String unit) =>
      (unit == 'g' || unit == 'ml') ? 50.0 : 1.0;

  void _decrementQuantity() {
    final step = _stepForUnit(_unit);
    setState(() {
      _quantity = (_quantity - step).clamp(step, 9999.0);
    });
  }

  void _incrementQuantity() {
    final step = _stepForUnit(_unit);
    setState(() {
      _quantity = (_quantity + step).clamp(step, 9999.0);
    });
  }

  void _cycleUnit() {
    final currentIndex = kFridgeUnitOptions.indexOf(_unit);
    final nextUnit =
        kFridgeUnitOptions[(currentIndex + 1) % kFridgeUnitOptions.length];
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

  Future<void> _pickExpirationDate() async {
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

  void _toggleNoDate() {
    setState(() {
      _hasExpirationDate = !_hasExpirationDate;
    });
  }

  IngredientCategory _inferCategory(String name) {
    final normalized = normalizeIngredientName(name);
    const vegetableKeywords = [
      'tomate',
      'carotte',
      'courgette',
      'courge',
      'salade',
      'oignon',
      'ail',
      'pomme de terre',
      'brocoli',
      'poivron',
      'concombre',
      'epinard',
      'haricot',
      'champignon',
      'aubergine',
      'chou',
      'radis',
      'poireau',
    ];
    const fruitKeywords = [
      'pomme',
      'banane',
      'fraise',
      'citron',
      'orange',
      'poire',
      'mangue',
      'raisin',
      'avocat',
      'kiwi',
      'framboise',
      'myrtille',
      'cerise',
      'peche',
      'fruit',
    ];
    const meatKeywords = [
      'poulet',
      'boeuf',
      'dinde',
      'porc',
      'jambon',
      'steak',
      'lardon',
      'canard',
      'agneau',
      'viande',
    ];
    const fishKeywords = [
      'saumon',
      'thon',
      'cabillaud',
      'crevette',
      'poisson',
      'truite',
      'sardine',
    ];
    const dairyKeywords = [
      'lait',
      'yaourt',
      'fromage',
      'beurre',
      'creme',
      'feta',
      'mozzarella',
      'parmesan',
      'oeuf',
    ];

    if (vegetableKeywords.any(normalized.contains)) {
      return IngredientCategory.vegetables;
    }
    if (fruitKeywords.any(normalized.contains)) {
      return IngredientCategory.fruits;
    }
    if (meatKeywords.any(normalized.contains)) {
      return IngredientCategory.meat;
    }
    if (fishKeywords.any(normalized.contains)) {
      return IngredientCategory.fish;
    }
    if (dairyKeywords.any(normalized.contains)) {
      return IngredientCategory.dairy;
    }
    return IngredientCategory.other;
  }

  void _handleAdd() {
    final trimmed = _nameController.text.trim();
    if (trimmed.isEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text("Veuillez saisir le nom d'un ingrédient."),
          ),
        );
      return;
    }

    final normalizedInput = normalizeIngredientName(trimmed);
    Ingredient? matchedSuggestion;

    if (_selectedSuggestion != null &&
        normalizeIngredientName(_selectedSuggestion!.name) == normalizedInput) {
      matchedSuggestion = _selectedSuggestion;
    } else {
      for (final suggestion in kFridgeIngredientSuggestions) {
        if (normalizeIngredientName(suggestion.name) == normalizedInput) {
          matchedSuggestion = suggestion;
          break;
        }
      }
    }

    final displayName = trimmed[0].toUpperCase() + trimmed.substring(1);
    final ingredient =
        matchedSuggestion ??
        Ingredient(
          id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
          name: displayName,
          category: _inferCategory(trimmed),
          defaultUnit: _unit,
        );

    final newItem = FridgeItem(
      id: 'fi_${DateTime.now().microsecondsSinceEpoch}',
      ingredient: ingredient,
      quantity: _quantity,
      unit: _unit,
      expirationDate: _expirationDate,
      hasExpirationDate: _hasExpirationDate,
    );

    widget.onAddItem(newItem);

    FocusScope.of(context).unfocus();
    setState(() {
      _nameController.clear();
      _selectedSuggestion = null;
      _quantity = 2;
      _unit = 'pièce';
      _hasExpirationDate = true;
      _expirationDate = _defaultExpirationDate();
    });

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text('${ingredient.name} ajouté au frigo')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _filteredSuggestions();
    final query = normalizeIngredientName(_nameController.text);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ajouter un ingrédient',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Ingredient search & entry field
          SizedBox(
            height: 50,
            child: TextField(
              controller: _nameController,
              onChanged: _onQueryChanged,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleAdd(),
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: "Nom de l'ingrédient",
                hintStyle: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.textMuted,
                ),
                filled: true,
                fillColor: AppColors.card,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
                suffixIcon: _nameController.text.isNotEmpty
                    ? IconButton(
                        tooltip: 'Effacer',
                        onPressed: () {
                          _nameController.clear();
                          _onQueryChanged('');
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < suggestions.length; i++)
                  _SuggestionChip(
                    label: suggestions[i].name,
                    isSelected: _selectedSuggestion != null
                        ? _selectedSuggestion!.id == suggestions[i].id
                        : (query.isNotEmpty && i == 0),
                    onTap: () => _selectSuggestion(suggestions[i]),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Quantity & Expiration controls
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quantité',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _StepperIconButton(
                            icon: Icons.remove_rounded,
                            tooltip: 'Diminuer',
                            backgroundColor: AppColors.card,
                            foregroundColor: AppColors.textPrimary,
                            onPressed: _decrementQuantity,
                          ),
                          Expanded(
                            child: Tooltip(
                              message: "Changer d'unité",
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: _cycleUnit,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    child: Text(
                                      formatFridgeQuantity(_quantity, _unit),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                          ),
                          _StepperIconButton(
                            icon: Icons.add_rounded,
                            tooltip: 'Augmenter',
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            onPressed: _incrementQuantity,
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            'Expiration',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: _toggleNoDate,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              _hasExpirationDate ? 'Sans date' : 'Avec date',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Material(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _pickExpirationDate,
                        child: Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _hasExpirationDate
                                      ? _dateFormat.format(_expirationDate)
                                      : 'Sans date',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _hasExpirationDate
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action buttons: Add + Scanner
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _handleAdd,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(
                      'Ajouter',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: widget.onScanPressed,
                    icon: const Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 18,
                      color: AppColors.tonalGreenText,
                    ),
                    label: Text(
                      'Scanner',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.tonalGreenText,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.card,
                      foregroundColor: AppColors.tonalGreenText,
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      side: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.softGreen : AppColors.cream,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SizedBox(
            height: 34,
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.tonalGreenText
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepperIconButton extends StatelessWidget {
  const _StepperIconButton({
    required this.icon,
    required this.tooltip,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
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
              child: Icon(icon, size: 18, color: foregroundColor),
            ),
          ),
        ),
      ),
    );
  }
}
