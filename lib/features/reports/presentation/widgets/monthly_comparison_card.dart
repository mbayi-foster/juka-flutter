import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/features/reports/domain/entities/expense_report.dart';
import 'package:juka/features/reports/domain/entities/monthly_comparison.dart';
import 'package:juka/shared/utils/date_formatter.dart';
import 'package:juka/shared/utils/money_formatter.dart';
import 'package:juka/shared/widget/app_card.dart';
import 'package:juka/shared/widget/evolution_chart.dart';
import 'package:juka/shared/widget/padding.dart';
import 'package:juka/shared/widget/trend_badge.dart';

/// Comparaison mois par mois : dépenses du mois, variation et solde.
class MonthlyComparisonCard extends StatelessWidget {
  const MonthlyComparisonCard({super.key, required this.report});

  final ExpenseReport report;

  @override
  Widget build(BuildContext context) {
    final months = report.byMonth;

    return AppCard(
      title: 'Comparaison mois par mois',
      icon: Icons.calendar_view_month_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (months.length > 1) ...[
            EvolutionChart(
              points: [
                for (final month in months)
                  (date: month.month, value: month.expenses),
              ],
              height: 110,
            ),
            8.ph,
            const Text(
              'Dépenses de chaque mois de la période.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
            ),
            AppSize.cardSpacing.ph,
          ],
          for (final month in months.reversed) ...[
            _MonthRow(month: month, report: report),
            if (month != months.first) const _RowDivider(),
          ],
        ],
      ),
    );
  }
}

/// Une ligne « mois » de la comparaison.
class _MonthRow extends StatelessWidget {
  const _MonthRow({required this.month, required this.report});

  final MonthlyComparison month;
  final ExpenseReport report;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = report.currency;
    final ratio = month.expensesChangeRatio;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormatter.shortMonthYear(month.month),
                  style: TextStyle(
                    color: isDark ? AppColors.textWhite : AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                4.ph,
                Text(
                  'Revenus ${currency.format(month.income)} · '
                  'Solde ${currency.format(month.savings)}',
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
                currency.format(month.expenses),
                style: TextStyle(
                  color: isDark ? AppColors.textWhite : AppColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (ratio != null) ...[
                6.ph,
                TrendBadge(ratio: ratio, isInverted: true),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Séparateur discret entre deux lignes.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? AppColors.borderDark : AppColors.border,
    );
  }
}
