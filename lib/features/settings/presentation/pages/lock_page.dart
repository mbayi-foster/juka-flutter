import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/features/settings/domain/services/pin_hasher.dart';
import 'package:juka/features/settings/presentation/providers/settings_providers.dart';
import 'package:juka/shared/widget/app_primary_button.dart';
import 'package:juka/shared/widget/app_text_field.dart';
import 'package:juka/shared/widget/padding.dart';

/// Écran de déverrouillage : le code PIN est demandé à chaque ouverture.
class LockPage extends ConsumerStatefulWidget {
  const LockPage({super.key});

  @override
  ConsumerState<LockPage> createState() => _LockPageState();
}

class _LockPageState extends ConsumerState<LockPage> {
  final _controller = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final unlocked = ref
        .read(settingsControllerProvider.notifier)
        .unlock(_controller.text);

    if (unlocked) {
      _controller.clear();
      setState(() => _errorMessage = null);
      return;
    }

    setState(() => _errorMessage = SettingsController.pinErrorMessage);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = ref.watch(settingsControllerProvider).profile.name;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSize.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              48.ph,
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    size: 30,
                    color: AppColors.primary,
                  ),
                ),
              ),
              20.ph,
              Text(
                name.isEmpty ? 'Bon retour' : 'Bon retour, $name',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? AppColors.textWhite : AppColors.textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              8.ph,
              const Text(
                'Saisissez votre code PIN pour retrouver vos comptes.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              AppSize.sectionSpacing.ph,
              AppTextField(
                label: 'Code PIN',
                controller: _controller,
                isPassword: true,
                autofocus: true,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                prefixIcon: const Icon(Icons.pin_outlined, size: 20),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(PinHasher.maxLength),
                ],
                onFieldSubmitted: (_) => _submit(),
              ),
              if (_errorMessage != null) ...[
                10.ph,
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              AppSize.sectionSpacing.ph,
              AppPrimaryButton(
                label: 'Déverrouiller',
                icon: Icons.lock_open_rounded,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
