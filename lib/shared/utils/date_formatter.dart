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

  static DateTime _dayOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
