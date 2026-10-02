import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/features/settings/domain/services/pin_hasher.dart';
import 'package:juka/features/settings/presentation/providers/settings_providers.dart';
import 'package:juka/shared/utils/validators.dart';
import 'package:juka/shared/widget/app_card.dart';
import 'package:juka/shared/widget/app_primary_button.dart';
import 'package:juka/shared/widget/app_snack_bar.dart';
import 'package:juka/shared/widget/app_text_field.dart';
import 'package:juka/shared/widget/padding.dart';

/// Profil local : le nom affiché et le code PIN de verrouillage.
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _nameFormKey = GlobalKey<FormState>();
  final _enableFormKey = GlobalKey<FormState>();
  final _changeFormKey = GlobalKey<FormState>();
  final _disableFormKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _enablePinController = TextEditingController();
  final _enableConfirmController = TextEditingController();
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _newConfirmController = TextEditingController();
  final _disablePinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = ref.read(settingsControllerProvider).profile.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _enablePinController.dispose();
    _enableConfirmController.dispose();
    _currentPinController.dispose();
    _newPinController.dispose();
    _newConfirmController.dispose();
    _disablePinController.dispose();
    super.dispose();
  }

  void _notify(String message, {bool isError = false}) {
    if (!mounted) return;
    context.showAppSnackBar(message, isError: isError);
  }

  // ---------------------------------------------------------------------
  // Nom
  // ---------------------------------------------------------------------

  Future<void> _saveName() async {
    FocusScope.of(context).unfocus();
    if (!(_nameFormKey.currentState?.validate() ?? false)) return;

    await ref
        .read(settingsControllerProvider.notifier)
        .renameProfile(_nameController.text);
    _notify('Nom enregistré.');
  }

  // ---------------------------------------------------------------------
  // Code PIN
  // ---------------------------------------------------------------------

  Future<void> _enablePin() async {
    FocusScope.of(context).unfocus();
    if (!(_enableFormKey.currentState?.validate() ?? false)) return;

    final error = await ref
        .read(settingsControllerProvider.notifier)
        .enablePin(_enablePinController.text);

    if (error != null) {
      _notify(error, isError: true);
      return;
    }
    _enablePinController.clear();
    _enableConfirmController.clear();
    _notify('Code PIN activé.');
  }

  Future<void> _changePin() async {
    FocusScope.of(context).unfocus();
    if (!(_changeFormKey.currentState?.validate() ?? false)) return;

    final error = await ref
        .read(settingsControllerProvider.notifier)
        .changePin(
          currentPin: _currentPinController.text,
          newPin: _newPinController.text,
        );

    if (error != null) {
      _notify(error, isError: true);
      return;
    }
    _currentPinController.clear();
    _newPinController.clear();
    _newConfirmController.clear();
    _notify('Code PIN modifié.');
  }

  Future<void> _disablePin() async {
    FocusScope.of(context).unfocus();
    if (!(_disableFormKey.currentState?.validate() ?? false)) return;

    final error = await ref
        .read(settingsControllerProvider.notifier)
        .disablePin(pin: _disablePinController.text);

    if (error != null) {
      _notify(error, isError: true);
      return;
    }
    _disablePinController.clear();
    _notify('Code PIN désactivé.');
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(settingsControllerProvider).profile;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSize.pagePadding),
          children: [
            AppCard(
              title: 'Mon nom',
              icon: Icons.person_outline_rounded,
              child: Form(
                key: _nameFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      label: 'Votre nom',
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      prefixIcon: const Icon(
                        Icons.person_outline_rounded,
                        size: 20,
                      ),
                      validator: (value) =>
                          AppValidators.personName(value, label: 'Votre nom'),
                      onFieldSubmitted: (_) => _saveName(),
                    ),
                    16.ph,
                    AppPrimaryButton(
                      label: 'Enregistrer',
                      icon: Icons.check_rounded,
                      onPressed: _saveName,
                    ),
                  ],
                ),
              ),
            ),
            AppSize.cardSpacing.ph,
            AppCard(
              title: 'Code PIN',
              icon: Icons.lock_outline_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        profile.hasPin
                            ? Icons.verified_user_rounded
                            : Icons.lock_open_rounded,
                        size: 18,
                        color: profile.hasPin
                            ? AppColors.success
                            : AppColors.textMuted,
                      ),
                      8.pw,
                      Expanded(
                        child: Text(
                          profile.hasPin
                              ? 'Protection activée : le code est demandé à '
                                    'chaque ouverture.'
                              : 'Aucune protection : l\'application s\'ouvre '
                                    'directement.',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textWhite
                                : AppColors.textDark,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSize.fieldSpacing.ph,
                  if (!profile.hasPin)
                    _PinForm(
                      formKey: _enableFormKey,
                      pinController: _enablePinController,
                      confirmController: _enableConfirmController,
                      submitLabel: 'Activer le code PIN',
                      submitIcon: Icons.lock_rounded,
                      onSubmit: _enablePin,
                    )
                  else ...[
                    _PinForm(
                      formKey: _changeFormKey,
                      currentController: _currentPinController,
                      pinController: _newPinController,
                      confirmController: _newConfirmController,
                      submitLabel: 'Modifier le code PIN',
                      submitIcon: Icons.password_rounded,
                      onSubmit: _changePin,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Divider(height: 1),
                    ),
                    _PinForm(
                      formKey: _disableFormKey,
                      currentController: _disablePinController,
                      submitLabel: 'Désactiver la protection',
                      submitIcon: Icons.lock_open_rounded,
                      onSubmit: _disablePin,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Petit formulaire de code PIN, réutilisé pour activer, modifier et
/// désactiver la protection.
class _PinForm extends StatelessWidget {
  const _PinForm({
    required this.formKey,
    required this.submitLabel,
    required this.submitIcon,
    required this.onSubmit,
    this.currentController,
    this.pinController,
    this.confirmController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController? currentController;
  final TextEditingController? pinController;
  final TextEditingController? confirmController;
  final String submitLabel;
  final IconData submitIcon;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final current = currentController;
    final pin = pinController;
    final confirm = confirmController;

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (current != null) ...[
            _PinField(label: 'Code PIN actuel', controller: current),
            AppSize.fieldSpacing.ph,
          ],
          if (pin != null) ...[
            _PinField(
              label: current == null ? 'Code PIN' : 'Nouveau code PIN',
              controller: pin,
            ),
            AppSize.fieldSpacing.ph,
          ],
          if (confirm != null) ...[
            _PinField(
              label: 'Confirmer le code PIN',
              controller: confirm,
              validator: (value) => value == pin?.text
                  ? null
                  : 'Les deux codes ne correspondent pas',
            ),
            AppSize.fieldSpacing.ph,
          ],
          AppPrimaryButton(
            label: submitLabel,
            icon: submitIcon,
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}

/// Champ de code PIN : chiffres uniquement, masqué.
class _PinField extends StatelessWidget {
  const _PinField({
    required this.label,
    required this.controller,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: label,
      controller: controller,
      isPassword: true,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      prefixIcon: const Icon(Icons.pin_outlined, size: 20),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(PinHasher.maxLength),
      ],
      validator:
          validator ??
          (value) => PinHasher.isValid(value ?? '')
              ? null
              : SettingsController.pinFormatMessage,
    );
  }
}
