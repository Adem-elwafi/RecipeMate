import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:recipemate/core/config/app_assets.dart';
import 'package:recipemate/core/providers/app_providers.dart';
import 'package:recipemate/core/services/auth_error_mapper.dart';
import 'package:recipemate/core/theme/app_colors.dart';
import 'package:recipemate/core/theme/app_text_styles.dart';
import 'package:recipemate/core/theme/app_theme.dart';
import 'package:recipemate/features/auth/utils/auth_validators.dart';
import 'package:recipemate/shared/widgets/app_buttons.dart';
import 'package:recipemate/shared/widgets/app_text_field.dart';

enum _AuthMode { login, register, forgotPassword }

/// Authentication screen owned by Farah. Three modes share the same form
/// widget; only the visible fields and the submitted action change.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  _AuthMode _mode = _AuthMode.login;

  void _changeMode(_AuthMode mode) => setState(() => _mode = mode);

  @override
  Widget build(BuildContext context) {
    final title = switch (_mode) {
      _AuthMode.login => 'Bon retour parmi nous !',
      _AuthMode.register => 'Créez votre compte',
      _AuthMode.forgotPassword => 'Réinitialiser le mot de passe',
    };

    // Les écrans d'authentification (connexion, inscription, mot de passe
    // oublié/réinitialisé) restent clairs même si le thème sombre est actif :
    // la maquette impose fond crème, champs blancs, boutons verts et focus vert.
    // Seule l'apparence est forcée : aucune disposition ni interaction ne change.
    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const _AuthLogo(),
                const SizedBox(height: 20),
                Text(title, style: AppTextStyles.titleLarge),
                const SizedBox(height: 6),
                Text(
                  'Mangez sainement. Cuisinez malin.',
                  style: AppTextStyles.bodySecondary,
                ),
                const SizedBox(height: 28),
                _AuthForm(
                  key: ValueKey<_AuthMode>(_mode),
                  mode: _mode,
                  onModeChanged: _changeMode,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthLogo extends StatelessWidget {
  const _AuthLogo();

  @override
  Widget build(BuildContext context) {
    // Point 2 : mark SVG officiel, sur carte blanche pour le contraste
    // (y compris en thème sombre).
    return Center(
      child: Container(
        width: 88,
        height: 88,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(26),
        ),
        child: SvgPicture.asset(
          appLogoAssetPath,
          fit: BoxFit.contain,
          semanticsLabel: 'Logo RecipeMate',
        ),
      ),
    );
  }
}

class _AuthForm extends ConsumerStatefulWidget {
  const _AuthForm({required this.mode, required this.onModeChanged, super.key});

  final _AuthMode mode;
  final ValueChanged<_AuthMode> onModeChanged;

  @override
  ConsumerState<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends ConsumerState<_AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _infoMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _setLoading(bool value) {
    if (mounted) {
      setState(() => _isLoading = value);
    }
  }

  void _showError(Object error) {
    if (mounted) {
      setState(() => _errorMessage = AuthErrorMapper.message(error));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _infoMessage = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      final email = _emailController.text.trim();

      // Point 3 : appel réel à FirebaseAuth.sendPasswordResetEmail().
      // Firebase envoie un lien (jamais le mot de passe, qui est haché).
      if (widget.mode == _AuthMode.forgotPassword) {
        await auth.sendPasswordResetEmail(email);
        if (mounted) {
          setState(() {
            _infoMessage =
                'Un e-mail de réinitialisation a été envoyé à $email. '
                'Vérifiez votre boîte de réception et vos courriers indésirables.';
          });
        }
        return;
      }

      if (widget.mode == _AuthMode.register) {
        final credential = await auth.register(
          name: _nameController.text.trim(),
          email: email,
          password: _passwordController.text,
        );
        await _finishWithCredential(credential);
      } else {
        final credential = await auth.signIn(
          email: email,
          password: _passwordController.text,
        );
        await _finishWithCredential(credential);
      }
    } on Object catch (error) {
      _showError(error);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final credential = await ref.read(authServiceProvider).signInWithGoogle();
      if (credential != null) {
        await _finishWithCredential(credential);
      }
    } on Object catch (error, stackTrace) {
      // Point A2 : trace complète de l'exception Google/Firebase sur mobile.
      debugPrint('[Connexion Google] $error\n$stackTrace');
      _showError(error);
    } finally {
      _setLoading(false);
    }
  }

  /// Creates or updates the shared UserProfile document after any login
  /// method (e-mail, registration or Google).
  Future<void> _finishWithCredential(UserCredential credential) async {
    final user = credential.user;
    if (user == null) {
      throw StateError('Connexion réussie mais utilisateur introuvable.');
    }
    final firestore = ref.read(firestoreServiceProvider);
    final existing = await firestore.getUserProfile(user.uid);
    final defaultName =
        user.displayName ?? user.email?.split('@').first ?? 'Utilisateur';

    if (existing == null) {
      // Point 5 : premier doc totalement vide (seules les identités Firebase
      // sont conservées) avec createdAt = serverTimestamp().
      await firestore.createEmptyProfile(
        uid: user.uid,
        displayName: defaultName,
        email: user.email,
        // Nouveau compte Google : on conserve la photo fournie par Google.
        // Pour une inscription e-mail/mot de passe, la valeur reste null.
        photoUrl: user.photoURL,
      );
    } else {
      await firestore.saveUserProfile(
        existing.copyWith(
          name: existing.name.isEmpty ? defaultName : existing.name,
          email: user.email ?? existing.email,
          photoUrl: user.photoURL ?? existing.photoUrl,
        ),
      );
    }

    if (!mounted) {
      return;
    }
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final isRegister = widget.mode == _AuthMode.register;
    final isForgot = widget.mode == _AuthMode.forgotPassword;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (isRegister)
            AppTextField(
              controller: _nameController,
              labelText: 'Nom complet',
              hintText: 'Votre nom',
              prefixIcon: const Icon(Icons.person_outline),
              textInputAction: TextInputAction.next,
              validator: (value) => AuthValidators.required(value, 'Le nom'),
            ),
          if (isRegister) const SizedBox(height: 16),
          AppTextField(
            controller: _emailController,
            labelText: 'Adresse e-mail',
            hintText: 'vous@exemple.com',
            prefixIcon: const Icon(Icons.email_outlined),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: AuthValidators.email,
          ),
          if (!isForgot) ...<Widget>[
            const SizedBox(height: 16),
            AppTextField(
              controller: _passwordController,
              labelText: 'Mot de passe',
              hintText: 'Au moins 6 caractères',
              prefixIcon: const Icon(Icons.lock_outline),
              obscureText: _obscurePassword,
              textInputAction: isRegister
                  ? TextInputAction.next
                  : TextInputAction.done,
              validator: AuthValidators.password,
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
          ],
          if (isRegister) ...<Widget>[
            const SizedBox(height: 16),
            AppTextField(
              controller: _confirmController,
              labelText: 'Confirmer le mot de passe',
              hintText: 'Répétez le mot de passe',
              prefixIcon: const Icon(Icons.lock_outline),
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              validator: (value) =>
                  AuthValidators.confirmation(value, _passwordController.text),
            ),
          ],
          if (_errorMessage != null) ...<Widget>[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error),
              ),
              child: Text(
                _errorMessage!,
                style: AppTextStyles.caption.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
          if (_infoMessage != null) ...<Widget>[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.softGreen,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _infoMessage!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 22),
          PrimaryButton(
            label: switch (widget.mode) {
              _AuthMode.login => 'Se connecter',
              _AuthMode.register => 'Créer un compte',
              _AuthMode.forgotPassword => 'Envoyer le lien',
            },
            isFullWidth: true,
            isLoading: _isLoading,
            onPressed: _submit,
          ),
          if (!isRegister && !isForgot) ...<Widget>[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _signInWithGoogle,
              icon: const Icon(Icons.account_circle_outlined),
              label: const Text('Continuer avec Google'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 52),
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(
                  color: AppColors.borderSubtle,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            TextButton(
              onPressed: () => widget.onModeChanged(_AuthMode.forgotPassword),
              child: const Text('Mot de passe oublié ?'),
            ),
          ],
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => widget.onModeChanged(
              isForgot || widget.mode == _AuthMode.login
                  ? _AuthMode.register
                  : _AuthMode.login,
            ),
            child: Text(
              isForgot || widget.mode == _AuthMode.login
                  ? 'Créer un compte'
                  : 'Déjà un compte ? Se connecter',
            ),
          ),
        ],
      ),
    );
  }
}
