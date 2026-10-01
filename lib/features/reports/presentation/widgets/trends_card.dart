import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/features/reports/domain/entities/category_breakdown.dart';
import 'package:juka/features/reports/domain/entities/expense_report.dart';
import 'package:juka/features/reports/domain/enums/trend_direction.dart';
import 'package:juka/features/reports/domain/services/report_formatter.dart';
import 'package:juka/shared/utils/color_extension.dart';
import 'package:juka/shared/utils/money_formatter.dart';
import 'package:juka/shared/widget/app_card.dart';
import 'package:juka/shared/widget/evolution_chart.dart';
import 'package:juka/shared/widget/padding.dart';
import 'package:juka/shared/widget/trend_badge.dart';

/// Tendance de fond : moyenne mobile, sens d'évolution et catégories qui
/// bougent le plus.
class TrendsCard extends StatelessWidget {
  const TrendsCard({super.key, required this.report});

  final ExpenseReport report;

  @override
  Widget build(BuildContext context) {
    final trends = report.trends;
    final currency = report.currency;

    return AppCard(
      title: 'Tendances',
      icon: Icons.show_chart_rounded,
      trailing: _DirectionBadge(direction: trends.direction),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            trends.direction.message,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
          ),
          AppSize.fieldSpacing.ph,
          EvolutionChart(
            points: [
              for (final point in trends.points)
                (date: point.month, value: point.movingAverage),
            ],
            height: 110,
          ),
          8.ph,
          const Text(
            'Moyenne mobile des dépenses sur 3 mois : elle lisse les mois '
            'exceptionnels pour faire ressortir la tendance.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
          ),
          AppSize.fieldSpacing.ph,
          Row(
            children: [
              Expanded(
                child: _AverageTile(
                  label: '3 derniers mois',
                  value: currency.format(trends.averageRecent),
                ),
              ),
              12.pw,
              Expanded(
                child: _AverageTile(
                  label: '3 mois précédents',
                  value: currency.format(trends.averagePrevious),
                ),
              ),
            ],
          ),
          if (trends.movers.isNotEmpty) ...[
            AppSize.fieldSpacing.ph,
            const Text(
              'ÉVOLUTION PAR CATÉGORIE',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            12.ph,
            for (final mover in trends.movers) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      mover.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13.5),
                    ),
                  ),
                  12.pw,
                  Text(
                    '${currency.format(mover.previousAmount)} → '
                    '${currency.format(mover.amount)}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.5,
                    ),
                  ),
                  8.pw,
                  _MoverBadge(mover: mover),
                ],
              ),
              10.ph,
            ],
          ],
        ],
      ),
    );
  }
}

/// Sens d'évolution, affiché dans l'en-tête de la carte.
class _DirectionBadge extends StatelessWidget {
  const _DirectionBadge({required this.direction});

  final TrendDirection direction;

  @override
  Widget build(BuildContext context) {
    final isFavourable = direction == TrendDirection.down;
    final base = direction == TrendDirection.stable
        ? AppColors.info
        : (isFavourable ? AppColors.success : AppColors.error);
    final color = base.forBrightness(Theme.of(context).brightness);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            switch (direction) {
              TrendDirection.up => Icons.trending_up_rounded,
              TrendDirection.down => Icons.trending_down_rounded,
              TrendDirection.stable => Icons.drag_handle_rounded,
            },
            size: 15,
            color: color,
          ),
          6.pw,
          Text(
            direction.label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Moyenne mensuelle d'une fenêtre de trois mois.
class _AverageTile extends StatelessWidget {
  const _AverageTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
        ),
        4.ph,
        Text(
          value,
          style: TextStyle(
            color: isDark ? AppColors.textWhite : AppColors.textDark,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Variation d'une catégorie, avec un tiret quand la base manque.
class _MoverBadge extends StatelessWidget {
  const _MoverBadge({required this.mover});

  final CategoryBreakdown mover;

  @override
  Widget build(BuildContext context) {
    final ratio = mover.variationRatio;
    if (ratio == null) {
      return const Text(
        ReportFormatter.emptyValue,
        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
      );
    }
    return TrendBadge(ratio: ratio, isInverted: true);
  }
}
