import 'dart:math';

import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/accounts/domain/entities/account_balance_point.dart';
import 'package:juka/shared/utils/color_extension.dart';
import 'package:juka/shared/utils/date_formatter.dart';
import 'package:juka/shared/utils/money_formatter.dart';
import 'package:juka/shared/widget/empty_message.dart';
import 'package:juka/shared/widget/padding.dart';

/// Évolution du solde d'un compte, sous forme de barres proportionnelles.
///
/// La hauteur de chaque barre est normalisée entre le minimum et le maximum de
/// la période : les variations restent lisibles même sur de petits écarts.
class BalanceHistoryChart extends StatelessWidget {
  const BalanceHistoryChart({
    super.key,
    required this.points,
    required this.currency,
  });

  /// Points du plus ancien au plus récent.
  final List<AccountBalancePoint> points;

  final AppCurrency currency;

  static const double _chartHeight = 120;

  /// Hauteur minimale d'une barre, pour rester visible.
  static const double _minHeightFactor = 0.25;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const EmptyMessage(
        message: 'Aucun historique disponible pour ce compte.',
      );
    }

    final values = [for (final point in points) point.balance];
    final minValue = values.reduce(min);
    final maxValue = values.reduce(max);
    final range = maxValue - minValue;

    final variation = values.last - values.first;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _chartHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < points.length; i++) ...[
                if (i > 0) 8.pw,
                Expanded(
                  child: _Bar(
                    heightFactor: _heightFactor(values[i], minValue, range),
                    maxHeight: _chartHeight,
                    isCurrent: i == points.length - 1,
                  ),
                ),
              ],
            ],
          ),
        ),
        10.ph,
        Row(
          children: [
            for (var i = 0; i < points.length; i++) ...[
              if (i > 0) 8.pw,
              Expanded(
                child: Text(
                  DateFormatter.shortMonth(points[i].month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
        14.ph,
        Row(
          children: [
            Expanded(
              child: Text(
                'Sur ${points.length} mois',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12.5,
                ),
              ),
            ),
            Text(
              currency.format(variation, withSign: true),
              style: TextStyle(
                color: variation < 0
                    ? AppColors.error
                    : AppColors.success.forBrightness(theme.brightness),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Positionne la valeur entre [_minHeightFactor] et 1.
  double _heightFactor(double value, double minValue, double range) {
    if (range <= 0) return 0.6;
    return _minHeightFactor +
        ((value - minValue) / range) * (1 - _minHeightFactor);
  }
}

/// Barre verticale d'un point d'historique.
class _Bar extends StatelessWidget {
  const _Bar({
    required this.heightFactor,
    required this.maxHeight,
    required this.isCurrent,
  });

  final double heightFactor;
  final double maxHeight;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: maxHeight * heightFactor,
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.primary
            : AppColors.textMuted.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
