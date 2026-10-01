/// Formats d'export proposés pour un rapport.
enum ReportExportFormat {
  pdf(
    label: 'PDF',
    description: 'Document mis en page, prêt à imprimer ou à envoyer.',
    extension: 'pdf',
    mimeType: 'application/pdf',
  ),
  excel(
    label: 'Excel / CSV',
    description: 'Tableau à ouvrir dans Excel, Numbers ou Google Sheets.',
    extension: 'csv',
    mimeType: 'text/csv',
  );

  const ReportExportFormat({
    required this.label,
    required this.description,
    required this.extension,
    required this.mimeType,
  });

  final String label;

  /// Phrase d'explication affichée dans la feuille d'export.
  final String description;

  /// Extension du fichier produit (`pdf`, `csv`).
  final String extension;

  /// Type MIME utilisé par la feuille de partage du système.
  final String mimeType;

  /// `juka-rapport-2026-09-30.pdf`
  String fileNameFor(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return 'juka-rapport-${date.year}-$month-$day.$extension';
  }
}
