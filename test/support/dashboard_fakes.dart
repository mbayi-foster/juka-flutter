import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/common/enums/operation_type.dart';
import 'package:juka/common/enums/transaction_category.dart';
import 'package:juka/features/dashboard/domain/entities/budget_progress.dart';
import 'package:juka/features/dashboard/domain/entities/category_spending.dart';
import 'package:juka/features/dashboard/domain/entities/dashboard_alert.dart';
import 'package:juka/features/dashboard/domain/entities/dashboard_overview.dart';
import 'package:juka/features/dashboard/domain/entities/monthly_flow.dart';
import 'package:juka/features/dashboard/domain/entities/net_worth.dart';
import 'package:juka/features/dashboard/domain/entities/recent_operation.dart';
import 'package:juka/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:juka/features/dashboard/presentation/providers/dashboard_providers.dart';

/// Tableau de bord de démonstration, aux montants figés.
///
/// Le tableau de bord agrège désormais la base locale (comptes, opérations,
/// catégories, patrimoine) ; `sqflite` n'étant pas disponible dans
/// l'environnement de test, on injecte ce jeu de données à la place du
/// repository.
DashboardOverview demoDashboardOverview({DateTime? now}) {
  final reference = now ?? DateTime.now();

  return DashboardOverview(
    period: DateTime(reference.year, reference.month),
    currency: AppCurrency.eur,
    accountCount: 6,
    netWorth: const NetWorth(amount: 24850, previousAmount: 24070),
    flow: const MonthlyFlow(income: 3200, expenses: 2145),
    spendingByCategory: const [
      CategorySpending(category: TransactionCategory.housing, amount: 850),
      CategorySpending(category: TransactionCategory.food, amount: 420),
      CategorySpending(category: TransactionCategory.restaurants, amount: 235),
      CategorySpending(category: TransactionCategory.leisure, amount: 210),
      CategorySpending(category: TransactionCategory.transport, amount: 180),
      CategorySpending(category: TransactionCategory.subscriptions, amount: 95),
      CategorySpending(category: TransactionCategory.other, amount: 90),
      CategorySpending(category: TransactionCategory.health, amount: 65),
    ],
    budgets: const [
      BudgetProgress(
        category: TransactionCategory.housing,
        spent: 850,
        limit: 900,
      ),
      BudgetProgress(
        category: TransactionCategory.food,
        spent: 420,
        limit: 700,
      ),
      BudgetProgress(
        category: TransactionCategory.leisure,
        spent: 210,
        limit: 200,
      ),
    ],
    recentOperations: [
      RecentOperation(
        id: 'op-1',
        label: 'Courses alimentaires',
        category: TransactionCategory.food,
        type: OperationType.expense,
        amount: 96.40,
        date: reference,
        currency: AppCurrency.eur,
      ),
      RecentOperation(
        id: 'op-2',
        label: 'Salaire',
        category: TransactionCategory.salary,
        type: OperationType.income,
        amount: 3200,
        date: reference.subtract(const Duration(days: 2)),
        currency: AppCurrency.eur,
      ),
    ],
    alerts: const [
      DashboardAlert(
        severity: AlertSeverity.danger,
        title: 'Budget Loisirs dépassé',
        message: '210 € dépensés pour 200 € prévus ce mois-ci.',
      ),
      DashboardAlert(
        severity: AlertSeverity.success,
        title: 'Tout est à jour',
        message: 'Aucune autre alerte pour le moment.',
      ),
    ],
  );
}

/// Repository de test : renvoie toujours le même tableau de bord.
class FakeDashboardRepository implements DashboardRepository {
  const FakeDashboardRepository();

  @override
  Future<DashboardOverview> fetchOverview() async => demoDashboardOverview();
}

/// Surcharges à appliquer aux tests qui affichent le tableau de bord.
final dashboardTestOverrides = [
  dashboardRepositoryProvider.overrideWith(
    (ref) => const FakeDashboardRepository(),
  ),
];
