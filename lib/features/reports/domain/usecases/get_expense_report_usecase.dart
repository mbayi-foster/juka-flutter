import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/reports/domain/entities/expense_report.dart';
import 'package:juka/features/reports/domain/entities/report_period.dart';
import 'package:juka/features/reports/domain/repositories/reports_repository.dart';

/// Construit le rapport « Rapports et analyses » d'une période.
class GetExpenseReportUseCase {
  const GetExpenseReportUseCase(this._reportsRepository);

  final ReportsRepository _reportsRepository;

  /// [accountId] `null` = tous les comptes, [currency] `null` = devise
  /// principale de l'utilisateur.
  Future<ExpenseReport> call({
    required ReportPeriod period,
    String? accountId,
    AppCurrency? currency,
  }) => _reportsRepository.fetchReport(
    period: period,
    accountId: accountId,
    currency: currency,
  );
}
