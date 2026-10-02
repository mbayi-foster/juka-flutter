/// Ordre d'écriture d'une date numérique.
///
/// S'applique aux dates affichées et exportées (PDF, CSV). Les dates longues
/// (« 12 sept. ») suivent la langue choisie.
enum AppDateFormat {
  dayFirst('Jour/Mois/Année', '31/12/2026'),
  monthFirst('Mois/Jour/Année', '12/31/2026'),
  iso('Année-Mois-Jour', '2026-12-31');

  const AppDateFormat(this.label, this.example);

  /// Libellé affiché à l'utilisateur.
  final String label;

  /// Exemple affiché sous le libellé.
  final String example;

  /// Valeur enregistrée en base.
  String get storageKey => name;

  /// Écrit une date selon l'ordre choisi.
  String format(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return switch (this) {
      AppDateFormat.dayFirst => '$day/$month/${date.year}',
      AppDateFormat.monthFirst => '$month/$day/${date.year}',
      AppDateFormat.iso => '${date.year}-$month-$day',
    };
  }

  /// Écrit une date suivie de l'heure (`31/12/2026 14:32`).
  String formatWithTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${format(date)} $hour:$minute';
  }

  /// Relit une préférence stockée ; retombe sur jour/mois/année.
  static AppDateFormat fromStorage(String? value) {
    for (final format in AppDateFormat.values) {
      if (format.storageKey == value) return format;
    }
    return AppDateFormat.dayFirst;
  }
}
