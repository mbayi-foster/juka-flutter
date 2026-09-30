/// Périodicité d'une opération récurrente (loyer, salaire, abonnements…).
enum RecurrenceFrequency {
  daily('Quotidienne'),
  weekly('Hebdomadaire'),
  monthly('Mensuelle'),
  quarterly('Trimestrielle'),
  yearly('Annuelle');

  const RecurrenceFrequency(this.label);

  /// Libellé affichable à l'utilisateur.
  final String label;

  /// Date de l'échéance suivant [date].
  ///
  /// Un mois sans le quantième (le 31 dans un mois de 30 jours) est reporté au
  /// premier jour du mois suivant, comportement de `DateTime`.
  DateTime next(DateTime date) => switch (this) {
    RecurrenceFrequency.daily => date.add(const Duration(days: 1)),
    RecurrenceFrequency.weekly => date.add(const Duration(days: 7)),
    RecurrenceFrequency.monthly => DateTime(
      date.year,
      date.month + 1,
      date.day,
    ),
    RecurrenceFrequency.quarterly => DateTime(
      date.year,
      date.month + 3,
      date.day,
    ),
    RecurrenceFrequency.yearly => DateTime(date.year + 1, date.month, date.day),
  };
}
