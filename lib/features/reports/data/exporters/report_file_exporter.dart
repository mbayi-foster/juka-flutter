import 'dart:io';

import 'package:juka/features/reports/data/exporters/csv_report_builder.dart';
import 'package:juka/features/reports/data/exporters/pdf_report_builder.dart';
import 'package:juka/features/reports/domain/entities/expense_report.dart';
import 'package:juka/features/reports/domain/entities/exported_report.dart';
import 'package:juka/features/reports/domain/enums/report_export_format.dart';
import 'package:juka/features/reports/domain/failures/reports_failure.dart';
import 'package:juka/features/reports/domain/services/report_exporter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Écrit le rapport dans le stockage privé de l'application puis ouvre la
/// feuille de partage du système.
///
/// Le fichier n'est ni déposé dans la galerie ni dans les téléchargements :
/// l'utilisateur choisit lui-même la destination (Fichiers, Drive, e-mail…),
/// ce qui évite d'avoir à demander une permission de stockage.
class ReportFileExporter implements ReportExporter {
  const ReportFileExporter({this.shareAfterExport = true});

  /// Ouvre la feuille de partage une fois le fichier écrit.
  ///
  /// Passé à `false` dans les tests et lorsque seul le fichier compte.
  final bool shareAfterExport;

  /// Sous-dossier des exports, dans les documents de l'application.
  static const String folderName = 'rapports';

  static const String _writeErrorMessage =
      'Le rapport n\'a pas pu être enregistré sur l\'appareil.';
  static const String _shareErrorMessage =
      'Le rapport a bien été enregistré, mais son partage a échoué.';

  @override
  Future<ExportedReport> export({
    required ExpenseReport report,
    required ReportExportFormat format,
  }) async {
    final generatedAt = DateTime.now();
    final bytes = await _bytesOf(report, format, generatedAt);
    final fileName = format.fileNameFor(generatedAt);
    final file = await _write(fileName, bytes);

    final exported = ExportedReport(
      fileName: fileName,
      path: file.path,
      format: format,
      byteLength: bytes.length,
    );

    if (shareAfterExport) await _share(exported, report);
    return exported;
  }

  /// Contenu du fichier, selon le format demandé.
  Future<List<int>> _bytesOf(
    ExpenseReport report,
    ReportExportFormat format,
    DateTime generatedAt,
  ) async => switch (format) {
    ReportExportFormat.pdf => await PdfReportBuilder.build(
      report,
      now: generatedAt,
    ),
    ReportExportFormat.excel => CsvReportBuilder.build(
      report,
      now: generatedAt,
    ),
  };

  /// Crée le sous-dossier d'export si besoin, puis écrit le fichier.
  Future<File> _write(String fileName, List<int> bytes) async {
    try {
      final documents = await getApplicationDocumentsDirectory();
      final directory = Directory('${documents.path}/$folderName');
      if (!directory.existsSync()) {
        await directory.create(recursive: true);
      }

      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (_) {
      throw const ReportsFailure(_writeErrorMessage);
    }
  }

  Future<void> _share(ExportedReport exported, ExpenseReport report) async {
    final title = 'Rapport Juka — ${report.period.rangeLabel}';

    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(exported.path, mimeType: exported.format.mimeType)],
          fileNameOverrides: [exported.fileName],
          subject: title,
          text: title,
        ),
      );
    } catch (_) {
      throw const ReportsFailure(_shareErrorMessage);
    }
  }
}
