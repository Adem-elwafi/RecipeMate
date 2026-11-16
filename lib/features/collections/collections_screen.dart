import 'package:flutter/material.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/core/theme/app_text_styles.dart';

/// Recipe collections / folders screen (Owner: Farah).
class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key});

  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}

class _CollectionsScreenState extends State<CollectionsScreen> {
  final List<Map<String, dynamic>> _collections = [
    {
      'id': 'col_1',
      'title': 'Dîners rapides (< 20 min)',
      'count': 6,
      'icon': Icons.bolt_rounded,
      'color': AppColors.orangeAccent,
    },
    {
      'id': 'col_2',
      'title': 'Plats riches en protéines',
      'count': 4,
      'icon': Icons.fitness_center_rounded,
      'color': AppColors.primary,
    },
    {
      'id': 'col_3',
      'title': 'Batch cooking du dimanche',
      'count': 8,
      'icon': Icons.all_inbox_rounded,
      'color': AppColors.info,
    },
  ];

  void _deleteCollection(int index) {
    setState(() {
      _collections.removeAt(index);
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Collection supprimée')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mes Collections',
          style: AppTextStyles.title.copyWith(fontSize: 20),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _collections.length,
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final col = _collections[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (col['color'] as Color).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    col['icon'] as IconData,
                    color: col['color'] as Color,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        col['title'] as String,
                        style: AppTextStyles.subtitle.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${col['count']} recettes',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                  onPressed: () => _deleteCollection(index),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Création de collection (Farah - Phase 2)'),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Nouvelle collection', style: AppTextStyles.buttonSmall),
      ),
    );
  }
}
