import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/shared/utils/money_formatter.dart';
import 'package:juka/shared/widget/app_card.dart';
import 'package:juka/shared/widget/empty_message.dart';
import 'package:juka/shared/widget/padding.dart';

/// Totaux des comptes actifs, regroupés par devise.
///
/// Les soldes de devises différentes ne sont jamais additionnés entre eux.
class AccountsSummaryCard extends StatelessWidget {
  const AccountsSummaryCard({
    super.key,
    required this.totals,
    required this.activeCount,
    required this.archivedCount,
  });

  final Map<AppCurrency, double> totals;
  final int activeCount;
  final int archivedCount;

  @override
  Widget build(BuildContext context) {
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return AppCard(
      title: 'Solde total',
      icon: Icons.account_balance_wallet_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entries.isEmpty)
            const EmptyMessage(message: 'Aucun compte actif pour le moment.')
          else
            for (var i = 0; i < entries.length; i++) ...[
              if (i > 0) 12.ph,
              _TotalRow(currency: entries[i].key, amount: entries[i].value),
            ],
          16.ph,
          const Divider(height: 1),
          14.ph,
          Text(
            'Actifs : $activeCount · Archivés : $archivedCount',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

/// Total d'une devise : libellé à gauche, montant à droite.
class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.currency, required this.amount});

  final AppCurrency currency;
  final double amount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Text(
            currency.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
        8.pw,
        Text(
          currency.format(amount),
          style: TextStyle(
            color: isDark ? AppColors.textWhite : AppColors.textDark,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
