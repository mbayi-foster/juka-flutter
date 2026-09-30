import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/features/auth/presentation/providers/auth_providers.dart';
import 'package:juka/features/auth/presentation/widgets/auth_header.dart';
import 'package:juka/features/auth/presentation/widgets/auth_scaffold.dart';
import 'package:juka/routes/app_routes.dart';
import 'package:juka/shared/utils/validators.dart';
import 'package:juka/shared/widget/app_outlined_button.dart';
import 'package:juka/shared/widget/app_primary_button.dart';
import 'package:juka/shared/widget/app_snack_bar.dart';
import 'package:juka/shared/widget/app_text_field.dart';
import 'package:juka/shared/widget/padding.dart';

/// Écran 3/3 — Demande de réinitialisation du mot de passe.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  /// Passe à `true` une fois le lien envoyé.
  bool _isSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final error = await ref
        .read(authControllerProvider.notifier)
        .requestPasswordReset(email: _emailController.text.trim());

    if (!mounted) return;
    if (error != null) {
      context.showAppSnackBar(error, isError: true);
      return;
    }
    setState(() => _isSent = true);
    context.showAppSnackBar(
      'Un lien de réinitialisation vous a été envoyé par e-mail.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(authControllerProvider).isSubmitting;

    return AuthScaffold(
      showBackButton: true,
      centered: true,
      fallbackLocation: AppRoutes.login,
      children: [
        24.ph,
        const AuthHeader(
          title: 'Mot de passe oublié ?',
          subtitle:
              'Indiquez l\'adresse e-mail associée à votre compte : nous vous '
              'enverrons un lien pour définir un nouveau mot de passe.',
        ),
        AppSize.sectionSpacing.ph,
        if (_isSent)
          _ResetLinkSentView(email: _emailController.text.trim())
        else
          Form(
            key: _formKey,
            child: AppTextField(
              label: 'Adresse e-mail',
              hintText: 'vous@exemple.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
              validator: AppValidators.email,
              onFieldSubmitted: (_) => _submit(),
            ),
          ),
        AppSize.sectionSpacing.ph,
        if (!_isSent)
          AppPrimaryButton(
            label: 'Envoyer le lien',
            isLoading: isSubmitting,
            onPressed: _submit,
          )
        else
          AppOutlinedButton(
            label: 'Retour à la connexion',
            icon: Icons.arrow_back_rounded,
            onPressed: () => context.go(AppRoutes.login),
          ),
        24.ph,
      ],
    );
  }
}

/// Confirmation affichée après l'envoi du lien.
class _ResetLinkSentView extends StatelessWidget {
  const _ResetLinkSentView({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppSize.radius),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              color: AppColors.success,
              size: 22,
            ),
          ),
          12.pw,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'E-mail envoyé',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textWhite : AppColors.textDark,
                  ),
                ),
                6.ph,
                Text(
                  email.isEmpty
                      ? 'Consultez votre boîte de réception.'
                      : 'Consultez la boîte de réception de $email et suivez '
                            'les instructions du lien.',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
