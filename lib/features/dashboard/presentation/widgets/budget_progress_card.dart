import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/category_visuals.dart';
import 'package:juka/features/dashboard/domain/entities/budget_progress.dart';
import 'package:juka/shared/utils/color_extension.dart';
import 'package:juka/shared/utils/money_formatter.dart';
import 'package:juka/shared/widget/app_card.dart';
import 'package:juka/shared/widget/empty_message.dart';
import 'package:juka/shared/widget/padding.dart';

/// Budgets du mois consommés, sous forme de jauges.
class BudgetProgressCard extends StatelessWidget {
  const BudgetProgressCard({super.key, required this.budgets});

  final List<BudgetProgress> budgets;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'Budgets consommés',
      icon: Icons.speed_rounded,
      child: budgets.isEmpty
          ? const EmptyMessage(
              message: 'Aucun budget défini pour ce mois.',
              icon: Icons.savings_rounded,
            )
          : Column(
              children: [
                for (var i = 0; i < budgets.length; i++) ...[
                  if (i > 0) 18.ph,
                  _BudgetGauge(budget: budgets[i]),
                ],
              ],
            ),
    );
  }
}

/// Jauge d'un budget : consommation, reste disponible et alerte visuelle.
class _BudgetGauge extends StatelessWidget {
  const _BudgetGauge({required this.budget});

  final BudgetProgress budget;

  /// Vert tant que le budget est respecté, orange à partir de 80 %,
  /// rouge en cas de dépassement.
  Color _statusColor() {
    if (budget.isExceeded) return AppColors.error;
    if (budget.isCloseToLimit) return AppColors.warning;
    return AppColors.success;
  }

  String _statusLabel() {
    if (budget.isExceeded) {
      return 'Dépassé de ${MoneyFormatter.currency(-budget.remaining)}';
    }
    return 'Reste ${MoneyFormatter.currency(budget.remaining)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.textWhite : AppColors.textDark;
    final categoryColor = CategoryVisuals.colorOf(budget.category);
    final statusColor = _statusColor().forBrightness(theme.brightness);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              CategoryVisuals.iconOf(budget.category),
              size: 16,
              color: categoryColor.forBrightness(theme.brightness),
            ),
            8.pw,
            Expanded(
              child: Text(
                budget.category.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            8.pw,
            Text(
              '${MoneyFormatter.currency(budget.spent, decimals: 0)} / '
              '${MoneyFormatter.currency(budget.limit, decimals: 0)}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        10.ph,
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: budget.ratio.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: isDark
                ? AppColors.borderDark
                : AppColors.backgroundWhite,
            color: statusColor,
          ),
        ),
        8.ph,
        Row(
          children: [
            Expanded(
              child: Text(
                _statusLabel(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            8.pw,
            Text(
              MoneyFormatter.percent(
                budget.ratio,
                decimals: 0,
                withSign: false,
              ),
              style: TextStyle(
                color: statusColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
