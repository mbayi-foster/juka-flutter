import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/constants/category_visuals.dart';
import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/common/enums/operation_type.dart';
import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/features/operations/domain/entities/operation.dart';
import 'package:juka/features/operations/presentation/widgets/operation_type_selector.dart';
import 'package:juka/shared/utils/color_extension.dart';
import 'package:juka/shared/utils/date_formatter.dart';
import 'package:juka/shared/utils/money_formatter.dart';
import 'package:juka/shared/widget/app_card.dart';
import 'package:juka/shared/widget/padding.dart';

/// Actions proposées depuis la liste des opérations.
enum OperationAction { edit, delete }

/// Ligne d'une opération : catégorie, libellé, comptes, date et montant signé.
class OperationTile extends StatelessWidget {
  const OperationTile({
    super.key,
    required this.operation,
    required this.accounts,
    this.onTap,
    this.onAction,
  });

  final Operation operation;

  /// Comptes indexés par identifiant, pour retrouver noms et devises.
  final Map<String, Account> accounts;

  final VoidCallback? onTap;
  final ValueChanged<OperationAction>? onAction;

  Account? get _account => accounts[operation.accountId];

  Account? get _transferAccount {
    final transferAccountId = operation.transferAccountId;
    return transferAccountId == null ? null : accounts[transferAccountId];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.textWhite : AppColors.textDark;
    final accent = operation.isTransfer
        ? AppColors.info
        : CategoryVisuals.colorOf(operation.category);
    final onAction = this.onAction;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              operation.isTransfer
                  ? OperationTypeSelector.iconOf(operation.type)
                  : CategoryVisuals.iconOf(operation.category),
              size: 20,
              color: accent.forBrightness(theme.brightness),
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
                    fontWeight: FontWeight.w700,
                  ),
                ),
                4.ph,
                Text(
                  _subtitle(),
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
          8.pw,
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _currency.format(
                  operation.signedAmount,
                  withSign: operation.isIncome,
                ),
                style: TextStyle(
                  color: switch (operation.type) {
                    OperationType.income => AppColors.success.forBrightness(
                      theme.brightness,
                    ),
                    OperationType.expense => titleColor,
                    OperationType.transfer => AppColors.textMuted,
                  },
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              4.ph,
              Text(
                DateFormatter.shortDate(operation.date),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
          if (onAction != null)
            _OperationMenu(operation: operation, onAction: onAction),
        ],
      ),
    );
  }

  /// Devise de l'opération : celle de son compte, l'euro par défaut.
  AppCurrency get _currency => _account?.currency ?? AppCurrency.eur;

  String _subtitle() {
    final transferAccount = _transferAccount;
    if (operation.isTransfer && transferAccount != null) {
      return 'Vers ${transferAccount.name} · depuis ${_account?.name ?? '—'}';
    }
    if (operation.isTransfer) {
      return '${operation.category.label} · ${_account?.name ?? '—'}';
    }
    return '${operation.category.label} · ${_account?.name ?? '—'}';
  }
}

/// Menu d'actions rapides (modifier, supprimer).
class _OperationMenu extends StatelessWidget {
  const _OperationMenu({required this.operation, required this.onAction});

  final Operation operation;
  final ValueChanged<OperationAction> onAction;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<OperationAction>(
      tooltip: 'Actions',
      padding: EdgeInsets.zero,
      icon: const Icon(
        Icons.more_vert_rounded,
        size: 20,
        color: AppColors.textMuted,
      ),
      onSelected: onAction,
      itemBuilder: (context) => const [
        PopupMenuItem(value: OperationAction.edit, child: Text('Modifier')),
        PopupMenuItem(value: OperationAction.delete, child: Text('Supprimer')),
      ],
    );
  }
}
