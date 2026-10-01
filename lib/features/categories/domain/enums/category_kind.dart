/// Nature d'une catégorie.
///
/// Le sens d'une opération (revenu, dépense) reste porté par son type ; le
/// `kind` sert à filtrer les catégories proposées à l'utilisateur.
enum CategoryKind {
  expense('Dépense'),
  income('Revenu'),
  transfer('Transfert');

  const CategoryKind(this.label);

  /// Libellé affichable à l'utilisateur.
  final String label;

  /// `true` pour les catégories qui alimentent les budgets.
  bool get isBudgetable => this == CategoryKind.expense;
}
