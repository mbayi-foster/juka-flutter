import 'dart:typed_data';

import 'package:juka/features/reports/domain/entities/expense_report.dart';
import 'package:juka/features/reports/domain/services/report_formatter.dart';
import 'package:juka/shared/utils/date_formatter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Met le rapport en page dans un document PDF.
///
/// Le document reprend section par section ce qu'affiche l'écran : synthèse,
/// dépenses par catégorie et par compte, comparaison mois par mois, top des
/// dépenses et tendances. Les polices standard (Helvetica) suffisent : le
/// fichier reste léger et ne dépend d'aucune ressource externe.
abstract final class PdfReportBuilder {
  /// Jaune de la marque, utilisé pour les encadrés.
  static const PdfColor _accent = PdfColor.fromInt(0xFFF5B301);

  static const PdfColor _ink = PdfColor.fromInt(0xFF1A1A1A);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6B6B6B);
  static const PdfColor _headerBackground = PdfColor.fromInt(0xFF1F1F1F);

  /// Construit le document et retourne ses octets.
  static Future<Uint8List> build(ExpenseReport report, {DateTime? now}) async {
    final document = pw.Document(
      title: 'Rapport Juka — ${report.period.rangeLabel}',
      author: 'Juka',
      creator: 'Juka',
    );
    final generatedAt = now ?? DateTime.now();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 30, 32, 36),
        header: (context) => _header(report),
        footer: (context) => _footer(context, generatedAt),
        build: (context) => [
          _totals(report),
          pw.SizedBox(height: 8),
          _keyValues(report),
          if (report.isEmpty)
            _notice('Aucune opération sur cette période.')
          else ...[
            if (report.hasCategoryData)
              _section('Dépenses par catégorie', _categoryTable(report)),
            if (report.hasAccountData)
              _section('Dépenses par compte', _accountTable(report)),
            if (report.hasMonthlyData)
              _section('Comparaison mois par mois', _monthTable(report)),
            if (report.hasTopExpenses)
              _section('Top des dépenses', _topExpenseTable(report)),
            _section('Tendances', _trendTable(report)),
          ],
        ],
      ),
    );

    return document.save();
  }

  // ---------------------------------------------------------------------
  // En-tête et pied de page
  // ---------------------------------------------------------------------

  static pw.Widget _header(ExpenseReport report) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'Rapport — ${report.period.rangeLabel}',
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
      ),
      pw.Text(
        '${report.scopeLabel} · ${report.currency.displayName}',
        style: pw.TextStyle(fontSize: 9, color: _muted),
      ),
      pw.SizedBox(height: 10),
    ],
  );

  static pw.Widget _footer(pw.Context context, DateTime generatedAt) =>
      pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 8),
        child: pw.Text(
          'Généré par Juka le ${DateFormatter.numericWithTime(generatedAt)} — '
          'page ${context.pageNumber}/${context.pagesCount}',
          style: pw.TextStyle(fontSize: 8, color: _muted),
        ),
      );

  // ---------------------------------------------------------------------
  // Synthèse
  // ---------------------------------------------------------------------

  static pw.Widget _totals(ExpenseReport report) {
    final currency = report.currency;

    return pw.Row(
      children: [
        _statBox(
          'Revenus',
          ReportFormatter.amount(currency, report.totals.income),
        ),
        pw.SizedBox(width: 8),
        _statBox(
          'Dépenses',
          ReportFormatter.amount(currency, report.totals.expenses),
        ),
        pw.SizedBox(width: 8),
        _statBox(
          'Épargne',
          ReportFormatter.amount(currency, report.totals.savings),
        ),
      ],
    );
  }

  static pw.Widget _statBox(String label, String value) => pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 9, color: _muted)),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
        ],
      ),
    ),
  );

  /// Indicateurs secondaires, sous les encadrés.
  static pw.Widget _keyValues(ExpenseReport report) {
    final currency = report.currency;
    final totals = report.totals;

    return _table(
      headers: const ['Indicateur', 'Valeur'],
      data: [
        ['Taux d\'épargne', ReportFormatter.share(totals.savingsRate)],
        ['Opérations', totals.operationCount.toString()],
        [
          'Dépense moyenne par jour',
          ReportFormatter.amount(currency, totals.dailyAverage),
        ],
        [
          'Dépense moyenne par mois',
          ReportFormatter.amount(currency, totals.monthlyAverage),
        ],
        [
          'Dépenses — période précédente',
          ReportFormatter.amount(currency, totals.previousExpenses),
        ],
        [
          'Variation des dépenses',
          ReportFormatter.change(totals.expensesChangeRatio),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------
  // Tableaux
  // ---------------------------------------------------------------------

  static pw.Widget _categoryTable(ExpenseReport report) {
    final currency = report.currency;

    return _table(
      headers: const [
        'Catégorie',
        'Montant',
        'Part',
        'Période précédente',
        'Variation',
      ],
      data: [
        for (final item in report.byCategory)
          [
            item.name,
            ReportFormatter.amount(currency, item.amount),
            ReportFormatter.share(item.share),
            ReportFormatter.amount(currency, item.previousAmount),
            ReportFormatter.change(item.variationRatio),
          ],
      ],
    );
  }

  static pw.Widget _accountTable(ExpenseReport report) {
    final currency = report.currency;

    return _table(
      headers: const [
        'Compte',
        'Type',
        'Revenus',
        'Dépenses',
        'Solde',
        'Opérations',
      ],
      data: [
        for (final account in report.byAccount)
          [
            account.name,
            account.type.label,
            ReportFormatter.amount(currency, account.income),
            ReportFormatter.amount(currency, account.expenses),
            ReportFormatter.amount(currency, account.net),
            account.operationCount.toString(),
          ],
      ],
    );
  }

  static pw.Widget _monthTable(ExpenseReport report) {
    final currency = report.currency;

    return _table(
      headers: const [
        'Mois',
        'Revenus',
        'Dépenses',
        'Solde',
        'Variation des dépenses',
      ],
      data: [
        for (final month in report.byMonth)
          [
            ReportFormatter.month(month.month),
            ReportFormatter.amount(currency, month.income),
            ReportFormatter.amount(currency, month.expenses),
            ReportFormatter.amount(currency, month.savings),
            ReportFormatter.change(month.expensesChangeRatio),
          ],
      ],
    );
  }

  static pw.Widget _topExpenseTable(ExpenseReport report) {
    final currency = report.currency;

    return _table(
      headers: const [
        'Date',
        'Libellé',
        'Catégorie',
        'Compte',
        'Montant',
        'Part',
      ],
      data: [
        for (final expense in report.topExpenses)
          [
            ReportFormatter.date(expense.date),
            expense.label,
            expense.categoryName,
            expense.accountName,
            ReportFormatter.amount(currency, expense.amount),
            ReportFormatter.share(expense.share),
          ],
      ],
    );
  }

  static pw.Widget _trendTable(ExpenseReport report) {
    final currency = report.currency;
    final trends = report.trends;

    final rows = <List<String>>[
      ['Tendance', trends.direction.label],
      [
        'Moyenne des 3 derniers mois',
        ReportFormatter.amount(currency, trends.averageRecent),
      ],
      [
        'Moyenne des 3 mois précédents',
        ReportFormatter.amount(currency, trends.averagePrevious),
      ],
      ['Écart', ReportFormatter.change(trends.changeRatio)],
      [],
      ['Catégorie', 'Période', 'Période précédente', 'Variation'],
      for (final mover in trends.movers)
        [
          mover.name,
          ReportFormatter.amount(currency, mover.amount),
          ReportFormatter.amount(currency, mover.previousAmount),
          ReportFormatter.change(mover.variationRatio),
        ],
    ];

    return _table(
      headers: const ['Indicateur', 'Valeur'],
      data: rows,
      border: false,
    );
  }

  // ---------------------------------------------------------------------
  // Briques de mise en page
  // ---------------------------------------------------------------------

  static pw.Widget _section(String title, pw.Widget body) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Container(
        decoration: pw.BoxDecoration(
          color: _accent,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
        ),
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 10.5,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
      ),
      pw.SizedBox(height: 6),
      body,
      pw.SizedBox(height: 16),
    ],
  );

  static pw.Widget _notice(String message) => pw.Container(
    margin: const pw.EdgeInsets.only(top: 16),
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey100,
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
    ),
    child: pw.Text(message, style: pw.TextStyle(fontSize: 10, color: _muted)),
  );

  /// Tableau à en-tête sombre, utilisé par toutes les sections.
  static pw.Widget _table({
    required List<String> headers,
    required List<List<String>> data,
    bool border = true,
  }) => pw.TableHelper.fromTextArray(
    headers: headers,
    data: data,
    border: border
        ? const pw.TableBorder(
            horizontalInside: pw.BorderSide(
              color: PdfColors.grey300,
              width: 0.4,
            ),
            bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.6),
          )
        : null,
    headerDecoration: const pw.BoxDecoration(color: _headerBackground),
    headerStyle: pw.TextStyle(
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    ),
    headerAlignment: pw.Alignment.centerLeft,
    cellStyle: pw.TextStyle(fontSize: 9, color: _ink),
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
    oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
  );
}
