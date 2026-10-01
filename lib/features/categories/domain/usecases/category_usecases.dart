import 'package:juka/features/categories/domain/entities/budget.dart';
import 'package:juka/features/categories/domain/entities/category.dart';
import 'package:juka/features/categories/domain/enums/category_kind.dart';
import 'package:juka/features/categories/domain/repositories/categories_repository.dart';

/// Charge les catégories, en créant les catégories par défaut au premier
/// lancement.
class GetCategoriesUseCase {
  const GetCategoriesUseCase(this._repository);

  final CategoriesRepository _repository;

  Future<List<Category>> call() => _repository.ensureDefaults();
}

/// Crée ou met à jour une catégorie (sous-catégorie comprise).
class SaveCategoryUseCase {
  const SaveCategoryUseCase(this._repository);

  final CategoriesRepository _repository;

  Future<Category> call({
    String? id,
    required String name,
    required CategoryKind kind,
    required String iconKey,
    required int colorHex,
    String? parentId,
  }) {
    return _repository.saveCategory(
      id: id,
      name: name,
      kind: kind,
      iconKey: iconKey,
      colorHex: colorHex,
      parentId: parentId,
    );
  }
}

/// Archive ou restaure une catégorie.
class SetCategoryArchivedUseCase {
  const SetCategoryArchivedUseCase(this._repository);

  final CategoriesRepository _repository;

  Future<Category> call({required String id, required bool isArchived}) =>
      _repository.setCategoryArchived(id: id, isArchived: isArchived);
}

/// Supprime une catégorie inutilisée.
class DeleteCategoryUseCase {
  const DeleteCategoryUseCase(this._repository);

  final CategoriesRepository _repository;

  Future<void> call(String id) => _repository.deleteCategory(id);
}

/// Récupère les budgets mensuels, indexés par catégorie.
class GetBudgetsUseCase {
  const GetBudgetsUseCase(this._repository);

  final CategoriesRepository _repository;

  Future<Map<String, Budget>> call() => _repository.fetchBudgets();
}

/// Crée ou met à jour le budget mensuel d'une catégorie.
class SaveBudgetUseCase {
  const SaveBudgetUseCase(this._repository);

  final CategoriesRepository _repository;

  Future<Budget> call({
    required String categoryId,
    required double monthlyLimit,
    required bool carryOver,
  }) {
    return _repository.saveBudget(
      categoryId: categoryId,
      monthlyLimit: monthlyLimit,
      carryOver: carryOver,
    );
  }
}

/// Supprime le budget d'une catégorie.
class DeleteBudgetUseCase {
  const DeleteBudgetUseCase(this._repository);

  final CategoriesRepository _repository;

  Future<void> call(String categoryId) => _repository.deleteBudget(categoryId);
}

/// Récupère les dépenses par catégorie pour un mois donné.
///
/// Les montants sont bruts : l'agrégation des sous-catégories dans leur parent
/// se fait au moment du calcul de l'avancement des budgets.
class GetSpentByCategoryUseCase {
  const GetSpentByCategoryUseCase(this._repository);

  final CategoriesRepository _repository;

  Future<Map<String, double>> call(DateTime month) =>
      _repository.spentByCategory(month);
}
