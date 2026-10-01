import 'package:juka/features/reports/domain/entities/report_period.dart';

/// Périodes proposées par défaut sur l'écran « Rapports et analyses ».
enum ReportPeriodPreset {
  thisMonth('Ce mois-ci'),
  lastMonth('Le mois dernier'),
  last3Months('3 mois'),
  last6Months('6 mois'),
  last12Months('12 mois'),
  thisYear('Cette année'),
  custom('Personnalisée');

  const ReportPeriodPreset(this.label);

  /// Libellé affiché dans les pastilles de période.
  final String label;

  bool get isCustom => this == ReportPeriodPreset.custom;

  /// Convertit le choix en intervalle daté, par rapport à [now].
  ///
  /// Les bornes sont incluses : le premier jour du premier mois à minuit et le
  /// dernier jour du dernier mois à 23:59:59, ce qui permet de filtrer
  /// directement les opérations.
  ReportPeriod resolve(DateTime now) {
    final endOfCurrentMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final (start, end) = switch (this) {
      // Une période personnalisée est fournie par l'utilisateur : à défaut, on
      // retombe sur le mois en cours.
      ReportPeriodPreset.thisMonth || ReportPeriodPreset.custom => (
        DateTime(now.year, now.month),
        endOfCurrentMonth,
      ),
      ReportPeriodPreset.lastMonth => (
        DateTime(now.year, now.month - 1),
        DateTime(now.year, now.month, 0, 23, 59, 59),
      ),
      ReportPeriodPreset.last3Months => (
        DateTime(now.year, now.month - 2),
        endOfCurrentMonth,
      ),
      ReportPeriodPreset.last6Months => (
        DateTime(now.year, now.month - 5),
        endOfCurrentMonth,
      ),
      ReportPeriodPreset.last12Months => (
        DateTime(now.year, now.month - 11),
        endOfCurrentMonth,
      ),
      ReportPeriodPreset.thisYear => (DateTime(now.year), endOfCurrentMonth),
    };

    return ReportPeriod(start: start, end: end, preset: this);
  }
}
