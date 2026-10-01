/// Sens d'évolution des dépenses sur les derniers mois.
enum TrendDirection {
  up('En hausse', 'Vos dépenses augmentent par rapport aux mois précédents.'),
  down('En baisse', 'Vos dépenses diminuent par rapport aux mois précédents.'),
  stable('Stable', 'Vos dépenses sont stables sur les derniers mois.');

  const TrendDirection(this.label, this.message);

  /// Libellé court affiché dans la pastille de tendance.
  final String label;

  /// Phrase explicative affichée sous le libellé.
  final String message;

  bool get isIncrease => this == TrendDirection.up;
}
