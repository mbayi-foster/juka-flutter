import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/shared/utils/color_extension.dart';
import 'package:juka/shared/utils/date_formatter.dart';
import 'package:juka/shared/utils/money_formatter.dart';
import 'package:juka/shared/widget/app_card.dart';
import 'package:juka/shared/widget/app_outlined_button.dart';
import 'package:juka/shared/widget/padding.dart';

/// Rapprochement : confronte le solde calculé par l'application au solde réel
/// constaté sur le compte.
class ReconciliationCard extends StatelessWidget {
  const ReconciliationCard({
    super.key,
    required this.account,
    required this.onReconcile,
  });

  final Account account;

  /// Ouvre la saisie du solde réel.
  final VoidCallback onReconcile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gap = account.reconciliationGap;
    final reconciledBalance = account.reconciledBalance;
    final reconciledAt = account.reconciledAt;

    return AppCard(
      title: 'Rapprochement',
      icon: Icons.rule_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Comparez le solde calculé par Juka avec le solde réel de votre '
            'compte pour repérer les opérations manquantes.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          16.ph,
          _ValueRow(
            label: 'Solde de l\'app',
            value: account.currency.format(account.currentBalance),
          ),
          10.ph,
          _ValueRow(
            label: 'Solde réel constaté',
            value: reconciledBalance == null
                ? 'Non renseigné'
                : account.currency.format(reconciledBalance),
            isMuted: reconciledBalance == null,
          ),
          12.ph,
          const Divider(height: 1),
          12.ph,
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Écart',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                gap == null
                    ? '—'
                    : account.currency.format(gap, withSign: true),
                style: TextStyle(
                  color: gap == null
                      ? AppColors.textMuted
                      : (account.isReconciled
                                ? AppColors.success
                                : AppColors.warning)
                            .forBrightness(theme.brightness),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (reconciledAt != null) ...[
            6.ph,
            Text(
              'Dernier contrôle : ${DateFormatter.shortDate(reconciledAt)}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
          16.ph,
          AppOutlinedButton(
            label: 'Rapprocher le compte',
            icon: Icons.checklist_rounded,
            onPressed: onReconcile,
          ),
        ],
      ),
    );
  }
}

/// Ligne « libellé / montant » du bloc de rapprochement.
class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    required this.value,
    this.isMuted = false,
  });

  final String label;
  final String value;
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13.5),
          ),
        ),
        8.pw,
        Text(
          value,
          style: TextStyle(
            color: isMuted
                ? AppColors.textMuted
                : (isDark ? AppColors.textWhite : AppColors.textDark),
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
