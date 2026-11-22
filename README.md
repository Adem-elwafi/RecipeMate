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

### Logo et écrans de lancement

Le logo RecipeMate est unique et partagé (les anciens placeholders Flutter ont été supprimés) :

- sources vectorielles : `assets/images/recipemate_logo.svg` (fond crème, splash), `assets/images/recipemate_mark.svg` (transparent, connexion/en-têtes/onboarding) et `assets/images/recipemate_logo_green.svg` (icône), déclarées dans `pubspec.yaml` ;
- splash Flutter : `lib/features/splash/splash_screen.dart` (`SvgPicture.asset(appSplashLogoAssetPath)`) ;
- écran de connexion et en-tête commun : `SvgPicture.asset(appLogoAssetPath)`, chemins centralisés dans `lib/core/config/app_assets.dart` ;
- icône de l'application : `assets/icon/icon.png` (1024×1024 généré depuis le SVG vert), puis `dart run flutter_launcher_icons` pour Android/iOS ;
- splash natif Android : source 1024×1024 dans `assets/icon/splash_logo.png`, déclinaisons `drawable-*/splash_logo.png` générées depuis `assets/images/recipemate_logo.svg`, affichées par `drawable/launch_background.xml` et `drawable-v21/launch_background.xml`. Le projet n'utilise pas `flutter_native_splash` : ces drawables sont donc mis à jour manuellement.

Si l'ancien logo Flutter réapparaît, vérifier ces emplacements puis désinstaller/réinstaller l'application (icône et splash natifs sont mis en cache dans le binaire Android).

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

### Configuration Google Sign-In (connexion avec Google)

La connexion Google utilise `google_sign_in ^7` et Firebase Authentication. Le code ne contient **aucun client ID en dur** : la configuration vient soit des fichiers natifs, soit des variables transmises au lancement.

1. **Fichiers natifs Firebase** :
   - Android : `android/app/google-services.json` (package `com.recipemate.recipemate`).
   - iOS : `ios/Runner/GoogleService-Info.plist` (à générer avec `flutterfire configure` : il n'est **pas encore versionné** dans ce dépôt).
   - Web : options déclarées dans `lib/firebase_options.dart`.
   - En cas de modification du projet Firebase, régénérer avec `flutterfire configure`.
   - **Point d'attention constaté sur mobile** : le `google-services.json` actuellement versionné a `"oauth_client": []`. Sans client OAuth de type Web, Google Sign-In 7 renvoie `clientConfigurationError`. Il faut télécharger à nouveau ce fichier depuis *Firebase Console → Paramètres du projet → Vos applications → Application Android → google-services.json* après l'étape 3 ci-dessous, ou fournir `GOOGLE_WEB_CLIENT_ID` via `--dart-define`. La console affiche un avertissement dédié (`[Google] Attention`) au premier lancement si rien n'est configuré.

2. **Activer le fournisseur Google** dans la console Firebase : *Authentication* → *Providers* → **Google** → Activer, puis enregistrer l'adresse e-mail de support.

3. **Enregistrer les empreintes SHA** dans les paramètres du projet Firebase ( *Project settings* → *Your apps* → *Android app* ) :
   - Debug :
     ```bash
     keytool -list -v -keystore "$HOME\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
     ```
   - Release (keystore de production fourni par l'équipe) :
     ```bash
     keytool -list -v -keystore "chemin\vers\recipemate-release.jks" -alias recipemate
     ```
   - Ajouter **SHA-1 et SHA-256** pour chaque environnement utilisé, puis télécharger le nouveau `google-services.json`.
   - Sur iOS, vérifier que le *Bundle ID* (`com.recipemate.recipemate`) est bien enregistré dans le projet Firebase.

4. **Client IDs (optionnels)** : si la configuration native est incomplète ou si vous testez un autre projet Firebase, transmettre les IDs au lancement :
   ```bash
   flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com \
              --dart-define=GOOGLE_IOS_CLIENT_ID=yyyy.apps.googleusercontent.com
   ```
   Sur Android, `GOOGLE_WEB_CLIENT_ID` sert de `serverClientId` (obligatoire pour obtenir le token d'identité) ; sur iOS, c'est `GOOGLE_IOS_CLIENT_ID` qui est utilisé comme `clientId`. Sans ces variables, le plugin lit automatiquement `google-services.json` / `GoogleService-Info.plist`.

5. **Diagnostic** : les exceptions Google/Firebase complètes sont écrites dans la console (`[Google/Firebase]`, `[Google]`, `[Auth]`) avec la pile d'appels. Les messages utilisateurs distinguent une annulation, une configuration client incomplète (SHA-1/SHA-256), un fournisseur désactivé et une erreur réseau.

### Données Firestore & Storage

- Règles à déployer : `firestore.rules` et `storage.rules` (`firebase deploy --only firestore:rules,storage`).
- Favoris : `users/{uid}/favorites/{recipeId}` avec `addedAt: serverTimestamp()`, bascule atomique par transaction.
- Collections : `users/{uid}/collections/{collectionId}` ; une recette peut être ajoutée à plusieurs collections en une seule écriture.
- Recettes : `recipes/{recipeId}` avec `authorId`, `isPublic`, `ingredientKeywords[]`, `category`, `difficulty`, `dietTags[]`, `fiberGrams`, `createdAt` serveur et `imageUrl` (Firebase Storage sous `recipe_images/{uid}/`). Si Storage n'est pas disponible, un repli Base64 est utilisé et tracé dans les logs.
- Rappels : notifications locales planifiées via `flutter_local_notifications`, historique dans `users/{uid}/reminders/{reminderId}` et produits suivis dans `users/{uid}/pantry/{itemId}`.
- Les allergies sont normalisées à la lecture et à l'écriture : une ancienne valeur `Guten` stockée dans Firestore s'affiche désormais `Gluten`.
