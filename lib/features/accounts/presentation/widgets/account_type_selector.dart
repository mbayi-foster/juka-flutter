import 'package:flutter/material.dart';
import 'package:juka/common/constants/account_type_visuals.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/size.dart';
import 'package:juka/common/enums/account_type.dart';
import 'package:juka/shared/utils/color_extension.dart';
import 'package:juka/shared/widget/padding.dart';

/// Sélecteur du type de compte, sous forme de pastilles.
class AccountTypeSelector extends StatelessWidget {
  const AccountTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final AccountType value;
  final ValueChanged<AccountType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final type in AccountType.values)
          _TypeChip(
            type: type,
            isSelected: type == value,
            onTap: () => onChanged(type),
          ),
      ],
    );
  }
}

/// Pastille sélectionnable d'un type de compte.
class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  final AccountType type;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AccountTypeVisuals.colorOf(type);
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
            Icon(
              AccountTypeVisuals.iconOf(type),
              size: 17,
              color: isSelected
                  ? accent.forBrightness(theme.brightness)
                  : AppColors.textMuted,
            ),
            8.pw,
            Text(
              type.label,
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
