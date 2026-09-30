import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/shared/utils/color_extension.dart';
import 'package:juka/shared/utils/money_formatter.dart';
import 'package:juka/shared/widget/app_outlined_button.dart';
import 'package:juka/shared/widget/app_primary_button.dart';
import 'package:juka/shared/widget/app_text_field.dart';
import 'package:juka/shared/widget/padding.dart';

/// Ouvre la feuille de rapprochement et retourne le solde réel saisi
/// (`null` si l'utilisateur annule).
Future<double?> showReconciliationSheet(BuildContext context, Account account) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _ReconciliationSheet(account: account),
  );
}

/// Saisie du solde réel, avec écart calculé en direct.
class _ReconciliationSheet extends StatefulWidget {
  const _ReconciliationSheet({required this.account});

  final Account account;

  @override
  State<_ReconciliationSheet> createState() => _ReconciliationSheetState();
}

class _ReconciliationSheetState extends State<_ReconciliationSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: _initialValue(),
  );

  /// Pré-remplit avec le dernier solde réel connu, ou avec le solde de l'app.
  String _initialValue() {
    final account = widget.account;
    final balance = account.reconciledBalance ?? account.currentBalance;
    return MoneyFormatter.number(
      balance,
      decimals: account.currency.decimalDigits,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? get _realBalance => MoneyFormatter.tryParse(_controller.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final account = widget.account;
    final realBalance = _realBalance;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSize.pagePadding,
          AppSize.pagePadding,
          AppSize.pagePadding,
          MediaQuery.viewInsetsOf(context).bottom + AppSize.pagePadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Rapprochement',
              style: TextStyle(
                color: isDark ? AppColors.textWhite : AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            8.ph,
            Text(
              'Indiquez le solde réellement constaté sur « ${account.name} ».',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            20.ph,
            AppTextField(
              label: 'Solde réel',
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              textInputAction: TextInputAction.done,
              prefixIcon: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 20,
              ),
              helperText:
                  'Solde de l\'app : '
                  '${account.currency.format(account.currentBalance)}',
              onChanged: (_) => setState(() {}),
            ),
            16.ph,
            _GapPreview(
              gap: realBalance == null
                  ? null
                  : realBalance - account.currentBalance,
              currency: account.currency,
            ),
            20.ph,
            AppPrimaryButton(
              label: 'Enregistrer le rapprochement',
              onPressed: realBalance == null
                  ? null
                  : () => Navigator.of(context).pop(realBalance),
            ),
            8.ph,
            AppOutlinedButton(
              label: 'Annuler',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aperçu de l'écart entre le solde saisi et le solde de l'application.
class _GapPreview extends StatelessWidget {
  const _GapPreview({required this.gap, required this.currency});

  final double? gap;
  final AppCurrency currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gap = this.gap;

    final String label;
    final Color baseColor;

    if (gap == null) {
      label = 'Saisissez le solde réel pour voir l\'écart.';
      baseColor = AppColors.textMuted;
    } else if (gap.abs() < 0.005) {
      label = 'Les deux soldes correspondent.';
      baseColor = AppColors.success;
    } else if (gap > 0) {
      label = 'Le solde réel est supérieur : une entrée manque peut-être.';
      baseColor = AppColors.warning;
    } else {
      label = 'Le solde réel est inférieur : une dépense manque peut-être.';
      baseColor = AppColors.warning;
    }

    final color = baseColor.forBrightness(theme.brightness);
    final isBalanced = gap != null && gap.abs() < 0.005;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSize.radius),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(
            isBalanced
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
            size: 18,
            color: color,
          ),
          10.pw,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gap == null
                      ? 'Écart —'
                      : 'Écart ${currency.format(gap, withSign: true)}',
                  style: TextStyle(
                    color: isDark ? AppColors.textWhite : AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                4.ph,
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                    height: 1.35,
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
