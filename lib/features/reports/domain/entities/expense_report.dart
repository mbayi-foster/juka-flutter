import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/reports/domain/entities/account_breakdown.dart';
import 'package:juka/features/reports/domain/entities/category_breakdown.dart';
import 'package:juka/features/reports/domain/entities/monthly_comparison.dart';
import 'package:juka/features/reports/domain/entities/report_period.dart';
import 'package:juka/features/reports/domain/entities/report_totals.dart';
import 'package:juka/features/reports/domain/entities/top_expense.dart';
import 'package:juka/features/reports/domain/entities/trend_analysis.dart';

/// Rapport « Rapports et analyses » : tout ce qu'affiche l'écran, et tout ce
/// que reçoivent les exports PDF et CSV.
class ExpenseReport {
  const ExpenseReport({
    required this.period,
    required this.currency,
    required this.totals,
    required this.byCategory,
    required this.byAccount,
    required this.byMonth,
    required this.topExpenses,
    required this.trends,
    this.accountId,
    this.accountName,
  });

  final ReportPeriod period;

  /// Devise analysée : les comptes d'autres devises ne sont pas additionnés.
  final AppCurrency currency;

  final ReportTotals totals;

  /// Dépenses par catégorie, de la plus lourde à la plus légère.
  final List<CategoryBreakdown> byCategory;

  /// Flux par compte, du plus dépensier au moins dépensier.
  final List<AccountBreakdown> byAccount;

  /// Comparaison mois par mois, dans l'ordre chronologique.
  final List<MonthlyComparison> byMonth;

  /// Dépenses les plus élevées de la période.
  final List<TopExpense> topExpenses;

  final TrendAnalysis trends;

  /// Compte filtré, `null` si le rapport couvre tous les comptes.
  final String? accountId;

  final String? accountName;

  /// Aucune opération sur la période : l'écran invite à en saisir une.
  bool get isEmpty => totals.operationCount == 0;

  bool get hasCategoryData => byCategory.isNotEmpty;

  bool get hasAccountData => byAccount.isNotEmpty;

  bool get hasTopExpenses => topExpenses.isNotEmpty;

  bool get hasMonthlyData => byMonth.any((month) => month.hasData);

  /// Périmètre analysé, affiché dans l'en-tête et dans les exports.
  String get scopeLabel => accountName ?? 'Tous les comptes';
}
