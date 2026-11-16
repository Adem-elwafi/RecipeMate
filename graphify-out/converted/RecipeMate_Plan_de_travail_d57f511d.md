<!-- converted from RecipeMate_Plan_de_travail.docx -->

RecipeMate – Plan de travail
Équipe : Nyhel, Molka, Farah · Application Flutter (Android & iOS)
# Le principe
On découpe l'application par fonctionnalités, et non par couches techniques (une personne pour les écrans, une pour Firebase, une pour l'API). Chacun de nous construit sa partie de bout en bout : écrans, logique et base de données. Ainsi, tout le monde apprend Flutter, la gestion d'état, Firebase et les tests.
Le plan est organisé en étapes : on passe à la suivante quand la précédente est terminée, quel que soit le temps que cela prend.
# Étape 1 – Les fondations, ensemble
On fait cette étape à trois avant de se répartir le travail :
- Créer le projet Flutter et le dépôt GitHub ; se mettre d’accord sur l’organisation des dossiers et sur la gestion d’état (Riverpod ou Provider).
- Coder le thème : couleurs, polices (Poppins et Inter), arrondis, mode clair et mode sombre.
- Construire les widgets partagés : RecipeCard, MacroRing, DietBadge, les boutons, les champs de saisie et la barre de navigation.
- Définir les modèles de données (Recipe, Ingredient, FridgeItem, UserProfile) et la structure Firestore, puis ajouter quelques recettes d’exemple.
Étape terminée quand : l'application se lance avec la barre de navigation, le thème et une liste de recettes d'exemple.
# Étape 2 – Chacun sa partie

Chacun commence avec des données d'exemple, puis branche Firebase.
Étape terminée quand : les écrans de chacun fonctionnent de manière autonome.
# Étape 3 – Relier les parties
- Mon frigo → Recettes IA → Détail de la recette → Mode cuisine.
- Les favoris (partie de Farah) s’affichent dans les écrans de Molka.
- Le matching IA utilise les allergies et les régimes du profil (partie de Farah).
Étape terminée quand : on peut parcourir toute l'application, de la connexion jusqu'au mode cuisine.
# Étape 4 – Finitions
- Ajouter les états de chargement, les états vides et les messages d’erreur.
- Tester sur un vrai téléphone et corriger les bugs.
- Préparer la présentation.
# Pendant tout le projet
- Une branche par fonctionnalité. Chaque pull request est relue et validée par un autre membre de l’équipe : c’est en lisant le code des autres qu’on apprend leur partie.
- Une courte démo régulière. Chaque membre montre son avancement et explique une chose apprise.
- Un échange de tâche au milieu du projet. Par exemple, Molka ajoute le bandeau « ingrédients manquants » qui utilise les données du frigo de Adem.
- Du travail en binôme sur les parties difficiles : l’algorithme de matching, la connexion Google et le scanner.
## Points à fixer dès l’étape 1
- Le modèle de recette (Molka) est utilisé par tout le monde : on le définit ensemble.
- Les favoris passent par une fonction commune, par exemple toggleFavorite(recipeId).
- Les champs du profil (allergies, régimes, objectifs nutritionnels) sont fixés avant que Adem code le matching.
| Membre | Écrans | Ce qu'on apprend |
| --- | --- | --- |
| Adem
Frigo & IA | Mon frigo
Scanner code-barres
Fiche produit
Recettes IA (score de correspondance) | Firestore (lecture / écriture)
Caméra et scan
API OpenFoodFacts
Logique de matching |
| Molka
Recettes | Accueil
Explorer (recherche, filtres, tri)
Détail de la recette
Mode cuisine | Requêtes et filtres Firestore
Calcul des portions
Minuteur
Beaucoup de travail UI |
| Farah
Compte & bibliothèque | Splash et onboarding
Connexion / inscription
Profil et réglages
Favoris et collections
Ajouter une recette | Firebase Auth + Google
Formulaires et validation
Upload photo (Firebase Storage)
Thème sombre |