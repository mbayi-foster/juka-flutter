import 'package:flutter/material.dart';
import 'package:juka/common/constants/app_colors.dart';
import 'package:juka/features/reports/domain/enums/report_export_format.dart';
import 'package:juka/shared/widget/padding.dart';

/// Feuille de choix du format d'export.
///
/// Le widget ne fait qu'un choix : c'est l'écran qui déclenche l'export avec
/// le format retourné (`Navigator.pop(context, format)`).
class ReportExportSheet extends StatelessWidget {
  const ReportExportSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exporter le rapport',
                  style: TextStyle(
                    color: isDark ? AppColors.textWhite : AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                4.ph,
                const Text(
                  'Le fichier est créé sur l\'appareil, puis vous choisissez '
                  'où l\'enregistrer ou à qui l\'envoyer.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          for (final format in ReportExportFormat.values)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.16),
                child: Icon(
                  _iconOf(format),
                  color: AppColors.textDark,
                  size: 20,
                ),
              ),
              title: Text(
                format.label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(format.description),
              onTap: () => Navigator.of(context).pop(format),
            ),
          12.ph,
        ],
      ),
    );
  }

  static IconData _iconOf(ReportExportFormat format) => switch (format) {
    ReportExportFormat.pdf => Icons.picture_as_pdf_rounded,
    ReportExportFormat.excel => Icons.table_chart_rounded,
  };
}
