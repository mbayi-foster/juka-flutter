import 'package:juka/common/enums/transaction_category.dart';

/// Consommation d'un budget mensuel (jauge).
class BudgetProgress {
  const BudgetProgress({
    required this.category,
    required this.spent,
    required this.limit,
  });

  final TransactionCategory category;

  /// Montant déjà dépensé.
  final double spent;

  /// Enveloppe allouée pour le mois.
  final double limit;

  /// Part consommée (`1.05` = 105 %).
  double get ratio => limit <= 0 ? 0 : spent / limit;

  /// Reste disponible ; négatif en cas de dépassement.
  double get remaining => limit - spent;

  /// Le budget est dépassé.
  bool get isExceeded => spent > limit;

  /// Le budget est consommé à 80 % ou plus, sans être dépassé.
  bool get isCloseToLimit => !isExceeded && ratio >= 0.8;
}
