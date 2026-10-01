import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/common/enums/operation_type.dart';
import 'package:juka/common/enums/transaction_category.dart';

/// Opération récente affichée dans le tableau de bord.
class RecentOperation {
  const RecentOperation({
    required this.id,
    required this.label,
    required this.category,
    required this.type,
    required this.amount,
    required this.date,
    required this.currency,
  });

  final String id;

  /// Libellé saisi par l'utilisateur (ex. « Courses alimentaires »).
  final String label;

  final TransactionCategory category;
  final OperationType type;

  /// Montant toujours positif : le sens est porté par [type].
  final double amount;

  final DateTime date;

  /// Devise du compte de l'opération : les dernières opérations peuvent
  /// provenir de comptes de devises différentes.
  final AppCurrency currency;

  bool get isIncome => type == OperationType.income;

  /// Montant signé, prêt à être formaté (`+` pour un revenu).
  double get signedAmount => isIncome ? amount : -amount;
}
