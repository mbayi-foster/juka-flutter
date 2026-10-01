import 'package:juka/features/reports/domain/entities/expense_report.dart';
import 'package:juka/features/reports/domain/entities/exported_report.dart';
import 'package:juka/features/reports/domain/enums/report_export_format.dart';

/// Contrat d'export d'un rapport.
///
/// L'implémentation connaît les formats de fichier et le stockage de
/// l'appareil ; le domaine se contente de demander « le rapport en PDF » ou
/// « le rapport en tableau ».
abstract interface class ReportExporter {
  /// Écrit le rapport au format demandé et ouvre la feuille de partage du
  /// système.
  ///
  /// Échoue avec une `ReportsFailure` si le fichier ne peut pas être écrit.
  Future<ExportedReport> export({
    required ExpenseReport report,
    required ReportExportFormat format,
  });
}
