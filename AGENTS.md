# AGENTS.md — Single Source of Truth for AI Assistants

This repository is **RecipeMate**, an intelligent anti-waste & healthy cooking Flutter mobile application built with Material 3 and Riverpod.

Any AI assistant (Antigravity, Cursor, Claude Code, Copilot, Codex, etc.) working on this repository **MUST** adhere to the rules and guidelines specified below.

---

## 1. Core Principles & UI Language

1. **French UI Language Requirement**:
   - ALL user-facing strings, error messages, placeholders, titles, and labels MUST be written in **French** (fr-FR).
   - Code identifiers (classes, variables, methods, file names, comments) remain in **English**.
   - Example: Button text is `"Ajouter au frigo"`, method is `addToFridge()`.

2. **Material 3 Design Tokens (M3)**:
   - Always reference design tokens in `lib/core/theme/` (`AppColors`, `AppTextStyles`, `AppTheme`).
   - NEVER hardcode hex colors in widgets or styles.
   - Primary: `AppColors.primary` (`#527C43`)
   - Sage: `AppColors.sage` (`#A8C982`)
   - Soft Green: `AppColors.softGreen` (`#DDEBCB`)
   - Cream / Background: `AppColors.cream` (`#F5F2E9`)
   - Card / Surface: `AppColors.card` (`#FFFFFF`)
   - Text Primary: `AppColors.textPrimary` (`#292D27`)
   - Text Secondary: `AppColors.textSecondary` (`#5E6457`)
   - Expiration Warning: `AppColors.orangeAccent` (`#E9A65A`), `AppColors.orangeText` (`#9A5A12`)
   - Error: `AppColors.error` (`#B3261E`), `AppColors.errorContainer` (`#FBEDEB`)
   - Fonts: Poppins for headings/titles, Inter for body/captions/buttons.
   - Corner Radii: 12px (small), 16px (medium cards), 24px/28px (dialogs, large containers, bottom sheets).

---

## 2. Architecture & Ownership Boundaries

Each team member owns specific feature domains under `lib/features/`:

| Feature Directory | Owner | Responsibilities |
|---|---|---|
| `lib/features/fridge/` | **Adem** | Fridge item listing, expiration sorting, quantity editing, consumed/wasted actions |
| `lib/features/scanner/` | **Adem** | Camera barcode scanner with mobile_scanner, manual barcode fallback |
| `lib/features/product/` | **Adem** | Product details from barcode (OpenFoodFacts), nutriscore, add to fridge |
| `lib/features/recommendations/` | **Adem** | AI anti-waste suggestions, recipe match calculation against fridge stock |
| `lib/features/home/` | **Molka** | Dashboard, daily macro trackers, quick recipes, expiring soon banner |
| `lib/features/explore/` | **Molka** | Search recipes, category filters, diet filters, empty states |
| `lib/features/recipe_details/` | **Molka** | Full recipe screen, ingredients check, instructions list, start cooking button |
| `lib/features/cooking_mode/` | **Molka** | Immersive full-screen step-by-step cooking, step timers, complete flow |
| `lib/features/onboarding/` | **Farah** | 3-step carousel with skip, next, start buttons |
| `lib/features/auth/` | **Farah** | Login, registration, password validation, error feedback |
| `lib/features/profile/` | **Farah** | Profile info, diet choices, nutritional daily goals (calories, protein, carbs, fat) |
| `lib/features/favorites/` | **Farah** | Saved favorite recipes list, toggle favorite |
| `lib/features/collections/` | **Farah** | Custom recipe folders/collections, create collection, delete collection |
| `lib/features/add_recipe/` | **Farah** | Custom recipe creation form with ingredient and step inputs |
| `lib/core/` & `lib/shared/` | **Shared** | Foundation, routing, shared UI widgets, models, mock data |

**Rule**: Do NOT modify another owner's feature code without an explicit request or coordination. Keep shared code inside `lib/core/` and `lib/shared/`.

---

## 3. State Management & Code Style

1. **Riverpod 2.x**:
   - Use `flutter_riverpod`.
   - Prefer `Notifier` / `AsyncNotifier` (or `StateNotifier` where appropriate).
   - Use `ConsumerWidget` or `ConsumerStatefulWidget` to read providers via `WidgetRef`.
   - Do NOT use raw setState for cross-screen or domain data.

2. **Navigation**:
   - Centralized in `lib/core/router/app_router.dart` using `go_router`.
   - Use typed route paths and parameters.
   - Main bottom bar uses `StatefulShellRoute.indexedStack`.

3. **Linter & Quality**:
   - Code must satisfy `very_good_analysis` rules defined in `analysis_options.yaml`.
   - Always run `dart format .` before committing.
   - `flutter analyze` must return **0 errors and 0 warnings**.
   - Every model must have unit tests, and every shared widget must have widget tests.

---

## 4. Graphify Knowledge Graph

This project has a graphify knowledge graph at `graphify-out/`.

Rules:
- Before answering architecture or codebase questions, read `graphify-out/GRAPH_REPORT.md` for god nodes and community structure.
- If `graphify-out/wiki/index.md` exists, navigate it instead of reading raw files.
- For cross-module questions, prefer `graphify query "<question>"`, `graphify path "<A>" "<B>"`, or `graphify explain "<concept>"`.
- After modifying code files in any session, run `graphify update .` to keep the graph current.
