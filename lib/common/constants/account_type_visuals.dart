import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/common/enums/account_type.dart';

/// Identité visuelle (icône + couleur) de chaque [AccountType].
///
/// Centraliser ces correspondances évite de dupliquer des `switch` dans les
/// écrans qui listent des comptes.
abstract final class AccountTypeVisuals {
  static IconData iconOf(AccountType type) => switch (type) {
    AccountType.bank => Icons.account_balance_rounded,
    AccountType.mobileMoney => Icons.smartphone_rounded,
    AccountType.cash => Icons.payments_rounded,
    AccountType.savings => Icons.savings_rounded,
    AccountType.debt => Icons.credit_card_rounded,
    AccountType.receivable => Icons.handshake_rounded,
  };

  static Color colorOf(AccountType type) => switch (type) {
    AccountType.bank => AppColors.accountBank,
    AccountType.mobileMoney => AppColors.accountMobileMoney,
    AccountType.cash => AppColors.accountCash,
    AccountType.savings => AppColors.accountSavings,
    AccountType.debt => AppColors.accountDebt,
    AccountType.receivable => AppColors.accountReceivable,
  };
}
