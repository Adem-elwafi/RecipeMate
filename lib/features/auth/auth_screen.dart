import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/core/theme/app_text_styles.dart';
import 'package:recipemate/shared/widgets/app_buttons.dart';
import 'package:recipemate/shared/widgets/app_text_field.dart';

/// Authentication screen with Login and Register tabs (Owner: Farah).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    // In Phase 1, simply navigate to main home screen
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // App Brand Logo
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.eco_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'RecipeMate',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              Text(
                _isLogin ? 'Bon retour parmi nous !' : 'Créer un compte',
                style: AppTextStyles.display.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin
                    ? 'Connectez-vous pour retrouver votre frigo et vos recettes.'
                    : 'Rejoignez RecipeMate pour cuisiner malin et anti-gaspillage.',
                style: AppTextStyles.bodySecondary,
              ),
              const SizedBox(height: 32),

              // Mode Switcher Tabs
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLogin = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _isLogin
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Connexion',
                            style: AppTextStyles.buttonSmall.copyWith(
                              color: _isLogin
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLogin = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: !_isLogin
                                ? AppColors.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Inscription',
                            style: AppTextStyles.buttonSmall.copyWith(
                              color: !_isLogin
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Form fields
              if (!_isLogin) ...[
                AppTextField(
                  controller: _nameController,
                  labelText: 'Nom complet',
                  hintText: 'ex. Marie Dupont',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                const SizedBox(height: 18),
              ],

              AppTextField(
                controller: _emailController,
                labelText: 'Adresse e-mail',
                hintText: 'exemple@recipemate.app',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              const SizedBox(height: 18),

              AppTextField(
                controller: _passwordController,
                labelText: 'Mot de passe',
                hintText: '••••••••',
                obscureText: _obscurePassword,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 28),

              PrimaryButton(
                label: _isLogin ? 'Se connecter' : 'Créer mon compte',
                isFullWidth: true,
                onPressed: _submit,
              ),
              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Continuer en mode invité'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
