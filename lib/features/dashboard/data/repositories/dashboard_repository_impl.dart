import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/common/enums/transaction_category.dart';
import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/features/accounts/domain/repositories/accounts_repository.dart';
import 'package:juka/features/categories/domain/entities/budget_progress.dart';
import 'package:juka/features/categories/domain/entities/category.dart';
import 'package:juka/features/categories/domain/repositories/categories_repository.dart';
import 'package:juka/features/categories/domain/services/budget_progress_calculator.dart';
import 'package:juka/features/dashboard/domain/entities/budget_progress.dart'
    as dashboard;
import 'package:juka/features/dashboard/domain/entities/category_spending.dart';
import 'package:juka/features/dashboard/domain/entities/dashboard_alert.dart';
import 'package:juka/features/dashboard/domain/entities/dashboard_overview.dart';
import 'package:juka/features/dashboard/domain/entities/monthly_flow.dart';
import 'package:juka/features/dashboard/domain/entities/net_worth.dart';
import 'package:juka/features/dashboard/domain/entities/recent_operation.dart';
import 'package:juka/features/dashboard/domain/failures/dashboard_failure.dart';
import 'package:juka/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:juka/features/operations/domain/entities/operation.dart';
import 'package:juka/features/operations/domain/entities/operation_filter.dart';
import 'package:juka/features/operations/domain/repositories/operations_repository.dart';
import 'package:juka/features/wealth/domain/entities/net_worth_snapshot.dart';
import 'package:juka/features/wealth/domain/repositories/wealth_repository.dart';
import 'package:juka/features/wealth/domain/services/wealth_calculator.dart';
import 'package:juka/shared/utils/money_formatter.dart';

/// Agrège les **données réelles** de l'application pour le tableau de bord.
///
/// Chaque valeur affichée provient de la base locale :
/// * le patrimoine net des comptes (+ la photo du mois précédent) ;
/// * les revenus, dépenses et la répartition du mois depuis les opérations ;
/// * les budgets mensuels depuis les catégories ;
/// * les alertes sont déduites de ces mêmes données.
///
/// Aucune donnée de démonstration n'est injectée ici.
class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl({
    required this.accountsRepository,
    required this.operationsRepository,
    required this.categoriesRepository,
    required this.wealthRepository,
  });

  final AccountsRepository accountsRepository;
  final OperationsRepository operationsRepository;
  final CategoriesRepository categoriesRepository;
  final WealthRepository wealthRepository;

  /// Nombre d'opérations récentes affichées par le tableau de bord.
  static const int recentOperationsCount = 6;

  static const String _unexpectedMessage =
      'Impossible de charger votre tableau de bord. Veuillez réessayer.';

  @override
  Future<DashboardOverview> fetchOverview() async {
    try {
      final now = DateTime.now();
      final period = DateTime(now.year, now.month);

      final accounts = await accountsRepository.fetchAccounts();
      final currency =
          WealthCalculator.primaryCurrency(accounts) ?? AppCurrency.eur;
      final currencyAccounts = WealthCalculator.accountsOf(accounts, currency);
      final accountIds = {for (final account in currencyAccounts) account.id};

      final categories = await categoriesRepository.ensureDefaults();
      final budgets = await categoriesRepository.fetchBudgets();

      final operations = await _operationsOfMonth(period, accountIds);
      final previousOperations = await _operationsOfMonth(
        DateTime(now.year, now.month - 1),
        accountIds,
      );

      final spent = _spentByCategory(operations, categories);
      final progress = buildBudgetProgress(
        categories: categories,
        budgets: budgets,
        spent: spent,
        previousSpent: _spentByCategory(previousOperations, categories),
      );
      final flow = _flow(operations);

      return DashboardOverview(
        period: period,
        accountCount: currencyAccounts.length,
        netWorth: await _netWorth(accounts, currency, period),
        flow: flow,
        spendingByCategory: _spendingByCategory(spent, categories),
        budgets: [
          for (final item in progress)
            dashboard.BudgetProgress(
              category: _legacyCategory(item.category.id),
              spent: item.spent,
              // L'enveloppe affichée inclut le report éventuel du mois
              // précédent.
              limit: item.planned,
            ),
        ],
        recentOperations: _recentOperations(
          await _recentOperationsOf(accountIds),
        ),
        alerts: _alerts(
          progress: progress,
          accounts: currencyAccounts,
          flow: flow,
          currency: currency,
        ),
      );
    } on DashboardFailure {
      rethrow;
    } catch (_) {
      throw const DashboardFailure(_unexpectedMessage);
    }
  }

  // ---------------------------------------------------------------------
  // Patrimoine
  // ---------------------------------------------------------------------

  /// Patrimoine net de la devise, comparé à la photo du mois précédent.
  ///
  /// La photo du mois en cours est enregistrée au passage : le suivi mensuel
  /// est donc automatique.
  Future<NetWorth> _netWorth(
    List<Account> accounts,
    AppCurrency currency,
    DateTime period,
  ) async {
    final current = WealthCalculator.snapshot(
      accounts: accounts,
      currency: currency,
      month: period,
    );
    await wealthRepository.saveSnapshot(current);

    final history = await wealthRepository.fetchSnapshots(
      currency: currency,
      limit: WealthCalculator.historyMonths,
    );
    final previous = _snapshotOf(
      history,
      DateTime(period.year, period.month - 1),
    );

    return NetWorth(
      amount: current.netWorth,
      // Sans photo précédente, la variation est nulle plutôt que fausse.
      previousAmount: previous?.netWorth ?? current.netWorth,
    );
  }

  NetWorthSnapshot? _snapshotOf(
    List<NetWorthSnapshot> snapshots,
    DateTime month,
  ) {
    for (final snapshot in snapshots) {
      if (snapshot.isSameMonth(month)) return snapshot;
    }
    return null;
  }

  // ---------------------------------------------------------------------
  // Opérations
  // ---------------------------------------------------------------------

  /// Opérations du mois concernant les comptes de la devise affichée.
  Future<List<Operation>> _operationsOfMonth(
    DateTime month,
    Set<String> accountIds,
  ) async {
    final operations = await operationsRepository.fetchOperations(
      OperationFilter(
        from: DateTime(month.year, month.month),
        to: DateTime(month.year, month.month + 1, 0, 23, 59, 59),
      ),
    );
    return _onlyAccounts(operations, accountIds);
  }

  /// Dernières opérations, toutes périodes confondues.
  Future<List<Operation>> _recentOperationsOf(Set<String> accountIds) async {
    final operations = await operationsRepository.fetchOperations(
      const OperationFilter(),
    );
    return _onlyAccounts(
      operations,
      accountIds,
    ).take(recentOperationsCount).toList();
  }

  /// Les devises ne sont pas converties : on se limite aux comptes de la
  /// devise affichée.
  List<Operation> _onlyAccounts(
    List<Operation> operations,
    Set<String> accountIds,
  ) => [
    for (final operation in operations)
      if (accountIds.contains(operation.accountId)) operation,
  ];

  MonthlyFlow _flow(List<Operation> operations) {
    var income = 0.0;
    var expenses = 0.0;

    for (final operation in operations) {
      if (!operation.type.countsInStats) continue;
      if (operation.isIncome) {
        income += operation.amount;
      } else {
        expenses += operation.amount;
      }
    }

    return MonthlyFlow(income: income, expenses: expenses);
  }

  /// Dépenses brutes par identifiant de catégorie.
  ///
  /// La remontée des sous-catégories est laissée à `buildBudgetProgress`.
  Map<String, double> _spentByCategory(
    List<Operation> operations,
    List<Category> categories,
  ) {
    final known = {for (final category in categories) category.id};
    final spent = <String, double>{};

    for (final operation in operations) {
      if (!operation.isExpense) continue;
      final id = operation.category.id;
      if (!known.contains(id)) continue;
      spent.update(
        id,
        (total) => total + operation.amount,
        ifAbsent: () => operation.amount,
      );
    }

    return spent;
  }

  /// Répartition des dépenses, regroupée par catégorie racine.
  List<CategorySpending> _spendingByCategory(
    Map<String, double> spent,
    List<Category> categories,
  ) {
    final byId = {for (final category in categories) category.id: category};
    final totals = <String, double>{};

    for (final entry in spent.entries) {
      if (entry.value <= 0) continue;
      final rootId = _rootOf(entry.key, byId);
      totals.update(
        rootId,
        (total) => total + entry.value,
        ifAbsent: () => entry.value,
      );
    }

    return [
      for (final entry in totals.entries)
        CategorySpending(
          category: _legacyCategory(entry.key),
          amount: entry.value,
        ),
    ]..sort((a, b) => b.amount.compareTo(a.amount));
  }

  /// Identifiant de la catégorie racine (les sous-catégories remontent dans
  /// leur parent).
  String _rootOf(String categoryId, Map<String, Category> byId) {
    var current = byId[categoryId];
    final visited = <String>{};

    while (current != null &&
        current.parentId != null &&
        visited.add(current.id)) {
      final parent = byId[current.parentId!];
      if (parent == null) break;
      current = parent;
    }

    return current?.id ?? categoryId;
  }

  List<RecentOperation> _recentOperations(List<Operation> operations) => [
    for (final operation in operations)
      RecentOperation(
        id: operation.id,
        label: operation.label,
        category: operation.category,
        type: operation.type,
        amount: operation.amount,
        date: operation.date,
      ),
  ];

  // ---------------------------------------------------------------------
  // Alertes
  // ---------------------------------------------------------------------

  List<DashboardAlert> _alerts({
    required List<BudgetProgress> progress,
    required List<Account> accounts,
    required MonthlyFlow flow,
    required AppCurrency currency,
  }) {
    final alerts = <DashboardAlert>[];

    for (final budget in progress) {
      if (budget.isExceeded) {
        alerts.add(
          DashboardAlert(
            severity: AlertSeverity.danger,
            title: 'Budget ${budget.category.name} dépassé',
            message:
                '${currency.format(budget.spent)} dépensés pour '
                '${currency.format(budget.planned)} prévus ce mois-ci.',
          ),
        );
      } else if (budget.isAtWarning) {
        alerts.add(
          DashboardAlert(
            severity: AlertSeverity.warning,
            title: 'Budget ${budget.category.name} bientôt atteint',
            message:
                '${budget.percentage.round()} % de l\'enveloppe consommée '
                '(${currency.format(budget.spent)} sur '
                '${currency.format(budget.planned)}).',
          ),
        );
      }
    }

    for (final account in accounts) {
      final gap = account.reconciliationGap;
      if (gap == null || account.isReconciled) continue;
      alerts.add(
        DashboardAlert(
          severity: AlertSeverity.warning,
          title: 'Écart de rapprochement',
          message:
              '${account.name} : '
              '${account.currency.format(gap, withSign: true)} d\'écart avec '
              'le solde réel.',
        ),
      );
    }

    if (flow.income > 0 && !flow.hasPositiveSavings) {
      alerts.add(
        DashboardAlert(
          severity: AlertSeverity.danger,
          title: 'Dépenses supérieures aux revenus',
          message:
              'Ce mois-ci, vos dépenses dépassent vos revenus de '
              '${currency.format(-flow.savings)}.',
        ),
      );
    }

    if (alerts.isEmpty) {
      alerts.add(
        const DashboardAlert(
          severity: AlertSeverity.success,
          title: 'Tout est à jour',
          message:
              'Aucune alerte : vos budgets sont tenus et vos comptes sont '
              'rapprochés.',
        ),
      );
    }

    return alerts;
  }

  // ---------------------------------------------------------------------
  // Passerelle temporaire
  // ---------------------------------------------------------------------

  /// Convertit un identifiant de catégorie en catégorie « historique ».
  ///
  /// Les opérations stockent encore le nom de l'énumération
  /// `TransactionCategory` ; les catégories par défaut partagent ces
  /// identifiants. Une catégorie personnalisée retombe donc sur « Divers »
  /// dans le tableau de bord : ce pont disparaîtra avec la migration des
  /// opérations vers les catégories dynamiques.
  TransactionCategory _legacyCategory(String categoryId) {
    for (final category in TransactionCategory.values) {
      if (category.id == categoryId) return category;
    }
    return TransactionCategory.other;
  }
}
