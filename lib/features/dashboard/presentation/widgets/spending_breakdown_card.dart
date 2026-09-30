import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/category_visuals.dart';
import 'package:juka/features/dashboard/domain/entities/category_spending.dart';
import 'package:juka/shared/utils/color_extension.dart';
import 'package:juka/shared/utils/money_formatter.dart';
import 'package:juka/shared/widget/app_card.dart';
import 'package:juka/shared/widget/empty_message.dart';
import 'package:juka/shared/widget/padding.dart';

/// Répartition des dépenses du mois par catégorie.
class SpendingBreakdownCard extends StatelessWidget {
  const SpendingBreakdownCard({super.key, required this.items});

  /// Catégories triées de la plus grosse dépense à la plus petite.
  final List<CategorySpending> items;

  double get _total => items.fold(0, (sum, item) => sum + item.amount);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'Répartition des dépenses',
      icon: Icons.donut_large_rounded,
      child: items.isEmpty
          ? const EmptyMessage(
              message: 'Aucune dépense enregistrée sur la période.',
              icon: Icons.insights_rounded,
            )
          : Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) 14.ph,
                  _CategoryRow(item: items[i], total: _total),
                ],
              ],
            ),
    );
  }
}

/// Ligne d'une catégorie : identité visuelle, montant, part et jauge.
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.item, required this.total});

  final CategorySpending item;
  final double total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = CategoryVisuals.colorOf(item.category);
    final share = total <= 0 ? 0.0 : item.amount / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                CategoryVisuals.iconOf(item.category),
                size: 16,
                color: color.forBrightness(theme.brightness),
              ),
            ),
            10.pw,
            Expanded(
              child: Text(
                item.category.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark ? AppColors.textWhite : AppColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            8.pw,
            Text(
              MoneyFormatter.currency(item.amount),
              style: TextStyle(
                color: isDark ? AppColors.textWhite : AppColors.textDark,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            8.pw,
            SizedBox(
              width: 38,
              child: Text(
                MoneyFormatter.percent(share, decimals: 0, withSign: false),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        8.ph,
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: share.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: isDark
                ? AppColors.borderDark
                : AppColors.backgroundWhite,
            color: color,
          ),
        ),
      ],
    );
  }
}
