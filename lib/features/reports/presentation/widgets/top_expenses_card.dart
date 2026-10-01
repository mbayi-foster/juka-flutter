import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/category_visuals.dart';
import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/reports/domain/entities/expense_report.dart';
import 'package:juka/features/reports/domain/entities/top_expense.dart';
import 'package:juka/shared/utils/date_formatter.dart';
import 'package:juka/shared/utils/money_formatter.dart';
import 'package:juka/shared/widget/app_card.dart';
import 'package:juka/shared/widget/padding.dart';

/// Top des dépenses : les opérations les plus lourdes de la période.
class TopExpensesCard extends StatelessWidget {
  const TopExpensesCard({super.key, required this.report});

  final ExpenseReport report;

  @override
  Widget build(BuildContext context) {
    final currency = report.currency;

    return AppCard(
      title: 'Top des dépenses',
      icon: Icons.local_fire_department_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final expense in report.topExpenses) ...[
            _ExpenseRow(
              expense: expense,
              currency: currency,
              rank: report.topExpenses.indexOf(expense) + 1,
            ),
            if (expense != report.topExpenses.last) 14.ph,
          ],
        ],
      ),
    );
  }
}

/// Une dépense du classement : rang, libellé, catégorie et part du total.
class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    required this.expense,
    required this.currency,
    required this.rank,
  });

  final TopExpense expense;
  final AppCurrency currency;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = Color(expense.categoryColorHex);

    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$rank',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        12.pw,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                expense.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? AppColors.textWhite : AppColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              4.ph,
              Row(
                children: [
                  Icon(
                    CategoryVisuals.iconOfKey(expense.categoryIconKey),
                    size: 13,
                    color: AppColors.textMuted,
                  ),
                  4.pw,
                  Expanded(
                    child: Text(
                      '${expense.categoryName} · '
                      '${DateFormatter.shortDate(expense.date)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        12.pw,
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              currency.format(expense.amount),
              style: TextStyle(
                color: isDark ? AppColors.textWhite : AppColors.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            2.ph,
            Text(
              '${MoneyFormatter.percent(expense.share, withSign: false)} des dépenses',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}
