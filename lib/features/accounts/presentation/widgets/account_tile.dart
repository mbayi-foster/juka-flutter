import 'package:flutter/material.dart';
import 'package:juka/common/constants/account_type_visuals.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/shared/utils/color_extension.dart';
import 'package:juka/shared/utils/money_formatter.dart';
import 'package:juka/shared/widget/app_card.dart';
import 'package:juka/shared/widget/padding.dart';

/// Actions proposées depuis la liste des comptes.
enum AccountAction { edit, archive, restore }

/// Ligne d'un compte : identité, solde, état et actions rapides.
class AccountTile extends StatelessWidget {
  const AccountTile({
    super.key,
    required this.account,
    this.onTap,
    this.onAction,
  });

  final Account account;
  final VoidCallback? onTap;
  final ValueChanged<AccountAction>? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? AppColors.textWhite : AppColors.textDark;
    final accent = AccountTypeVisuals.colorOf(account.type);
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              AccountTypeVisuals.iconOf(account.type),
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
                  account.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                4.ph,
                Text(
                  '${account.type.label} · ${account.currency.code}',
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
                account.currency.format(account.currentBalance),
                style: TextStyle(
                  color: account.currentBalance < 0
                      ? AppColors.error.forBrightness(theme.brightness)
                      : titleColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              4.ph,
              _StatusLabel(account: account),
            ],
          ),
          if (onAction != null)
            _AccountMenu(account: account, onAction: onAction),
        ],
      ),
    );
  }
}

/// Résumé de l'état du compte sous son solde.
class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (account.isArchived) {
      return const Text(
        'Archivé',
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final gap = account.reconciliationGap;
    if (gap != null && !account.isReconciled) {
      return Text(
        'Écart ${account.currency.format(gap, withSign: true)}',
        style: TextStyle(
          color: AppColors.warning.forBrightness(theme.brightness),
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Text(
      account.currency.format(account.movement, withSign: true),
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Menu d'actions rapides (modifier, archiver / restaurer).
class _AccountMenu extends StatelessWidget {
  const _AccountMenu({required this.account, required this.onAction});

  final Account account;
  final ValueChanged<AccountAction> onAction;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AccountAction>(
      tooltip: 'Actions',
      padding: EdgeInsets.zero,
      icon: const Icon(
        Icons.more_vert_rounded,
        size: 20,
        color: AppColors.textMuted,
      ),
      onSelected: onAction,
      itemBuilder: (context) => [
        const PopupMenuItem(value: AccountAction.edit, child: Text('Modifier')),
        PopupMenuItem(
          value: account.isArchived
              ? AccountAction.restore
              : AccountAction.archive,
          child: Text(account.isArchived ? 'Restaurer' : 'Archiver'),
        ),
      ],
    );
  }
}
