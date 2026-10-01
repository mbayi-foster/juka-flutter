import 'package:juka/common/enums/account_type.dart';

/// Flux d'un compte sur la période analysée.
class AccountBreakdown {
  const AccountBreakdown({
    required this.accountId,
    required this.name,
    required this.type,
    required this.expenses,
    required this.income,
    required this.operationCount,
  });

  final String accountId;

  /// Nom du compte au moment de l'export.
  final String name;

  final AccountType type;

  /// Dépenses passées sur ce compte.
  final double expenses;

  /// Revenus encaissés sur ce compte.
  final double income;

  final int operationCount;

  /// Flux net : positif si le compte s'est enrichi sur la période.
  double get net => income - expenses;

  bool get isNetPositive => net >= 0;
}
