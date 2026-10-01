import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/reports/domain/entities/expense_report.dart';
import 'package:juka/features/reports/domain/entities/report_period.dart';

/// Contrat du domaine pour la construction des rapports.
///
/// L'implémentation agrège les comptes, les opérations et les catégories : les
/// rapports ne disposent d'aucun stockage propre.
abstract interface class ReportsRepository {
  /// Construit le rapport de [period].
  ///
  /// [accountId] limite l'analyse à un compte, [currency] à une devise ; une
  /// valeur `null` laisse le choix par défaut (tous les comptes, devise
  /// principale).
  Future<ExpenseReport> fetchReport({
    required ReportPeriod period,
    String? accountId,
    AppCurrency? currency,
  });
}
