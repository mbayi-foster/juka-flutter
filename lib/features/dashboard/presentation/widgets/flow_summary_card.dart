import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/dashboard/domain/entities/monthly_flow.dart';
import 'package:juka/shared/utils/color_extension.dart';
import 'package:juka/shared/utils/date_formatter.dart';
import 'package:juka/shared/utils/money_formatter.dart';
import 'package:juka/shared/widget/app_card.dart';
import 'package:juka/shared/widget/padding.dart';

/// Revenus, dépenses et épargne du mois affiché.
class FlowSummaryCard extends StatelessWidget {
  const FlowSummaryCard({
    super.key,
    required this.flow,
    required this.period,
    required this.currency,
  });

  final MonthlyFlow flow;

  /// Mois concerné (premier jour du mois).
  final DateTime period;

  /// Devise des montants affichés.
  final AppCurrency currency;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'Ce mois-ci',
      icon: Icons.calendar_month_rounded,
      trailing: Text(
        DateFormatter.monthYear(period),
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _FlowStatTile(
                    label: 'Revenus',
                    amount: flow.income,
                    currency: currency,
                    icon: Icons.south_west_rounded,
                    color: AppColors.success,
                  ),
                ),
                12.pw,
                Expanded(
                  child: _FlowStatTile(
                    label: 'Dépenses',
                    amount: flow.expenses,
                    currency: currency,
                    icon: Icons.north_east_rounded,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          12.ph,
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _FlowStatTile(
                    label: 'Épargne',
                    amount: flow.savings,
                    currency: currency,
                    icon: Icons.savings_rounded,
                    color: AppColors.primary,
                  ),
                ),
                12.pw,
                Expanded(child: _SavingsRateTile(flow: flow)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tuile d'un montant du mois (revenus, dépenses ou épargne).
class _FlowStatTile extends StatelessWidget {
  const _FlowStatTile({
    required this.label,
    required this.amount,
    required this.currency,
    required this.icon,
    required this.color,
  });

  final String label;
  final double amount;
  final AppCurrency currency;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _StatTile(
      label: label,
      accent: color,
      leading: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 16,
          color: color.forBrightness(theme.brightness),
        ),
      ),
      value: currency.format(amount),
    );
  }
}

/// Tuile affichant le taux d'épargne avec une jauge.
class _SavingsRateTile extends StatelessWidget {
  const _SavingsRateTile({required this.flow});

  final MonthlyFlow flow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return _StatTile(
      label: 'Taux d\'épargne',
      accent: AppColors.info,
      value: MoneyFormatter.percent(flow.savingsRate, withSign: false),
      footer: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: flow.savingsRate.clamp(0.0, 1.0),
          minHeight: 6,
          backgroundColor: isDark
              ? AppColors.borderDark
              : AppColors.backgroundWhite,
          color: AppColors.info.forBrightness(theme.brightness),
        ),
      ),
    );
  }
}

/// Base commune aux tuiles du résumé : fond teinté, label puis valeur.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.accent,
    required this.value,
    this.leading,
    this.footer,
  });

  final String label;
  final Color accent;
  final String value;
  final Widget? leading;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSize.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (leading != null) ...[leading!, 8.pw],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          10.ph,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: theme.brightness == Brightness.dark
                    ? AppColors.textWhite
                    : AppColors.textDark,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (footer != null) ...[10.ph, footer!],
        ],
      ),
    );
  }
}
