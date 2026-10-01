import 'dart:convert';

import 'package:juka/features/reports/domain/entities/expense_report.dart';
import 'package:juka/features/reports/domain/services/report_formatter.dart';
import 'package:juka/shared/utils/date_formatter.dart';

/// Met le rapport en tableau, au format CSV ouvrable dans Excel.
///
/// Deux précautions rendent le fichier directement exploitable :
///
/// * le séparateur est le point-virgule, celui qu'attend Excel en français ;
/// * le fichier commence par un BOM UTF-8, sans quoi les accents s'affichent
///   en `Ã©`.
///
/// Les montants sont écrits sans symbole monétaire pour que le tableur puisse
/// les additionner.
abstract final class CsvReportBuilder {
  /// Séparateur de colonnes.
  static const String separator = ';';

  /// Marque d'ordre des octets (BOM) placée en tête de fichier.
  static const String byteOrderMark = '\uFEFF';

  /// Contenu du fichier, encodé en UTF-8 avec BOM.
  static List<int> build(ExpenseReport report, {DateTime? now}) =>
      utf8.encode(byteOrderMark + text(report, now: now));

  /// Contenu du fichier, sous forme de texte.
  static String text(ExpenseReport report, {DateTime? now}) {
    final currency = report.currency;
    final totals = report.totals;

    final rows = <List<String>>[
      ['Rapport Juka'],
      ['Période', report.period.rangeLabel],
      ['Périmètre', report.scopeLabel],
      ['Devise', currency.displayName],
      ['Exporté le', DateFormatter.numericWithTime(now ?? DateTime.now())],
      [],
      ['SYNTHÈSE'],
      ['Indicateur', 'Valeur'],
      ['Revenus', ReportFormatter.amount(currency, totals.income)],
      ['Dépenses', ReportFormatter.amount(currency, totals.expenses)],
      ['Épargne', ReportFormatter.amount(currency, totals.savings)],
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
      [],
      ['DÉPENSES PAR CATÉGORIE'],
      ['Catégorie', 'Montant', 'Part', 'Période précédente', 'Variation'],
      for (final item in report.byCategory)
        [
          item.name,
          ReportFormatter.amount(currency, item.amount),
          ReportFormatter.share(item.share),
          ReportFormatter.amount(currency, item.previousAmount),
          ReportFormatter.change(item.variationRatio),
        ],
      [
        'Total',
        ReportFormatter.amount(currency, totals.expenses),
        ReportFormatter.share(totals.expenses <= 0 ? 0 : 1),
      ],
      [],
      ['DÉPENSES PAR COMPTE'],
      ['Compte', 'Type', 'Revenus', 'Dépenses', 'Solde', 'Opérations'],
      for (final account in report.byAccount)
        [
          account.name,
          account.type.label,
          ReportFormatter.amount(currency, account.income),
          ReportFormatter.amount(currency, account.expenses),
          ReportFormatter.amount(currency, account.net),
          account.operationCount.toString(),
        ],
      [],
      ['COMPARAISON MOIS PAR MOIS'],
      ['Mois', 'Revenus', 'Dépenses', 'Solde', 'Variation des dépenses'],
      for (final month in report.byMonth)
        [
          ReportFormatter.month(month.month),
          ReportFormatter.amount(currency, month.income),
          ReportFormatter.amount(currency, month.expenses),
          ReportFormatter.amount(currency, month.savings),
          ReportFormatter.change(month.expensesChangeRatio),
        ],
      [],
      ['TOP DES DÉPENSES'],
      ['Date', 'Libellé', 'Catégorie', 'Compte', 'Montant', 'Part'],
      for (final expense in report.topExpenses)
        [
          ReportFormatter.date(expense.date),
          expense.label,
          expense.categoryName,
          expense.accountName,
          ReportFormatter.amount(currency, expense.amount),
          ReportFormatter.share(expense.share),
        ],
      [],
      ['TENDANCES'],
      ['Indicateur', 'Valeur'],
      ['Tendance', report.trends.direction.label],
      ['Lecture', report.trends.direction.message],
      [
        'Moyenne des 3 derniers mois',
        ReportFormatter.amount(currency, report.trends.averageRecent),
      ],
      [
        'Moyenne des 3 mois précédents',
        ReportFormatter.amount(currency, report.trends.averagePrevious),
      ],
      ['Écart', ReportFormatter.change(report.trends.changeRatio)],
      [],
      ['ÉVOLUTION PAR CATÉGORIE'],
      ['Catégorie', 'Période', 'Période précédente', 'Variation'],
      for (final mover in report.trends.movers)
        [
          mover.name,
          ReportFormatter.amount(currency, mover.amount),
          ReportFormatter.amount(currency, mover.previousAmount),
          ReportFormatter.change(mover.variationRatio),
        ],
    ];

    return [for (final row in rows) line(row)].join('\n');
  }

  /// Assemble une ligne de tableau en échappant les cellules si nécessaire.
  static String line(List<String> cells) => cells.map(escape).join(separator);

  /// Entoure de guillemets les cellules contenant le séparateur, un guillemet
  /// ou un retour à la ligne (ex. libellé « Courses ; pain »).
  static String escape(String value) {
    final needsQuotes =
        value.contains(separator) ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!needsQuotes) return value;
    return '"${value.replaceAll('"', '""')}"';
  }
}
