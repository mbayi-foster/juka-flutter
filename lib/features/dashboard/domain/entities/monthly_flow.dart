/// Flux financiers du mois en cours (revenus, dépenses, épargne).
class MonthlyFlow {
  const MonthlyFlow({
    required this.income,
    required this.expenses,
    this.savingsGoal = 0,
  });

  /// Total des revenus encaissés sur le mois.
  final double income;

  /// Total des dépenses du mois.
  final double expenses;

  /// Objectif d'épargne fixé par l'utilisateur (`0` = aucun objectif).
  final double savingsGoal;

  /// Épargne réalisée : la différence est calculée ici pour garantir la
  /// cohérence entre les trois montants affichés.
  double get savings => income - expenses;

  /// Taux d'épargne (`0.33` = 33 %).
  double get savingsRate => income == 0 ? 0 : savings / income;

  /// Avancement vers l'objectif d'épargne (`0` si aucun objectif).
  double get savingsGoalRatio => savingsGoal <= 0 ? 0 : savings / savingsGoal;

  /// `true` lorsque l'épargne du mois est positive.
  bool get hasPositiveSavings => savings >= 0;
}
