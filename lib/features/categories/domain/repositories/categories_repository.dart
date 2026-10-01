import 'package:juka/features/categories/domain/entities/budget.dart';
import 'package:juka/features/categories/domain/entities/category.dart';
import 'package:juka/features/categories/domain/enums/category_kind.dart';

/// Contrat du domaine pour les catégories et leurs budgets mensuels.
abstract interface class CategoriesRepository {
  /// Toutes les catégories, archivées comprises.
  Future<List<Category>> fetchCategories();

  /// Crée les catégories par défaut si la base n'en contient aucune, puis les
  /// retourne. Les identifiants reprennent ceux des catégories historiques.
  Future<List<Category>> ensureDefaults();

  /// Crée ([id] `null`) ou met à jour une catégorie.
  Future<Category> saveCategory({
    String? id,
    required String name,
    required CategoryKind kind,
    required String iconKey,
    required int colorHex,
    String? parentId,
  });

  /// Archive ou restaure une catégorie (et, par ricochet, ses sous-catégories).
  Future<Category> setCategoryArchived({
    required String id,
    required bool isArchived,
  });

  /// Supprime définitivement une catégorie.
  ///
  /// Échoue si elle est utilisée par une opération, un budget ou une
  /// sous-catégorie : il faut alors l'archiver.
  Future<void> deleteCategory(String id);

  /// Budgets indexés par identifiant de catégorie.
  Future<Map<String, Budget>> fetchBudgets();

  /// Crée ou met à jour le budget mensuel d'une catégorie.
  Future<Budget> saveBudget({
    required String categoryId,
    required double monthlyLimit,
    required bool carryOver,
  });

  /// Supprime le budget d'une catégorie.
  Future<void> deleteBudget(String categoryId);

  /// Dépenses par catégorie sur un mois donné, sous-catégories incluses.
  ///
  /// Les transferts sont ignorés : ils ne sont pas des dépenses.
  Future<Map<String, double>> spentByCategory(DateTime month);
}
