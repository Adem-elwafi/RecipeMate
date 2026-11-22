import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:recipemate/core/data/mock_data.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/core/theme/app_text_styles.dart';
import 'package:recipemate/shared/widgets/app_buttons.dart';
import 'package:recipemate/shared/widgets/app_text_field.dart';
import 'package:recipemate/shared/widgets/diet_badge.dart';
import 'package:recipemate/shared/widgets/macro_ring.dart';
import 'package:recipemate/shared/widgets/match_bar.dart';
import 'package:recipemate/shared/widgets/recipe_card.dart';

/// Interactive Playground to showcase and preview all Design System primitives.
class PlaygroundScreen extends StatefulWidget {
  const PlaygroundScreen({super.key});

  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen> {
  bool _isFavorite = true;
  String _inputText = '';
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        title: Text(
          'Playground des Composants',
          style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Banner intro
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Design System RecipeMate',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Voici la vitrine interactive de tous les widgets et jetons '
                  'prêts à l’emploi dans lib/shared/widgets/ et lib/core/theme/.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.softGreen,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // 1. PALETTE DE COULEURS
          _buildSectionHeader(
            title: '1. Couleurs (AppColors)',
            icon: Icons.palette_outlined,
          ),
          _buildColorsGrid(),
          const SizedBox(height: 28),

          // 2. TYPOGRAPHIE
          _buildSectionHeader(
            title: '2. Typographie (AppTextStyles)',
            icon: Icons.text_fields_rounded,
          ),
          _buildTypographyCard(),
          const SizedBox(height: 28),

          // 3. BOUTONS
          _buildSectionHeader(
            title: '3. Boutons (lib/shared/widgets/app_buttons.dart)',
            icon: Icons.smart_button_outlined,
          ),
          _buildButtonsCard(),
          const SizedBox(height: 28),

          // 4. CHAMPS DE SAISIE
          _buildSectionHeader(
            title: '4. Champs de Saisie (AppTextField)',
            icon: Icons.edit_note_rounded,
          ),
          _buildTextFieldsCard(),
          const SizedBox(height: 28),

          // 5. BADGES & RÉGIMES
          _buildSectionHeader(
            title: '5. Badges de Régime (DietBadge)',
            icon: Icons.local_offer_outlined,
          ),
          _buildBadgesCard(),
          const SizedBox(height: 28),

          // 6. ANNEAUX NUTRITIONNELS
          _buildSectionHeader(
            title: '6. Objectifs Nutritionnels (MacroRing)',
            icon: Icons.donut_large_rounded,
          ),
          _buildMacroRingsCard(),
          const SizedBox(height: 28),

          // 7. BARRE DE CORRESPONDANCE IA
          _buildSectionHeader(
            title: '7. Score de Correspondance IA (MatchBar)',
            icon: Icons.auto_awesome_motion_rounded,
          ),
          _buildMatchBarCard(),
          const SizedBox(height: 28),

          // 8. CARTE DE RECETTE
          _buildSectionHeader(
            title: '8. Carte de Recette (RecipeCard)',
            icon: Icons.restaurant_menu_rounded,
          ),
          _buildRecipeCardsSection(),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.subtitle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorsGrid() {
    final colors = [
      ('Primary', AppColors.primary, '#527C43'),
      ('Sage', AppColors.sage, '#A8C982'),
      ('Soft Green', AppColors.softGreen, '#DDEBCB'),
      ('Crème (Fond)', AppColors.cream, '#F5F2E9'),
      ('Carte (Surface)', AppColors.card, '#FFFFFF'),
      ('Texte', AppColors.textPrimary, '#292D27'),
      ('Texte Second.', AppColors.textSecondary, '#5E6457'),
      ('Gris Icônes', AppColors.greyIcon, '#858B7D'),
      ('Orange Accent', AppColors.orangeAccent, '#E9A65A'),
      ('Orange Texte', AppColors.orangeText, '#9A5A12'),
      ('Erreur', AppColors.error, '#B3261E'),
      ('Erreur Fond', AppColors.errorContainer, '#FBEDEB'),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: colors.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.85,
        ),
        itemBuilder: (context, index) {
          final (name, color, hex) = colors[index];
          final isLight = color.computeLuminance() > 0.6;
          return Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isLight ? AppColors.borderSubtle : Colors.transparent,
              ),
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isLight ? AppColors.textPrimary : Colors.white,
                  ),
                ),
                Text(
                  hex,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: isLight ? AppColors.textSecondary : Colors.white70,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypographyCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Display · Poppins 32 bold', style: AppTextStyles.display),
          const Divider(height: 24),
          Text('Titre · Poppins 22 semibold', style: AppTextStyles.title),
          const Divider(height: 24),
          Text(
            'Sous-titre · Poppins 17 semibold',
            style: AppTextStyles.subtitle,
          ),
          const Divider(height: 24),
          Text(
            'Corps · Inter 15 — Une salade fraîche, croquante et riche en protéines.',
            style: AppTextStyles.body,
          ),
          const Divider(height: 24),
          Text('Légende · Inter 13 secondaire', style: AppTextStyles.caption),
          const Divider(height: 24),
          Text('LABEL / TAG · INTER 12 UPPERCASE', style: AppTextStyles.label),
        ],
      ),
    );
  }

  Widget _buildButtonsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryButton(
            label: 'Commencer à cuisiner (Primary)',
            icon: Icons.play_arrow_rounded,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Clic sur PrimaryButton !')),
              );
            },
          ),
          const SizedBox(height: 12),
          OutlineButtonWidget(
            label: 'Ajouter à la liste de courses (Outline)',
            icon: Icons.playlist_add_rounded,
            onPressed: () {},
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TonalButton(label: 'Bouton Tonal', onPressed: () {}),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: PrimaryButton(label: 'Désactivé', onPressed: null),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Bouton Favori interactif :', style: AppTextStyles.body),
              const Spacer(),
              FavoriteButton(
                isFavorite: _isFavorite,
                onToggle: () {
                  setState(() => _isFavorite = !_isFavorite);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: _textController,
            hintText: 'Rechercher une recette ou un ingrédient...',
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.primary,
            ),
            onChanged: (val) => setState(() => _inputText = val),
          ),
          if (_inputText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Texte saisi en temps réel : "$_inputText"',
              style: AppTextStyles.caption.copyWith(color: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadgesCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: const Wrap(
        spacing: 8,
        runSpacing: 10,
        children: [
          DietBadge(label: 'Healthy'),
          DietBadge(label: 'Végétarien'),
          DietBadge(label: 'Sans gluten'),
          DietBadge(label: 'Riche en protéines'),
          DietBadge(label: 'Moins de 20 min'),
          DietBadge(label: 'Anti-gaspillage'),
        ],
      ),
    );
  }

  Widget _buildMacroRingsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          MacroRing(
            label: 'Calories',
            current: 1428,
            target: 2100,
            unit: 'kcal',
            color: AppColors.primary,
          ),
          MacroRing(
            label: 'Protéines',
            current: 100,
            target: 135,
            unit: 'g',
            color: AppColors.sage,
          ),
          MacroRing(
            label: 'Glucides',
            current: 109,
            target: 210,
            unit: 'g',
            color: AppColors.orangeAccent,
          ),
          MacroRing(
            label: 'Lipides',
            current: 27,
            target: 65,
            unit: 'g',
            color: AppColors.greyIcon,
          ),
        ],
      ),
    );
  }

  Widget _buildMatchBarCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: const Column(
        children: [
          MatchBar(percentage: 0.90),
          SizedBox(height: 16),
          MatchBar(percentage: 0.65),
          SizedBox(height: 16),
          MatchBar(percentage: 0.35),
        ],
      ),
    );
  }

  Widget _buildRecipeCardsSection() {
    final sample1 = MockData.recipes[0];
    final sample2 = MockData.recipes[1];

    return SizedBox(
      height: 250,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            width: 190,
            child: RecipeCard(
              recipe: sample1,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Clic sur ${sample1.title}')),
                );
              },
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 190,
            child: RecipeCard(
              recipe: sample2,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Clic sur ${sample2.title}')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
