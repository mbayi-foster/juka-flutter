import 'package:juka/features/reports/domain/entities/expense_report.dart';
import 'package:juka/features/reports/domain/entities/exported_report.dart';
import 'package:juka/features/reports/domain/enums/report_export_format.dart';
import 'package:juka/features/reports/domain/services/report_exporter.dart';

/// Exporte un rapport (PDF ou Excel / CSV) sur l'appareil.
///
/// Le fichier est écrit dans le stockage privé de l'application puis proposé
/// au partage : l'utilisateur choisit lui-même où l'enregistrer (Fichiers,
/// Drive, e-mail…).
class ExportExpenseReportUseCase {
  const ExportExpenseReportUseCase(this._reportExporter);

  final ReportExporter _reportExporter;

  Future<ExportedReport> call({
    required ExpenseReport report,
    required ReportExportFormat format,
  }) => _reportExporter.export(report: report, format: format);
}
