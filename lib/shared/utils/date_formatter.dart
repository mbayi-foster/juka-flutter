import 'package:juka/common/enums/app_date_format.dart';
import 'package:juka/common/enums/app_language.dart';

/// Formatage des dates, sans dépendance externe.
///
/// La langue et l'ordre des dates sont appliqués par toute l'application : ils
/// sont renseignés au démarrage depuis les préférences (voir
/// `SettingsController`) puis à chaque changement dans l'écran Paramètres. Un
/// état statique évite de faire descendre les préférences jusqu'à chaque widget
/// qui affiche une date.
abstract final class DateFormatter {
  /// Langue utilisée pour les noms de mois et les dates relatives.
  static AppLanguage language = AppLanguage.french;

  /// Ordre d'écriture des dates numériques.
  static AppDateFormat dateOrder = AppDateFormat.dayFirst;

  /// Applique les préférences d'affichage des dates.
  static void configure({AppLanguage? language, AppDateFormat? dateOrder}) {
    if (language != null) DateFormatter.language = language;
    if (dateOrder != null) DateFormatter.dateOrder = dateOrder;
  }

  static const List<String> _shortMonthsFr = [
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

  static const List<String> _longMonthsFr = [
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

  static const List<String> _shortMonthsEn = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const List<String> _longMonthsEn = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static List<String> get _shortMonths =>
      language == AppLanguage.french ? _shortMonthsFr : _shortMonthsEn;

  static List<String> get _longMonths =>
      language == AppLanguage.french ? _longMonthsFr : _longMonthsEn;

  /// `12 sept.`, ou `aujourd'hui` / `hier` si la date est proche de [now].
  static String shortDate(DateTime date, {DateTime? now}) {
    final reference = _dayOnly(now ?? DateTime.now());
    final target = _dayOnly(date);
    final isFrench = language == AppLanguage.french;

    return switch (reference.difference(target).inDays) {
      0 => isFrench ? 'aujourd\'hui' : 'today',
      1 => isFrench ? 'hier' : 'yesterday',
      _ => '${date.day} ${_shortMonths[date.month - 1]}',
    };
  }

  /// `septembre 2026` (ou `September 2026`).
  static String monthYear(DateTime date) =>
      '${_longMonths[date.month - 1]} ${date.year}';

  /// `sept.` — mois abrégé, sans le quantième.
  static String shortMonth(DateTime date) => _shortMonths[date.month - 1];

  /// `sept. 2026` — mois abrégé suivi de l'année.
  static String shortMonthYear(DateTime date) =>
      '${shortMonth(date)} ${date.year}';

  /// `05/09/2026` — date numérique, selon l'ordre choisi par l'utilisateur.
  static String numeric(DateTime date) => dateOrder.format(date);

  /// `05/09/2026 14:32` — horodatage, utilisé par les exports.
  static String numericWithTime(DateTime date) =>
      dateOrder.formatWithTime(date);

  static DateTime _dayOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
