/// Comparaison d'un mois avec le mois qui le précède.
class MonthlyComparison {
  const MonthlyComparison({
    required this.month,
    required this.income,
    required this.expenses,
    this.previousExpenses,
  });

  /// Premier jour du mois concerné.
  final DateTime month;

  final double income;
  final double expenses;

  /// Dépenses du mois précédent, `null` si ce mois est hors de la fenêtre
  /// analysée.
  final double? previousExpenses;

  /// Solde du mois (revenus − dépenses).
  double get savings => income - expenses;

  bool get hasData => income != 0 || expenses != 0;

  /// Variation des dépenses par rapport au mois précédent.
  double? get expensesChangeRatio {
    final reference = previousExpenses;
    if (reference == null || reference.abs() < 0.005) return null;
    return (expenses - reference) / reference.abs();
  }
}
