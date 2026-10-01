/// Budget mensuel associé à une catégorie de dépense.
class Budget {
  const Budget({
    required this.categoryId,
    required this.monthlyLimit,
    this.carryOver = false,
    this.updatedAt,
  });

  final String categoryId;

  /// Enveloppe allouée chaque mois.
  final double monthlyLimit;

  /// `true` lorsque le reste du mois précédent est ajouté à l'enveloppe du
  /// mois courant.
  final bool carryOver;

  final DateTime? updatedAt;

  Budget copyWith({
    double? monthlyLimit,
    bool? carryOver,
    DateTime? updatedAt,
  }) {
    return Budget(
      categoryId: categoryId,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      carryOver: carryOver ?? this.carryOver,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
