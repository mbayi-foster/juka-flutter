import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/shared/utils/color_extension.dart';
import 'package:juka/shared/widget/padding.dart';

/// Pastille sélectionnable (filtres, types de compte ou d'opération…).
///
/// Mutualise l'apparence des sélecteurs de l'application : contour neutre au
/// repos, fond et bordure teintés lorsque la pastille est retenue.
class ChoiceChipTile extends StatelessWidget {
  const ChoiceChipTile({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.accent,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  /// Icône optionnelle affichée avant le libellé.
  final IconData? icon;

  /// Couleur d'accent utilisée lorsque la pastille est sélectionnée.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = this.accent ?? AppColors.primary;
    final icon = this.icon;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSize.radius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? accent.withValues(alpha: 0.16) : null,
          borderRadius: BorderRadius.circular(AppSize.radius),
          border: Border.all(
            color: isSelected ? accent : borderColor,
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 17,
                color: isSelected
                    ? accent.forBrightness(theme.brightness)
                    : AppColors.textMuted,
              ),
              8.pw,
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? (isDark ? AppColors.textWhite : AppColors.textDark)
                    : AppColors.textMuted,
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
