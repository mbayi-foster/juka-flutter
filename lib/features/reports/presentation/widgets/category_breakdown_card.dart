import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/category_visuals.dart';
import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/reports/domain/entities/category_breakdown.dart';
import 'package:juka/features/reports/domain/entities/expense_report.dart';
import 'package:juka/shared/utils/money_formatter.dart';
import 'package:juka/shared/widget/app_card.dart';
import 'package:juka/shared/widget/padding.dart';
import 'package:juka/shared/widget/trend_badge.dart';

/// Dépenses par catégorie : montant, part du total et évolution.
class CategoryBreakdownCard extends StatelessWidget {
  const CategoryBreakdownCard({super.key, required this.report});

  final ExpenseReport report;

  @override
  Widget build(BuildContext context) {
    final currency = report.currency;

    return AppCard(
      title: 'Dépenses par catégorie',
      icon: Icons.donut_small_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in report.byCategory) ...[
            _CategoryRow(item: item, currency: currency),
            if (item != report.byCategory.last) 16.ph,
          ],
          16.ph,
          Text(
            'Total dépensé : ${currency.format(report.totals.expenses)} — les '
            'sous-catégories sont regroupées dans leur catégorie parente.',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

/// Une catégorie : pastille, nom, montant, part et variation.
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.item, required this.currency});

  final CategoryBreakdown item;
  final AppCurrency currency;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = Color(item.colorHex);
    final ratio = item.variationRatio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                CategoryVisuals.iconOfKey(item.iconKey),
                size: 18,
                color: color,
              ),
            ),
            12.pw,
            Expanded(
              child: Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? AppColors.textWhite : AppColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            12.pw,
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currency.format(item.amount),
                  style: TextStyle(
                    color: isDark ? AppColors.textWhite : AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                2.ph,
                Text(
                  '${MoneyFormatter.percent(item.share, withSign: false)} du total',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        10.ph,
        Row(
          children: [
            Expanded(
              child: _ShareBar(share: item.share, color: color),
            ),
            if (ratio != null) ...[
              12.pw,
              TrendBadge(ratio: ratio, isInverted: true),
            ],
          ],
        ),
      ],
    );
  }
}

/// Jauge de la part d'une catégorie dans les dépenses totales.
class _ShareBar extends StatelessWidget {
  const _ShareBar({required this.share, required this.color});

  final double share;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 6,
        color: (isDark ? AppColors.borderDark : AppColors.border).withValues(
          alpha: 0.6,
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: share.clamp(0, 1),
          child: Container(color: color),
        ),
      ),
    );
  }
}
