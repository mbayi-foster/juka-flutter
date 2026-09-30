/// Sens d'une opération financière.
///
/// Partagé par tous les modules (tableau de bord, opérations) afin de ne pas
/// dupliquer la notion.
enum OperationType {
  income('Revenu'),
  expense('Dépense'),
  transfer('Transfert');

  const OperationType(this.label);

  /// Libellé affichable à l'utilisateur.
  final String label;

  bool get isIncome => this == OperationType.income;

  bool get isExpense => this == OperationType.expense;

  /// Un transfert déplace de l'argent entre deux comptes de l'utilisateur : il
  /// ne compte ni comme revenu ni comme dépense dans les statistiques.
  bool get isTransfer => this == OperationType.transfer;

  /// `true` lorsque l'opération entre dans les totaux revenus / dépenses.
  bool get countsInStats => !isTransfer;
}
