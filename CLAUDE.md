# CLAUDE.md — Instructions for Claude Code & Assistants

Refer to `AGENTS.md` for full repository rules.

## Key Rules
- **UI Language**: French (fr-FR) for all user-facing strings.
- **Design System**: Material 3 tokens via `lib/core/theme/` (`AppColors`, `AppTextStyles`, `AppTheme`).
- **Feature Ownership**:
  - Adem: `lib/features/fridge/`, `lib/features/scanner/`, `lib/features/product/`, `lib/features/recommendations/`
  - Molka: `lib/features/home/`, `lib/features/explore/`, `lib/features/recipe_details/`, `lib/features/cooking_mode/`
  - Farah: `lib/features/onboarding/`, `lib/features/auth/`, `lib/features/profile/`, `lib/features/favorites/`, `lib/features/collections/`, `lib/features/add_recipe/`
  - Shared: `lib/core/`, `lib/shared/`
- **State Management**: Riverpod (`flutter_riverpod`).
- **Routing**: `go_router` in `lib/core/router/app_router.dart`.
- **Quality**: `dart format .`, `flutter analyze` (0 errors), `flutter test` (all green).
