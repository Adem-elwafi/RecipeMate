# RecipeMate 🍳🌱

> **Application mobile intelligente anti-gaspillage & cuisine saine.**  
> *Smart anti-waste and healthy cooking mobile application.*

---

## 🇫🇷 Français

### Présentation
**RecipeMate** est une application mobile Flutter conçue pour transformer la façon dont nous gérons nos aliments et cuisinons au quotidien. Grâce à un suivi intelligent du réfrigérateur avec alertes de péremption, un scanner de code-barres alimentaire, un moteur de recommandation anti-gaspi calculant le taux de correspondance des ingrédients et un mode cuisine pas-à-pas, RecipeMate aide à manger sainement tout en réduisant le gaspillage alimentaire.

### Fonctionnalités Clés
- **Mon Frigo & Anti-Gaspi** : Gestion des ingrédients en stock, tri par date de péremption et alertes visuelles ("Expire bientôt").
- **Scanner Code-barres & Fiche Produit** : Scan instantané des emballages, fiche nutritionnelle détaillée (Nutri-Score, Eco-Score, Nova) et ajout direct au frigo.
- **Recettes IA & Match d'Ingrédients** : Suggestions de recettes intelligentes classées par pourcentage d'ingrédients déjà possédés.
- **Mode Cuisine Interactif** : Interface optimisée plein écran avec étapes pas à pas, minuteurs intégrés et suivi des gestes.
- **Profil & Nutrition** : Suivi des macronutriments (Calories, Protéines, Glucides, Lipides), objectifs personnalisés et régimes (Végétarien, Sans gluten, etc.).

---

## 🇬🇧 English

### Overview
**RecipeMate** is a modern Flutter mobile app designed to revolutionize home cooking and reduce food waste. Featuring an intelligent fridge manager with expiration alerts, a barcode scanner with OpenFoodFacts integration, smart recipe matching based on existing pantry items, and an immersive step-by-step cooking mode.

### Key Features
- **Smart Fridge & Anti-Waste**: Track stored ingredients, expiration dates, and get timely alerts for expiring items.
- **Barcode Scanner**: Scan products, view nutritional scores (Nutri-Score, Eco-Score, Nova), and add them to the fridge in one tap.
- **AI Recommendations & Match Bar**: Suggest recipes sorted by available ingredient match rate.
- **Interactive Cooking Mode**: Distraction-free step-by-step cooking interface with built-in timers.
- **Personalized Nutrition & Diets**: Track daily macros (Calories, Protein, Carbs, Fat) and filter by diet badges.

---

## 🎨 Design System & Référence
L'intégralité du design suit **Material 3** avec une palette organique moderne inspirée de la nature.
- **Spécification de référence** : [`docs/design/RecipeMate.html`](docs/design/RecipeMate.html)
- **Couleurs principales** :
  - `Primary` : `#527C43` (Vert feuille)
  - `Sage` : `#A8C982` (Sauge)
  - `Soft Green` : `#DDEBCB` (Vert doux pour jauges et fonds clairs)
  - `Crème` : `#F5F2E9` (Fond d'application chaleureux)
  - `Orange Accent` : `#E9A65A` / `#9A5A12` (Alertes péremption)
- **Typographie** : **Poppins** (Titres, En-têtes) & **Inter** (Corps, Boutons, Libellés).

---

## 🏗️ Architecture du Projet

```text
lib/
├── core/
│   ├── data/            # Données mockées haute fidélité (mock_data.dart)
│   ├── models/          # Entités métier (recipe, ingredient, fridge_item, user_profile)
│   ├── router/          # Configuration GoRouter (app_router.dart)
│   └── theme/           # AppColors, AppTextStyles, AppTheme (Material 3)
├── features/
│   ├── add_recipe/      # Écran d'ajout de recette personnalisée (Farah)
│   ├── auth/            # Écrans de connexion & inscription (Farah)
│   ├── collections/     # Gestion des dossiers & collections (Farah)
│   ├── cooking_mode/    # Mode cuisine pas à pas plein écran (Molka)
│   ├── explore/         # Recherche, catégories & filtres de recettes (Molka)
│   ├── favorites/       # Liste des recettes favorites sauvegardées (Farah)
│   ├── fridge/          # Gestion du frigo, stocks & péremptions (Adem)
│   ├── home/            # Tableau de bord principal, macros & suggestions (Molka)
│   ├── onboarding/      # Parcours d'accueil en 3 étapes (Farah)
│   ├── product/         # Fiche produit détaillée scannée (Adem)
│   ├── profile/         # Profil utilisateur, régimes & objectifs (Farah)
│   ├── recipe_details/  # Fiche complète d'une recette (Molka)
│   ├── recommendations/ # Suggestions IA anti-gaspi & match (Adem)
│   └── scanner/         # Scanner de code-barres caméra (Adem)
├── shared/
│   └── widgets/         # RecipeCard, MatchBar, MacroRing, DietBadge, AppButtons...
└── main.dart            # Point d'entrée de l'application (ProviderScope)
```

---

## 👥 Équipe & Attribution des Modules

| Membre | Rôle & Responsabilité | Dossiers sous `lib/features/` |
|---|---|---|
| **Adem** | Frigo, Scanner, Fiche Produit, Recettes IA & Core Foundation | `fridge/`, `scanner/`, `product/`, `recommendations/`, `core/`, `shared/` |
| **Molka** | Accueil, Explorer, Détail de la Recette, Mode Cuisine | `home/`, `explore/`, `recipe_details/`, `cooking_mode/` |
| **Farah** | Onboarding, Authentification, Profil, Favoris, Collections, Ajout Recette | `onboarding/`, `auth/`, `profile/`, `favorites/`, `collections/`, `add_recipe/` |

---

## 🚀 Démarrage Rapide

### Prérequis
- Flutter SDK `^3.13.5` ou supérieur (`flutter --version`)
- Dart SDK `^3.13.5`
- Android Studio / Xcode / VS Code avec extension Flutter

### Installation & Lancement
```bash
# 1. Cloner le dépôt
git clone https://github.com/Adem-elwafi/RecipeMate.git
cd RecipeMate

# 2. Installer les dépendances
flutter pub get

# 3. Vérifier le formatage et l'analyse statique
dart format --set-exit-if-changed .
flutter analyze

# 4. Exécuter les tests
flutter test

# 5. Lancer l'application
flutter run
```
