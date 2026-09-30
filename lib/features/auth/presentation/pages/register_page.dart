import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/features/auth/domain/enums/google_auth_mode.dart';
import 'package:juka/features/auth/presentation/providers/auth_providers.dart';
import 'package:juka/features/auth/presentation/widgets/auth_footer.dart';
import 'package:juka/features/auth/presentation/widgets/auth_header.dart';
import 'package:juka/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:juka/routes/app_routes.dart';
import 'package:juka/shared/utils/validators.dart';
import 'package:juka/shared/widget/app_or_divider.dart';
import 'package:juka/shared/widget/app_primary_button.dart';
import 'package:juka/shared/widget/app_snack_bar.dart';
import 'package:juka/shared/widget/app_social_button.dart';
import 'package:juka/shared/widget/app_text_field.dart';
import 'package:juka/shared/widget/google_logo.dart';
import 'package:juka/shared/widget/padding.dart';

/// Écran 2/3 — Création de compte (e-mail / mot de passe ou Google).
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _acceptTerms = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_acceptTerms) {
      context.showAppSnackBar(
        'Veuillez accepter les conditions d\'utilisation.',
        isError: true,
      );
      return;
    }

    final error = await ref
        .read(authControllerProvider.notifier)
        .signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
        );

    if (!mounted) return;
    if (error != null) {
      context.showAppSnackBar(error, isError: true);
      return;
    }
    context.showAppSnackBar('Votre compte a bien été créé 🎉');
    context.go(AppRoutes.dashboard);
  }

  Future<void> _signUpWithGoogle() async {
    FocusScope.of(context).unfocus();

    final error = await ref
        .read(authControllerProvider.notifier)
        .signInWithGoogle(GoogleAuthMode.signUp);

    if (!mounted) return;
    if (error != null) {
      context.showAppSnackBar(error, isError: true);
      return;
    }
    context.showAppSnackBar('Votre compte a bien été créé 🎉');
    context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(authControllerProvider).isSubmitting;

    return AuthScaffold(
      showBackButton: true,
      fallbackLocation: AppRoutes.login,
      children: [
        8.ph,
        const AuthHeader(
          title: 'Créer un compte',
          subtitle:
              'Quelques informations suffisent pour commencer à gérer votre argent.',
        ),
        AppSize.sectionSpacing.ph,
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Prénom',
                      controller: _firstNameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.givenName],
                      validator: (value) =>
                          AppValidators.personName(value, label: 'Le prénom'),
                    ),
                  ),
                  12.pw,
                  Expanded(
                    child: AppTextField(
                      label: 'Nom',
                      controller: _lastNameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.familyName],
                      validator: (value) =>
                          AppValidators.personName(value, label: 'Le nom'),
                    ),
                  ),
                ],
              ),
              AppSize.fieldSpacing.ph,
              AppTextField(
                label: 'Adresse e-mail',
                hintText: 'vous@exemple.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
                validator: AppValidators.email,
              ),
              AppSize.fieldSpacing.ph,
              AppTextField(
                label: 'Mot de passe',
                controller: _passwordController,
                isPassword: true,
                textInputAction: TextInputAction.next,
                helperText:
                    'Au moins ${AppValidators.minPasswordLength} caractères.',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                validator: AppValidators.password,
              ),
              AppSize.fieldSpacing.ph,
              AppTextField(
                label: 'Confirmer le mot de passe',
                controller: _confirmPasswordController,
                isPassword: true,
                textInputAction: TextInputAction.done,
                prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                validator: (value) => AppValidators.confirmPassword(
                  value,
                  _passwordController.text,
                ),
                onFieldSubmitted: (_) => _submit(),
              ),
              AppSize.fieldSpacing.ph,
              _TermsCheckbox(
                value: _acceptTerms,
                onChanged: (value) => setState(() => _acceptTerms = value),
              ),
            ],
          ),
        ),
        20.ph,
        AppPrimaryButton(
          label: 'Créer mon compte',
          isLoading: isSubmitting,
          onPressed: _submit,
        ),
        24.ph,
        const AppOrDivider(),
        24.ph,
        AppSocialButton(
          label: 'S\'inscrire avec Google',
          leading: const GoogleLogo(),
          onPressed: _signUpWithGoogle,
        ),
        AppSize.sectionSpacing.ph,
        AuthFooter(
          message: 'Déjà un compte ?',
          actionLabel: 'Se connecter',
          onPressed: () => context.go(AppRoutes.login),
        ),
        24.ph,
      ],
    );
  }
}

/// Case à cocher d'acceptation des conditions d'utilisation.
class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: value,
          onChanged: (checked) => onChanged(checked ?? false),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        8.pw,
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: const Padding(
              padding: EdgeInsets.only(top: 10),
              child: Text(
                'J\'accepte les conditions d\'utilisation et la politique de '
                'confidentialité de Juka.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
