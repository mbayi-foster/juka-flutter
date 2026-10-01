import 'package:flutter_test/flutter_test.dart';
import 'package:juka/common/enums/account_type.dart';
import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/common/enums/operation_type.dart';
import 'package:juka/common/enums/transaction_category.dart';
import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/features/categories/domain/entities/category.dart';
import 'package:juka/features/categories/domain/enums/category_kind.dart';
import 'package:juka/features/operations/domain/entities/operation.dart';
import 'package:juka/features/reports/data/exporters/csv_report_builder.dart';
import 'package:juka/features/reports/data/exporters/pdf_report_builder.dart';
import 'package:juka/features/reports/domain/entities/expense_report.dart';
import 'package:juka/features/reports/domain/entities/report_period.dart';
import 'package:juka/features/reports/domain/enums/report_period_preset.dart';
import 'package:juka/features/reports/domain/services/reports_calculator.dart';

/// Rapport de septembre 2026 : un loyer et un revenu, avec un libellé qui
/// contient le séparateur CSV.
ExpenseReport _report() => ReportsCalculator.build(
  period: ReportPeriod(
    start: DateTime(2026, 9),
    end: DateTime(2026, 9, 30, 23, 59, 59),
    preset: ReportPeriodPreset.thisMonth,
  ),
  operations: [
    Operation(
      id: 'loyer',
      label: 'Loyer; septembre',
      type: OperationType.expense,
      amount: 800,
      category: TransactionCategory.housing,
      accountId: 'courant',
      date: DateTime(2026, 9, 5),
    ),
    Operation(
      id: 'salaire',
      label: 'Salaire',
      type: OperationType.income,
      amount: 3000,
      category: TransactionCategory.salary,
      accountId: 'courant',
      date: DateTime(2026, 9, 1),
    ),
  ],
  categories: [
    Category(
      id: 'housing',
      name: 'Logement',
      kind: CategoryKind.expense,
      iconKey: 'home',
      colorHex: 0xFF6C63FF,
      createdAt: DateTime(2026),
    ),
  ],
  accounts: [
    Account(
      id: 'courant',
      name: 'Compte courant',
      type: AccountType.bank,
      currency: AppCurrency.eur,
      initialBalance: 0,
      currentBalance: 0,
      createdAt: DateTime(2026),
    ),
  ],
  currency: AppCurrency.eur,
);

void main() {
  group('CsvReportBuilder', () {
    test('produit un tableau séparé par des points-virgules, avec BOM', () {
      final text = CsvReportBuilder.text(
        _report(),
        now: DateTime(2026, 9, 30, 8, 5),
      );

      expect(text, contains('SYNTHÈSE'));
      expect(text, contains('DÉPENSES PAR CATÉGORIE'));
      expect(text, contains('Logement;800,00;100,0 %'));
      expect(text, contains('Exporté le;30/09/2026 08:05'));
      // Un libellé contenant le séparateur doit être mis entre guillemets.
      expect(text, contains('"Loyer; septembre"'));

      final bytes = CsvReportBuilder.build(_report());
      expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
    });

    test('échappe les cellules sensibles du tableur', () {
      expect(CsvReportBuilder.escape('Courses ; pain'), '"Courses ; pain"');
      expect(CsvReportBuilder.escape('Il a dit "non"'), '"Il a dit ""non"""');
      expect(CsvReportBuilder.escape('Loyer'), 'Loyer');
    });
  });

  group('PdfReportBuilder', () {
    test('génère un document PDF exploitable', () async {
      final bytes = await PdfReportBuilder.build(
        _report(),
        now: DateTime(2026, 9, 30, 8, 5),
      );

      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(1000));
      // Les polices d'écriture doivent accompagner le document.
      expect(String.fromCharCodes(bytes), contains('WinAnsiEncoding'));
    });
  });
}
