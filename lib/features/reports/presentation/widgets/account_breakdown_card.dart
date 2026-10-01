import 'package:flutter/material.dart';
import 'package:juka/common/constants/account_type_visuals.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/reports/domain/entities/account_breakdown.dart';
import 'package:juka/features/reports/domain/entities/expense_report.dart';
import 'package:juka/shared/utils/money_formatter.dart';
import 'package:juka/shared/widget/app_card.dart';
import 'package:juka/shared/widget/padding.dart';

/// Dépenses, revenus et solde de chaque compte sur la période.
class AccountBreakdownCard extends StatelessWidget {
  const AccountBreakdownCard({super.key, required this.report});

  final ExpenseReport report;

  @override
  Widget build(BuildContext context) {
    final currency = report.currency;

    return AppCard(
      title: 'Dépenses par compte',
      icon: Icons.account_balance_wallet_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final account in report.byAccount) ...[
            _AccountRow(account: account, currency: currency),
            if (account != report.byAccount.last) 16.ph,
          ],
          16.ph,
          const Text(
            'Le solde affiché est le flux de la période (revenus − dépenses), '
            'et non le solde du compte.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

/// Une ligne « compte » : identité, dépenses et flux net.
class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.account, required this.currency});

  final AccountBreakdown account;
  final AppCurrency currency;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = AccountTypeVisuals.colorOf(account.type);
    final netColor = account.isNetPositive
        ? AppColors.success
        : AppColors.error;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            AccountTypeVisuals.iconOf(account.type),
            size: 18,
            color: color,
          ),
        ),
        12.pw,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                account.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? AppColors.textWhite : AppColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              4.ph,
              Text(
                '${account.type.label} · ${account.operationCount} opération'
                '${account.operationCount > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        12.pw,
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currency.format(account.expenses),
              style: TextStyle(
                color: isDark ? AppColors.textWhite : AppColors.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            2.ph,
            Text(
              'Flux ${currency.format(account.net, withSign: true)}',
              style: TextStyle(color: netColor, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}
