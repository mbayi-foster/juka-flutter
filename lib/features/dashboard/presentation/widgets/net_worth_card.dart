import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/dashboard/domain/entities/net_worth.dart';
import 'package:juka/shared/widget/trend_badge.dart';
import 'package:juka/shared/utils/color_extension.dart';
import 'package:juka/shared/utils/money_formatter.dart';
import 'package:juka/shared/widget/app_card.dart';
import 'package:juka/shared/widget/padding.dart';

/// Carte principale : patrimoine net actuel et évolution sur un mois.
class NetWorthCard extends StatelessWidget {
  const NetWorthCard({
    super.key,
    required this.netWorth,
    required this.currency,
  });

  final NetWorth netWorth;

  /// Devise des montants affichés.
  final AppCurrency currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final changeColor = (netWorth.isUp ? AppColors.success : AppColors.error)
        .forBrightness(theme.brightness);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Patrimoine net',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TrendBadge(ratio: netWorth.changeRatio),
            ],
          ),
          14.ph,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              currency.format(netWorth.amount),
              style: TextStyle(
                color: isDark ? AppColors.textWhite : AppColors.textDark,
                fontSize: 34,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ),
          10.ph,
          Row(
            children: [
              Icon(
                netWorth.isUp
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 15,
                color: changeColor,
              ),
              4.pw,
              Expanded(
                child: Text(
                  '${currency.format(netWorth.change, withSign: true)} '
                  'sur un mois',
                  style: TextStyle(
                    color: changeColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          16.ph,
          const Divider(height: 1),
          14.ph,
          Text(
            'Il y a un mois : ${currency.format(netWorth.previousAmount)}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
