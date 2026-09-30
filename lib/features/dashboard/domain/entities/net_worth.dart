/// Patrimoine net (actifs - dettes) et son évolution sur un mois.
class NetWorth {
  const NetWorth({required this.amount, required this.previousAmount});

  /// Montant actuel. Peut être négatif si les dettes dépassent les actifs.
  final double amount;

  /// Montant à la même période le mois précédent.
  final double previousAmount;

  /// Variation absolue depuis le mois précédent.
  double get change => amount - previousAmount;

  /// Variation relative (`0.032` = +3,2 %).
  double get changeRatio => previousAmount == 0 ? 0 : change / previousAmount;

  /// `true` lorsque le patrimoine progresse.
  bool get isUp => change >= 0;
}
