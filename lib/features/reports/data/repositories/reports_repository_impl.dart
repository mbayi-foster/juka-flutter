import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/features/accounts/domain/repositories/accounts_repository.dart';
import 'package:juka/features/categories/domain/repositories/categories_repository.dart';
import 'package:juka/features/operations/domain/entities/operation_filter.dart';
import 'package:juka/features/operations/domain/repositories/operations_repository.dart';
import 'package:juka/features/reports/domain/entities/expense_report.dart';
import 'package:juka/features/reports/domain/entities/report_period.dart';
import 'package:juka/features/reports/domain/failures/reports_failure.dart';
import 'package:juka/features/reports/domain/repositories/reports_repository.dart';
import 'package:juka/features/reports/domain/services/reports_calculator.dart';
import 'package:juka/features/wealth/domain/services/wealth_calculator.dart';

/// Construit les rapports à partir des **données réelles** de l'application.
///
/// Comme le tableau de bord, ce module n'a pas de stockage propre : il croise
/// les comptes, les opérations et les catégories, puis délègue tout le calcul
/// à [ReportsCalculator].
class ReportsRepositoryImpl implements ReportsRepository {
  const ReportsRepositoryImpl({
    required this.accountsRepository,
    required this.operationsRepository,
    required this.categoriesRepository,
  });

  final AccountsRepository accountsRepository;
  final OperationsRepository operationsRepository;
  final CategoriesRepository categoriesRepository;

  static const String _unexpectedMessage =
      'Impossible de construire le rapport. Veuillez réessayer.';

  @override
  Future<ExpenseReport> fetchReport({
    required ReportPeriod period,
    String? accountId,
    AppCurrency? currency,
  }) async {
    try {
      final accounts = await accountsRepository.fetchAccounts();

      // Une seule requête couvre la période, son comparatif et la tendance.
      final operations = await operationsRepository.fetchOperations(
        OperationFilter(
          from: ReportsCalculator.windowStart(period),
          to: period.end,
          accountId: accountId,
        ),
      );
      final categories = await categoriesRepository.fetchCategories();

      // Les devises ne sont pas converties : le rapport porte donc sur une
      // seule devise. Sans choix explicite, c'est celle qui porte des
      // opérations sur la période qui est analysée, afin de ne jamais afficher
      // un rapport vide alors que des opérations existent.
      final target = ReportsCalculator.resolveCurrency(
        operations: operations,
        accounts: accounts,
        period: period,
        fallback: _fallbackCurrency(accounts, accountId),
        requested: currency,
      );

      return ReportsCalculator.build(
        period: period,
        operations: operations,
        categories: categories,
        accounts: accounts,
        currency: target,
        accountId: accountId,
      );
    } on ReportsFailure {
      rethrow;
    } catch (_) {
      throw const ReportsFailure(_unexpectedMessage);
    }
  }

  /// Devise de repli du rapport : celle du compte observé, sinon celle qui
  /// concentre le plus de montants.
  AppCurrency _fallbackCurrency(List<Account> accounts, String? accountId) {
    if (accountId != null) {
      for (final account in accounts) {
        if (account.id == accountId) return account.currency;
      }
    }

    return WealthCalculator.primaryCurrency(accounts) ?? AppCurrency.eur;
  }
}
