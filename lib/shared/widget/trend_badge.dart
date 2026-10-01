import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/shared/utils/color_extension.dart';
import 'package:juka/shared/utils/money_formatter.dart';
import 'package:juka/shared/widget/padding.dart';

/// Pastille indiquant une évolution (hausse ou baisse) en pourcentage.
///
/// Partagée par le tableau de bord (patrimoine net : une hausse est une bonne
/// nouvelle) et par les rapports (dépenses : une hausse est au contraire un
/// signal d'alerte). [isInverted] inverse la couleur sans changer la flèche.
class TrendBadge extends StatelessWidget {
  const TrendBadge({super.key, required this.ratio, this.isInverted = false});

  /// Variation relative (`0.032` = +3,2 %).
  final double ratio;

  /// `true` lorsque la hausse doit s'afficher en rouge (montants dépensés).
  final bool isInverted;

  @override
  Widget build(BuildContext context) {
    final isUp = ratio >= 0;
    final isFavourable = isInverted ? !isUp : isUp;
    final color = (isFavourable ? AppColors.success : AppColors.error)
        .forBrightness(Theme.of(context).brightness);

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
            isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 16,
            color: color,
          ),
          6.pw,
          Text(
            MoneyFormatter.percent(ratio),
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
