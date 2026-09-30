import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

/// Écran 1/3 — Connexion (e-mail / mot de passe ou Google).
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final error = await ref
        .read(authControllerProvider.notifier)
        .signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;
    if (error != null) {
      context.showAppSnackBar(error, isError: true);
      return;
    }
    context.showAppSnackBar('Connexion réussie. Bienvenue !');
    context.go(AppRoutes.dashboard);
  }

  Future<void> _signInWithGoogle() async {
    FocusScope.of(context).unfocus();

    final error = await ref
        .read(authControllerProvider.notifier)
        .signInWithGoogle(GoogleAuthMode.signIn);

    if (!mounted) return;
    if (error != null) {
      context.showAppSnackBar(error, isError: true);
      return;
    }
    context.showAppSnackBar('Connexion avec Google réussie.');
    context.go(AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(authControllerProvider).isSubmitting;

    return AuthScaffold(
      children: [
        24.ph,
        const AuthHeader(
          showLogo: true,
          centered: true,
          title: 'Bon retour !',
          subtitle: 'Connectez-vous pour garder le contrôle de vos finances.',
        ),
        AppSize.sectionSpacing.ph,
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                validator: AppValidators.password,
                onFieldSubmitted: (_) => _submit(),
              ),
              AppSize.fieldSpacing.ph,
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(AppRoutes.forgotPassword),
                  child: const Text('Mot de passe oublié ?'),
                ),
              ),
            ],
          ),
        ),
        16.ph,
        AppPrimaryButton(
          label: 'Se connecter',
          isLoading: isSubmitting,
          onPressed: _submit,
        ),
        24.ph,
        const AppOrDivider(),
        24.ph,
        AppSocialButton(
          label: 'Continuer avec Google',
          leading: const GoogleLogo(),
          onPressed: _signInWithGoogle,
        ),
        AppSize.sectionSpacing.ph,
        AuthFooter(
          message: 'Pas encore de compte ?',
          actionLabel: 'Créer un compte',
          onPressed: () => context.push(AppRoutes.register),
        ),
        24.ph,
      ],
    );
  }
}
