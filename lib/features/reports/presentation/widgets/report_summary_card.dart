import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/features/reports/domain/entities/expense_report.dart';
import 'package:juka/shared/utils/money_formatter.dart';
import 'package:juka/shared/widget/app_card.dart';
import 'package:juka/shared/widget/padding.dart';
import 'package:juka/shared/widget/trend_badge.dart';

/// Chiffres clés de la période : revenus, dépenses, épargne et opérations.
///
/// Chaque montant est comparé à la période précédente lorsque la comparaison a
/// un sens (une base non nulle).
class ReportSummaryCard extends StatelessWidget {
  const ReportSummaryCard({super.key, required this.report});

  final ExpenseReport report;

  @override
  Widget build(BuildContext context) {
    final currency = report.currency;
    final totals = report.totals;

    return AppCard(
      title: 'Synthèse',
      icon: Icons.insights_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Revenus',
                  value: currency.format(totals.income),
                  ratio: totals.incomeChangeRatio,
                ),
              ),
              12.pw,
              Expanded(
                child: _StatTile(
                  label: 'Dépenses',
                  value: currency.format(totals.expenses),
                  ratio: totals.expensesChangeRatio,
                  isInverted: true,
                ),
              ),
            ],
          ),
          AppSize.fieldSpacing.ph,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Épargne',
                  value: currency.format(totals.savings),
                  hint:
                      '${MoneyFormatter.percent(totals.savingsRate, withSign: false)} des revenus',
                  ratio: totals.savingsChangeRatio,
                ),
              ),
              12.pw,
              Expanded(
                child: _StatTile(
                  label: 'Opérations',
                  value: '${totals.operationCount}',
                  hint:
                      '${currency.format(totals.dailyAverage)} / jour en moyenne',
                ),
              ),
            ],
          ),
          AppSize.fieldSpacing.ph,
          Text(
            'Dépense moyenne : ${currency.format(totals.monthlyAverage)} par mois '
            'sur la période.',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

/// Un indicateur : libellé, valeur et évolution éventuelle.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    this.hint,
    this.ratio,
    this.isInverted = false,
  });

  final String label;
  final String value;
  final String? hint;
  final double? ratio;

  /// `true` pour un montant dont la hausse est une mauvaise nouvelle.
  final bool isInverted;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ratio = this.ratio;
    final hint = this.hint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
        ),
        6.ph,
        Text(
          value,
          style: TextStyle(
            color: isDark ? AppColors.textWhite : AppColors.textDark,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (ratio != null) ...[
          6.ph,
          TrendBadge(ratio: ratio, isInverted: isInverted),
        ] else if (hint != null) ...[
          6.ph,
          Text(
            hint,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
          ),
        ],
      ],
    );
  }
}
