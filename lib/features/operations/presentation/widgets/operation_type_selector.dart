import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/enums/operation_type.dart';
import 'package:juka/shared/widget/choice_chip_tile.dart';

/// Sélecteur du sens d'une opération : dépense, revenu ou transfert.
class OperationTypeSelector extends StatelessWidget {
  const OperationTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.includeTransfer = true,
  });

  final OperationType value;
  final ValueChanged<OperationType> onChanged;

  /// Masque le transfert lorsque le contexte ne s'y prête pas.
  final bool includeTransfer;

  /// Couleur associée à un type d'opération.
  static Color colorOf(OperationType type) => switch (type) {
    OperationType.income => AppColors.success,
    OperationType.expense => AppColors.error,
    OperationType.transfer => AppColors.info,
  };

  /// Icône associée à un type d'opération.
  static IconData iconOf(OperationType type) => switch (type) {
    OperationType.income => Icons.south_west_rounded,
    OperationType.expense => Icons.north_east_rounded,
    OperationType.transfer => Icons.swap_horiz_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final types = [
      OperationType.expense,
      OperationType.income,
      if (includeTransfer) OperationType.transfer,
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final type in types)
          ChoiceChipTile(
            label: type.label,
            icon: iconOf(type),
            accent: colorOf(type),
            isSelected: type == value,
            onTap: () => onChanged(type),
          ),
      ],
    );
  }
}
