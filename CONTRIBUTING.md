# Guide de Contribution - RecipeMate 🍳🌱

Bienvenue dans l'équipe de développement de **RecipeMate** ! Ce guide définit nos standards de développement, de branching, de commits et de revue de code pour garantir une collaboration fluide et de haute qualité.

---

## 1. Stratégie de Branches (Git Flow)

- `main` : Branche de production, toujours stable et prête à être déployée.
- `develop` : Branche d'intégration principale. Toutes les fonctionnalités y convergent.
- `feature/<owner>-<nom>` : Branche de fonctionnalité isolée.
  - Exemples :
    - `feature/adem-fridge-list`
    - `feature/molka-home-header`
    - `feature/farah-auth-login`
- `fix/<owner>-<nom>` : Branche de correction de bug.

### Cycle d'une branche
1. Créer la branche à partir de `develop` :
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/adem-fridge-list
   ```
2. Développer, tester localement et valider avec `flutter analyze` et `flutter test`.
3. Pousser vers GitHub et ouvrir une Pull Request vers `develop`.
4. Après revue et passage des tests CI, fusionner (Squash & Merge ou Rebase).

---

## 2. Convention de Commits (Conventional Commits)

Les messages de commits doivent suivre le format :
`<type>(<portée>): <description>`

### Types acceptés :
- `feat` : Nouvelle fonctionnalité visible pour l'utilisateur.
- `fix` : Correction d'une anomalie.
- `refactor` : Amélioration du code sans modification fonctionnelle.
- `docs` : Modification de la documentation (README, guides, commentaires).
- `test` : Ajout ou correction de tests.
- `chore` : Tâches d'infrastructure, configuration ou dépendances.

### Exemples :
- `feat(fridge): ajouter le filtre anti-gaspillage par péremption`
- `fix(auth): corriger la validation du format de mot de passe`
- `test(recipe): ajouter les tests unitaires sur les macros nutritionnelles`

---

## 3. Règles d'Architecture & Code

1. **Langue de l'interface** : Tous les libellés de l'interface utilisateur sont en **français** (les noms de variables, fonctions et classes restent en anglais standard).
2. **Design Tokens** : Toujours utiliser `AppColors` et `AppTextStyles` définis dans `lib/core/theme/`. Ne pas coder de couleurs hexadécimales en dur.
3. **Gestion d'état** : Riverpod (`NotifierProvider`, `StateNotifierProvider` ou `AsyncNotifierProvider`).
4. **Navigation** : GoRouter centralisé dans `lib/core/router/app_router.dart`.
5. **Validation locale avant PR** :
   ```bash
   dart format --set-exit-if-changed .
   flutter analyze
   flutter test
   ```

---

## 4. Attribution des Écrans et Modules

| Responsable | Features & Chemins | Écrans Clés |
|---|---|---|
| **Adem** | `fridge`, `scanner`, `product`, `recommendations` | Mon frigo, Scanner code-barres, Fiche produit, Recettes IA |
| **Molka** | `home`, `explore`, `recipe_details`, `cooking_mode` | Accueil, Explorer & recherche, Détail de la recette, Mode cuisine |
| **Farah** | `onboarding`, `auth`, `profile`, `favorites`, `collections`, `add_recipe` | Onboarding, Connexion/Inscription, Profil, Favoris/Collections, Ajouter une recette |
| **Équipe (Shared)** | `core/`, `shared/` | Thème, Modèles de base, Navigation Bar, Routeur, Mock data |
