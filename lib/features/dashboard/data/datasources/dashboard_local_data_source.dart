import 'package:juka/common/enums/operation_type.dart';
import 'package:juka/common/enums/transaction_category.dart';
import 'package:juka/features/dashboard/domain/entities/budget_progress.dart';
import 'package:juka/features/dashboard/domain/entities/category_spending.dart';
import 'package:juka/features/dashboard/domain/entities/dashboard_alert.dart';
import 'package:juka/features/dashboard/domain/entities/dashboard_overview.dart';
import 'package:juka/features/dashboard/domain/entities/monthly_flow.dart';
import 'package:juka/features/dashboard/domain/entities/net_worth.dart';
import 'package:juka/features/dashboard/domain/entities/recent_operation.dart';

/// Source de données du tableau de bord.
abstract interface class DashboardLocalDataSource {
  Future<DashboardOverview> fetchOverview();
}

/// Implémentation de démonstration : les données sont générées en mémoire.
///
/// Elle renvoie directement les entités du domaine (pas de JSON) puisqu'aucun
/// transport n'est encore en jeu. Lorsque `api-juka` exposera `/dashboard`, il
/// suffira d'introduire des modèles et de les convertir ici : les couches
/// `domain` et `presentation` resteront inchangées.
class DashboardLocalDataSourceImpl implements DashboardLocalDataSource {
  const DashboardLocalDataSourceImpl();

  /// Latence simulée pour rendre l'état de chargement visible.
  static const Duration _latency = Duration(milliseconds: 450);

  @override
  Future<DashboardOverview> fetchOverview() async {
    await Future<void>.delayed(_latency);

    final now = DateTime.now();

    return DashboardOverview(
      period: DateTime(now.year, now.month),
      netWorth: const NetWorth(amount: 24850, previousAmount: 24070),
      flow: const MonthlyFlow(income: 3200, expenses: 2145, savingsGoal: 800),
      spendingByCategory: const [
        CategorySpending(category: TransactionCategory.housing, amount: 850),
        CategorySpending(category: TransactionCategory.food, amount: 420),
        CategorySpending(
          category: TransactionCategory.restaurants,
          amount: 235,
        ),
        CategorySpending(category: TransactionCategory.leisure, amount: 210),
        CategorySpending(category: TransactionCategory.transport, amount: 180),
        CategorySpending(
          category: TransactionCategory.subscriptions,
          amount: 95,
        ),
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
          category: TransactionCategory.transport,
          spent: 180,
          limit: 300,
        ),
        BudgetProgress(
          category: TransactionCategory.leisure,
          spent: 210,
          limit: 200,
        ),
        BudgetProgress(
          category: TransactionCategory.subscriptions,
          spent: 95,
          limit: 150,
        ),
      ],
      recentOperations: [
        RecentOperation(
          id: 'op-1',
          label: 'Courses alimentaires',
          category: TransactionCategory.food,
          type: OperationType.expense,
          amount: 96.40,
          date: now,
        ),
        RecentOperation(
          id: 'op-2',
          label: 'Restaurant',
          category: TransactionCategory.restaurants,
          type: OperationType.expense,
          amount: 42.50,
          date: now.subtract(const Duration(days: 1)),
        ),
        RecentOperation(
          id: 'op-3',
          label: 'Salaire',
          category: TransactionCategory.salary,
          type: OperationType.income,
          amount: 3200,
          date: now.subtract(const Duration(days: 2)),
        ),
        RecentOperation(
          id: 'op-4',
          label: 'Loyer',
          category: TransactionCategory.housing,
          type: OperationType.expense,
          amount: 850,
          date: now.subtract(const Duration(days: 3)),
        ),
        RecentOperation(
          id: 'op-5',
          label: 'Carburant',
          category: TransactionCategory.transport,
          type: OperationType.expense,
          amount: 68.20,
          date: now.subtract(const Duration(days: 4)),
        ),
        RecentOperation(
          id: 'op-6',
          label: 'Abonnement musique',
          category: TransactionCategory.subscriptions,
          type: OperationType.expense,
          amount: 11.99,
          date: now.subtract(const Duration(days: 5)),
        ),
      ],
      alerts: const [
        DashboardAlert(
          severity: AlertSeverity.danger,
          title: 'Budget Loisirs dépassé',
          message: '210 € dépensés pour 200 € prévus ce mois-ci.',
        ),
        DashboardAlert(
          severity: AlertSeverity.warning,
          title: 'Budget Logement presque atteint',
          message: '94 % du budget consommé (850 € sur 900 €).',
        ),
        DashboardAlert(
          severity: AlertSeverity.info,
          title: '3 prélèvements à venir',
          message: 'Abonnements prévus dans les 7 prochains jours : 84,97 €.',
        ),
        DashboardAlert(
          severity: AlertSeverity.success,
          title: 'Objectif d\'épargne atteint',
          message: '1 055 € épargnés, soit 132 % de votre objectif de 800 €.',
        ),
      ],
    );
  }
}
