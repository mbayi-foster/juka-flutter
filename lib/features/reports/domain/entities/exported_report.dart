import 'package:juka/features/reports/domain/enums/report_export_format.dart';

/// Fichier produit par un export, prêt à être partagé.
class ExportedReport {
  const ExportedReport({
    required this.fileName,
    required this.path,
    required this.format,
    required this.byteLength,
  });

  /// Nom du fichier écrit sur l'appareil.
  final String fileName;

  /// Chemin absolu du fichier dans le stockage privé de l'application.
  final String path;

  final ReportExportFormat format;

  /// Taille du fichier en octets.
  final int byteLength;

  /// `18,4 ko` — taille lisible affichée après l'export.
  String get readableSize => byteLength < 1024
      ? '$byteLength o'
      : '${(byteLength / 1024).toStringAsFixed(1).replaceAll('.', ',')} ko';
}
