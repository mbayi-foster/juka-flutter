import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/features/settings/domain/services/pin_hasher.dart';
import 'package:juka/features/settings/presentation/providers/settings_providers.dart';
import 'package:juka/shared/utils/validators.dart';
import 'package:juka/shared/widget/app_outlined_button.dart';
import 'package:juka/shared/widget/app_primary_button.dart';
import 'package:juka/shared/widget/app_snack_bar.dart';
import 'package:juka/shared/widget/app_text_field.dart';
import 'package:juka/shared/widget/padding.dart';

/// Première ouverture : l'utilisateur indique son nom et peut choisir de
/// protéger l'application par un code PIN.
///
/// Tout reste sur le téléphone : aucune inscription ni connexion réseau.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _nameFormKey = GlobalKey<FormState>();
  final _pinFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();

  int _step = 0;
  bool _withPin = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _goToPinStep() {
    FocusScope.of(context).unfocus();
    if (!(_nameFormKey.currentState?.validate() ?? false)) return;
    setState(() => _step = 1);
  }

  /// Termine l'accueil. Sans code PIN, [pin] reste `null`.
  Future<void> _finish({bool withPin = true}) async {
    FocusScope.of(context).unfocus();
    final usePin = withPin && _withPin;

    if (usePin && !(_pinFormKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    await ref
        .read(settingsControllerProvider.notifier)
        .completeOnboarding(
          name: _nameController.text,
          pin: usePin ? _pinController.text : null,
        );

    if (!mounted) return;
    setState(() => _isSaving = false);
    context.showAppSnackBar(
      usePin ? 'Bienvenue ! Votre code PIN est actif.' : 'Bienvenue !',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSize.pagePadding),
          child: _step == 0 ? _buildNameStep() : _buildPinStep(),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Étape 1 : le nom
  // ---------------------------------------------------------------------

  Widget _buildNameStep() {
    return Form(
      key: _nameFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          32.ph,
          const _OnboardingHeader(
            icon: Icons.waving_hand_rounded,
            title: 'Bienvenue sur Juka',
            message:
                'Vos comptes, vos opérations et vos analyses vivent sur ce '
                'téléphone. Commençons par faire connaissance.',
          ),
          AppSize.sectionSpacing.ph,
          AppTextField(
            label: 'Votre nom',
            hintText: 'Mayisha',
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
            validator: (value) =>
                AppValidators.personName(value, label: 'Votre nom'),
            onFieldSubmitted: (_) => _goToPinStep(),
          ),
          AppSize.sectionSpacing.ph,
          AppPrimaryButton(
            label: 'Continuer',
            icon: Icons.arrow_forward_rounded,
            onPressed: _goToPinStep,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Étape 2 : le code PIN (facultatif)
  // ---------------------------------------------------------------------

  Widget _buildPinStep() {
    return Form(
      key: _pinFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          24.ph,
          const _OnboardingHeader(
            icon: Icons.lock_outline_rounded,
            title: 'Protéger l\'application',
            message:
                'Un code PIN empêche quelqu\'un qui prend votre téléphone '
                'd\'ouvrir Juka. Vous pourrez l\'activer ou le modifier plus '
                'tard dans les paramètres.',
          ),
          AppSize.sectionSpacing.ph,
          SwitchListTile.adaptive(
            value: _withPin,
            onChanged: (value) => setState(() => _withPin = value),
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.primary,
            title: const Text('Créer un code PIN'),
            subtitle: Text(
              _withPin ? '4 à 6 chiffres' : 'Recommandé, mais facultatif',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12.5,
              ),
            ),
          ),
          if (_withPin) ...[
            8.ph,
            AppTextField(
              label: 'Code PIN',
              controller: _pinController,
              isPassword: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(Icons.pin_outlined, size: 20),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(PinHasher.maxLength),
              ],
              validator: (value) => PinHasher.isValid(value ?? '')
                  ? null
                  : SettingsController.pinFormatMessage,
            ),
            AppSize.fieldSpacing.ph,
            AppTextField(
              label: 'Confirmer le code PIN',
              controller: _confirmController,
              isPassword: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              prefixIcon: const Icon(Icons.pin_outlined, size: 20),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(PinHasher.maxLength),
              ],
              validator: (value) => value == _pinController.text
                  ? null
                  : 'Les deux codes ne correspondent pas',
            ),
          ],
          AppSize.sectionSpacing.ph,
          AppPrimaryButton(
            label: 'Commencer',
            icon: Icons.check_rounded,
            isLoading: _isSaving,
            onPressed: _finish,
          ),
          10.ph,
          AppOutlinedButton(
            label: _withPin ? 'Plus tard' : 'Continuer sans code PIN',
            onPressed: _isSaving ? null : () => _finish(withPin: false),
          ),
          AppSize.fieldSpacing.ph,
          TextButton.icon(
            onPressed: _isSaving ? null : () => setState(() => _step = 0),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Modifier mon nom'),
          ),
        ],
      ),
    );
  }
}

/// En-tête illustré des étapes d'accueil.
class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, size: 28, color: AppColors.primary),
        ),
        18.ph,
        Text(
          title,
          style: TextStyle(
            color: isDark ? AppColors.textWhite : AppColors.textDark,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        10.ph,
        Text(
          message,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
