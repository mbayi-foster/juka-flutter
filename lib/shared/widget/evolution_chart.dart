import 'dart:math';

import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/shared/utils/date_formatter.dart';
import 'package:juka/shared/widget/padding.dart';

/// Diagramme en barres d'une série de valeurs datées.
///
/// La hauteur de chaque barre est normalisée entre le minimum et le maximum de
/// la série : les variations restent lisibles même sur de petits écarts. La
/// dernière barre (valeur courante) est mise en avant.
class EvolutionChart extends StatelessWidget {
  const EvolutionChart({super.key, required this.points, this.height = 120});

  /// Série à afficher, du plus ancien au plus récent.
  final List<({DateTime date, double value})> points;

  /// Hauteur du diagramme, hors étiquettes de mois.
  final double height;

  /// Hauteur minimale d'une barre, pour rester visible.
  static const double _minHeightFactor = 0.25;

  /// Espacement horizontal entre deux barres.
  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    final values = [for (final point in points) point.value];
    final minValue = values.reduce(min);
    final maxValue = values.reduce(max);
    final range = maxValue - minValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < points.length; i++) ...[
                if (i > 0) _gap.pw,
                Expanded(
                  child: _Bar(
                    heightFactor: _heightFactor(values[i], minValue, range),
                    maxHeight: height,
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
              if (i > 0) _gap.pw,
              Expanded(
                child: Text(
                  DateFormatter.shortMonth(points[i].date),
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

/// Barre verticale d'un point de la série.
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
