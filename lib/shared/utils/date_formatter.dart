/// Formatage des dates en français, sans dépendance externe.
abstract final class DateFormatter {
  static const List<String> _shortMonths = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];

  static const List<String> _longMonths = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];

  /// `12 sept.`, ou `aujourd'hui` / `hier` si la date est proche de [now].
  static String shortDate(DateTime date, {DateTime? now}) {
    final reference = _dayOnly(now ?? DateTime.now());
    final target = _dayOnly(date);

    return switch (reference.difference(target).inDays) {
      0 => 'aujourd\'hui',
      1 => 'hier',
      _ => '${date.day} ${_shortMonths[date.month - 1]}',
    };
  }

  /// `septembre 2026`.
  static String monthYear(DateTime date) =>
      '${_longMonths[date.month - 1]} ${date.year}';

  /// `sept.` — mois abrégé, sans le quantième.
  static String shortMonth(DateTime date) => _shortMonths[date.month - 1];

  /// `sept. 2026` — mois abrégé suivi de l'année.
  static String shortMonthYear(DateTime date) =>
      '${shortMonth(date)} ${date.year}';

  /// `05/09/2026` — format numérique, utilisé par les exports.
  static String numeric(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  /// `05/09/2026 14:32` — horodatage, utilisé par les exports.
  static String numericWithTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${numeric(date)} $hour:$minute';
  }

  static DateTime _dayOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
