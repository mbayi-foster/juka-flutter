import 'package:flutter/material.dart';
import 'package:juka/common/constants/account_type_visuals.dart';
import 'package:juka/common/enums/account_type.dart';
import 'package:juka/shared/widget/choice_chip_tile.dart';

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
          ChoiceChipTile(
            label: type.label,
            icon: AccountTypeVisuals.iconOf(type),
            accent: AccountTypeVisuals.colorOf(type),
            isSelected: type == value,
            onTap: () => onChanged(type),
          ),
      ],
    );
  }
}
