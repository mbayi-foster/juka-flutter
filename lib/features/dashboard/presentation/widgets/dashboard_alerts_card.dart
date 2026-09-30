import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/features/dashboard/domain/entities/dashboard_alert.dart';
import 'package:juka/shared/utils/color_extension.dart';
import 'package:juka/shared/widget/app_card.dart';
import 'package:juka/shared/widget/empty_message.dart';
import 'package:juka/shared/widget/padding.dart';

/// Alertes du tableau de bord (budget dépassé, échéances, objectifs…).
class DashboardAlertsCard extends StatelessWidget {
  const DashboardAlertsCard({super.key, required this.alerts});

  final List<DashboardAlert> alerts;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'Alertes',
      icon: Icons.notifications_active_rounded,
      trailing: alerts.isEmpty ? null : _CountBadge(count: alerts.length),
      child: alerts.isEmpty
          ? const EmptyMessage(
              message: 'Aucune alerte pour le moment.',
              icon: Icons.check_circle_outline_rounded,
            )
          : Column(
              children: [
                for (var i = 0; i < alerts.length; i++) ...[
                  if (i > 0) 12.ph,
                  _AlertTile(alert: alerts[i]),
                ],
              ],
            ),
    );
  }
}

/// Nombre d'alertes affiché dans l'en-tête de la carte.
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: AppColors.error.forBrightness(Theme.of(context).brightness),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Bandeau d'une alerte, coloré selon sa gravité.
class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});

  final DashboardAlert alert;

  Color get _baseColor => switch (alert.severity) {
    AlertSeverity.info => AppColors.info,
    AlertSeverity.success => AppColors.success,
    AlertSeverity.warning => AppColors.warning,
    AlertSeverity.danger => AppColors.error,
  };

  IconData get _icon => switch (alert.severity) {
    AlertSeverity.info => Icons.info_outline_rounded,
    AlertSeverity.success => Icons.check_circle_outline_rounded,
    AlertSeverity.warning => Icons.warning_amber_rounded,
    AlertSeverity.danger => Icons.error_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _baseColor.forBrightness(theme.brightness);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _baseColor.withValues(alpha: isDark ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(AppSize.radius),
        border: Border.all(
          color: _baseColor.withValues(alpha: isDark ? 0.4 : 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, size: 18, color: color),
          10.pw,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: TextStyle(
                    color: isDark ? AppColors.textWhite : AppColors.textDark,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                4.ph,
                Text(
                  alert.message,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
