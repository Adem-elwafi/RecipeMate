import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/core/theme/app_text_styles.dart';
import 'package:recipemate/shared/widgets/app_buttons.dart';
import 'package:recipemate/shared/widgets/app_text_field.dart';

/// Form screen to create a custom recipe (Owner: Farah).
class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _cookTimeController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    super.dispose();
  }

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recette enregistrée avec succès ! 🎉')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Créer une recette',
          style: AppTextStyles.title.copyWith(fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          AppTextField(
            controller: _titleController,
            labelText: 'Titre de la recette',
            hintText: 'ex. Pâtes fraîches au pesto maison',
          ),
          const SizedBox(height: 18),
          AppTextField(
            controller: _descController,
            labelText: 'Description',
            hintText: 'Une courte présentation appétissante...',
            maxLines: 3,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  controller: _prepTimeController,
                  labelText: 'Préparation (min)',
                  hintText: '15',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AppTextField(
                  controller: _cookTimeController,
                  labelText: 'Cuisson (min)',
                  hintText: '20',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            label: 'Enregistrer la recette',
            isFullWidth: true,
            icon: Icons.check_circle_outline_rounded,
            onPressed: _save,
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Module développé par Farah',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
