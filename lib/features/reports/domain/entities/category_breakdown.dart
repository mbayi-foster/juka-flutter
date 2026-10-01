/// Dépenses cumulées d'une catégorie (sous-catégories regroupées).
class CategoryBreakdown {
  const CategoryBreakdown({
    required this.categoryId,
    required this.name,
    required this.colorHex,
    required this.iconKey,
    required this.amount,
    required this.share,
    required this.previousAmount,
  });

  /// Identifiant de la catégorie **racine**.
  final String categoryId;

  /// Nom affichable, même si la catégorie a été supprimée depuis.
  final String name;

  /// Couleur ARGB stockée en base (`0xFF2E7D32`).
  final int colorHex;

  /// Clé d'icône du catalogue `CategoryVisuals`.
  final String iconKey;

  /// Montant dépensé sur la période.
  final double amount;

  /// Part de ces dépenses dans le total (`0.396` = 39,6 %).
  final double share;

  /// Montant dépensé sur la période précédente (base de comparaison).
  final double previousAmount;

  /// Écart en valeur absolue par rapport à la période précédente.
  double get variation => amount - previousAmount;

  /// Écart relatif ; `null` si rien n'avait été dépensé avant.
  double? get variationRatio =>
      previousAmount.abs() < 0.005 ? null : variation / previousAmount.abs();

  /// `true` si la catégorie coûte plus cher qu'avant.
  bool get hasIncreased => variation > 0.005;
}
