/// Indicateurs de progression du patrimoine.
class WealthIndicators {
  const WealthIndicators({
    this.savingsRate,
    this.emergencyFundMonths,
    this.debtRatio,
    this.monthlyExpenses = 0,
    this.liquidAssets = 0,
  });

  /// Seuil recommandé pour le fonds d'urgence (mois de dépenses couverts).
  static const double recommendedEmergencyMonths = 3;

  /// Ratio d'endettement au-delà duquel la situation est fragile.
  static const double maxHealthyDebtRatio = 0.5;

  /// Part des revenus du mois épargnée (`0.33` = 33 %), `null` sans revenu.
  final double? savingsRate;

  /// Mois de dépenses couverts par les actifs mobilisables, `null` si les
  /// dépenses du mois sont inconnues.
  final double? emergencyFundMonths;

  /// Part des dettes dans les actifs (`0.25` = 25 %), `null` sans actif.
  final double? debtRatio;

  /// Dépenses du mois en cours (transferts exclus).
  final double monthlyExpenses;

  /// Actifs mobilisables : comptes courants, mobile money, espèces, épargne.
  final double liquidAssets;

  /// Fonds d'urgence suffisant (au moins [recommendedEmergencyMonths] mois).
  bool get hasEmergencyFund =>
      (emergencyFundMonths ?? 0) >= recommendedEmergencyMonths;

  /// Endettement dans les limites recommandées.
  bool get isDebtHealthy =>
      debtRatio == null || debtRatio! <= maxHealthyDebtRatio;

  /// Épargne positive sur le mois.
  bool get isSaving => (savingsRate ?? 0) > 0;
}
