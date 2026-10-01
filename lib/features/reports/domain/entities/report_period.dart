import 'package:juka/features/reports/domain/enums/report_period_preset.dart';
import 'package:juka/shared/utils/date_formatter.dart';

/// Intervalle de temps couvert par un rapport (bornes incluses).
class ReportPeriod {
  const ReportPeriod({
    required this.start,
    required this.end,
    this.preset = ReportPeriodPreset.custom,
  });

  /// Premier instant inclus de la période.
  final DateTime start;

  /// Dernier instant inclus de la période.
  final DateTime end;

  /// Choix de l'utilisateur à l'origine de cette période.
  final ReportPeriodPreset preset;

  /// Premier jour du premier mois couvert, à minuit.
  DateTime get firstDay => DateTime(start.year, start.month, start.day);

  /// Nombre de jours calendaires couverts (bornes incluses).
  int get dayCount => end.difference(firstDay).inDays + 1;

  /// Nombre de mois calendaires touchés, même partiellement.
  int get monthCount =>
      (end.year - start.year) * 12 + (end.month - start.month) + 1;

  /// Premier jour de chaque mois couvert, du plus ancien au plus récent.
  List<DateTime> get months => [
    for (var index = 0; index < monthCount; index++)
      DateTime(start.year, start.month + index),
  ];

  /// Période comparable la plus récente : celle qui précède immédiatement.
  ///
  /// Elle sert de base aux variations affichées (« +12 % vs période
  /// précédente »). Une période d'un mois est donc comparée au mois précédent,
  /// une période de trois mois aux trois mois précédents.
  ReportPeriod get previous => ReportPeriod(
    preset: preset,
    start: DateTime(start.year, start.month - monthCount),
    end: firstDay.subtract(const Duration(seconds: 1)),
  );

  bool contains(DateTime date) => !date.isBefore(start) && !date.isAfter(end);

  /// `septembre 2026`, `1 – 30 sept. 2026` ou `1 juil. – 30 sept. 2026`.
  String get rangeLabel {
    final lastDayOfMonth = DateTime(start.year, start.month + 1, 0);
    final coversWholeMonth =
        start.day == 1 &&
        end.day == lastDayOfMonth.day &&
        end.month == start.month;
    if (coversWholeMonth) return DateFormatter.monthYear(start);

    final startLabel =
        '${start.day} ${DateFormatter.shortMonth(start)} ${start.year}';
    if (start.year == end.year && start.month == end.month) {
      return '${start.day} – ${end.day} ${DateFormatter.shortMonth(end)} ${end.year}';
    }
    return '$startLabel – ${end.day} '
        '${DateFormatter.shortMonth(end)} ${end.year}';
  }

  /// Libellé principal : le choix de l'utilisateur, ou la plage pour une
  /// période personnalisée.
  String get label => preset.isCustom ? rangeLabel : preset.label;
}
