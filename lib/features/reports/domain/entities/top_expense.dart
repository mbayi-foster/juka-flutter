/// Une des plus grosses dépenses de la période.
class TopExpense {
  const TopExpense({
    required this.operationId,
    required this.label,
    required this.amount,
    required this.date,
    required this.categoryName,
    required this.categoryColorHex,
    required this.categoryIconKey,
    required this.accountName,
    required this.share,
  });

  final String operationId;

  /// Libellé saisi par l'utilisateur (ex. « Loyer septembre »).
  final String label;

  final double amount;
  final DateTime date;

  /// Nom de la catégorie racine de l'opération.
  final String categoryName;

  final int categoryColorHex;
  final String categoryIconKey;

  /// Compte débité.
  final String accountName;

  /// Part de cette dépense dans le total des dépenses de la période.
  final double share;
}
