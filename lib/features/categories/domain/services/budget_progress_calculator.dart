import 'package:juka/features/categories/domain/entities/budget.dart';
import 'package:juka/features/categories/domain/entities/budget_progress.dart';
import 'package:juka/features/categories/domain/entities/category.dart';

/// Calcule l'avancement des budgets à partir des dépenses constatées.
///
/// Fonction pure, sans dépendance à Flutter ni à la base : elle est donc
/// facilement vérifiable et réutilisable (tableau de bord, écran Budgets…).
///
/// Règles :
/// * les dépenses d'une sous-catégorie remontent dans sa catégorie parente ;
/// * le report éventuel correspond au reste du mois précédent, plafonné à 0 ;
/// * les budgets des catégories archivées sont ignorés.
List<BudgetProgress> buildBudgetProgress({
  required List<Category> categories,
  required Map<String, Budget> budgets,
  required Map<String, double> spent,
  Map<String, double> previousSpent = const {},
}) {
  final byId = {for (final category in categories) category.id: category};

  /// Total d'une catégorie et de ses sous-catégories.
  double totalOf(Map<String, double> source, String categoryId) {
    var total = source[categoryId] ?? 0;
    final visited = <String>{categoryId};

    void addChildren(String parentId) {
      for (final category in categories) {
        if (category.parentId != parentId || !visited.add(category.id)) {
          continue;
        }
        total += source[category.id] ?? 0;
        addChildren(category.id);
      }
    }

    addChildren(categoryId);
    return total;
  }

  final progress = <BudgetProgress>[];

  for (final entry in budgets.entries) {
    final category = byId[entry.key];
    if (category == null || category.isArchived) continue;

    final budget = entry.value;
    final carriedOver = budget.carryOver
        ? (budget.monthlyLimit - totalOf(previousSpent, category.id)).clamp(
            0.0,
            double.infinity,
          )
        : 0.0;

    progress.add(
      BudgetProgress(
        category: category,
        budget: budget,
        carriedOver: carriedOver,
        spent: totalOf(spent, category.id),
      ),
    );
  }

  // Les budgets les plus tendus en premier.
  progress.sort((a, b) => b.ratio.compareTo(a.ratio));
  return progress;
}
