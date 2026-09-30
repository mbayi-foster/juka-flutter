import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/category_visuals.dart';
import 'package:juka/features/dashboard/domain/entities/recent_operation.dart';
import 'package:juka/shared/utils/color_extension.dart';
import 'package:juka/shared/utils/date_formatter.dart';
import 'package:juka/shared/utils/money_formatter.dart';
import 'package:juka/shared/widget/padding.dart';

/// Ligne d'opération : catégorie, libellé, date et montant signé.
class OperationTile extends StatelessWidget {
  const OperationTile({super.key, required this.operation});

  final RecentOperation operation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.textWhite : AppColors.textDark;
    final categoryColor = CategoryVisuals.colorOf(operation.category);
    final amountColor = operation.isIncome
        ? AppColors.success.forBrightness(theme.brightness)
        : titleColor;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: categoryColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            CategoryVisuals.iconOf(operation.category),
            size: 19,
            color: categoryColor.forBrightness(theme.brightness),
          ),
        ),
        12.pw,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                operation.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              4.ph,
              Text(
                '${operation.category.label} · '
                '${DateFormatter.shortDate(operation.date)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
        10.pw,
        Text(
          MoneyFormatter.currency(
            operation.signedAmount,
            withSign: operation.isIncome,
          ),
          style: TextStyle(
            color: amountColor,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
