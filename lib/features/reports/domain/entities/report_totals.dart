/// Chiffres clés du rapport, sur la période et sur la période précédente.
class ReportTotals {
  const ReportTotals({
    required this.income,
    required this.expenses,
    required this.previousIncome,
    required this.previousExpenses,
    required this.operationCount,
    required this.dayCount,
    required this.monthCount,
  });

  /// Revenus encaissés sur la période.
  final double income;

  /// Dépenses engagées sur la période.
  final double expenses;

  /// Revenus de la période précédente (base de comparaison).
  final double previousIncome;

  /// Dépenses de la période précédente (base de comparaison).
  final double previousExpenses;

  /// Nombre d'opérations comptabilisées (transferts exclus).
  final int operationCount;

  final int dayCount;
  final int monthCount;

  /// Épargne de la période (revenus − dépenses).
  double get savings => income - expenses;

  /// Part des revenus non dépensée (`0.32` = 32 %).
  double get savingsRate => income <= 0 ? 0 : savings / income;

  /// Dépense moyenne par jour.
  double get dailyAverage => dayCount <= 0 ? 0 : expenses / dayCount;

  /// Dépense moyenne par mois.
  double get monthlyAverage => monthCount <= 0 ? 0 : expenses / monthCount;

  double? get expensesChangeRatio => _ratio(previousExpenses, expenses);

  double? get incomeChangeRatio => _ratio(previousIncome, income);

  double? get savingsChangeRatio =>
      _ratio(previousIncome - previousExpenses, savings);

  /// Variation relative ; `null` quand la base de comparaison est nulle ou
  /// absente (le pourcentage n'aurait alors aucun sens).
  static double? _ratio(double reference, double value) =>
      reference.abs() < 0.005 ? null : (value - reference) / reference.abs();
}
