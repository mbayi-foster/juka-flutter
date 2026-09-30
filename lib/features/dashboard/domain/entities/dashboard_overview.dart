import 'package:juka/features/dashboard/domain/entities/budget_progress.dart';
import 'package:juka/features/dashboard/domain/entities/category_spending.dart';
import 'package:juka/features/dashboard/domain/entities/dashboard_alert.dart';
import 'package:juka/features/dashboard/domain/entities/monthly_flow.dart';
import 'package:juka/features/dashboard/domain/entities/net_worth.dart';
import 'package:juka/features/dashboard/domain/entities/recent_operation.dart';

/// Agrégat exposé au tableau de bord : tout ce qu'affiche l'écran d'accueil.
///
/// Regrouper les données en un seul objet évite de multiplier les requêtes et
/// les états de chargement dans la couche présentation.
class DashboardOverview {
  const DashboardOverview({
    required this.period,
    required this.netWorth,
    required this.flow,
    required this.spendingByCategory,
    required this.budgets,
    required this.recentOperations,
    required this.alerts,
  });

  /// Mois affiché (premier jour du mois).
  final DateTime period;

  final NetWorth netWorth;
  final MonthlyFlow flow;
  final List<CategorySpending> spendingByCategory;
  final List<BudgetProgress> budgets;
  final List<RecentOperation> recentOperations;
  final List<DashboardAlert> alerts;

  /// Total des dépenses du mois, déduit de la répartition par catégorie.
  double get totalExpenses =>
      spendingByCategory.fold(0, (sum, item) => sum + item.amount);

  /// Répartition triée de la plus grosse dépense à la plus petite.
  List<CategorySpending> get sortedSpendingByCategory =>
      [...spendingByCategory]..sort((a, b) => b.amount.compareTo(a.amount));
}
