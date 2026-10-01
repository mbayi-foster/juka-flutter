import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juka/features/categories/data/datasources/categories_sqflite_data_source.dart';
import 'package:juka/features/categories/data/repositories/categories_repository_impl.dart';
import 'package:juka/features/categories/domain/entities/budget_progress.dart';
import 'package:juka/features/categories/domain/enums/category_kind.dart';
import 'package:juka/features/categories/domain/failures/categories_failure.dart';
import 'package:juka/features/categories/domain/repositories/categories_repository.dart';
import 'package:juka/features/categories/domain/services/budget_progress_calculator.dart';
import 'package:juka/features/categories/domain/usecases/category_usecases.dart';
import 'package:juka/features/categories/presentation/state/categories_state.dart';
import 'package:juka/shared/database/app_database.dart';

// ---------------------------------------------------------------------------
// Injection des dépendances (data -> domain)
// ---------------------------------------------------------------------------

/// Source locale des catégories et budgets : SQLite.
final categoriesLocalDataSourceProvider = Provider<CategoriesRepository>(
  (ref) => CategoriesSqfliteDataSource(ref.watch(appDatabaseProvider)),
);

final categoriesRepositoryProvider = Provider<CategoriesRepository>(
  (ref) =>
      CategoriesRepositoryImpl(ref.watch(categoriesLocalDataSourceProvider)),
);

final getCategoriesUseCaseProvider = Provider<GetCategoriesUseCase>(
  (ref) => GetCategoriesUseCase(ref.watch(categoriesRepositoryProvider)),
);

final saveCategoryUseCaseProvider = Provider<SaveCategoryUseCase>(
  (ref) => SaveCategoryUseCase(ref.watch(categoriesRepositoryProvider)),
);

final setCategoryArchivedUseCaseProvider = Provider<SetCategoryArchivedUseCase>(
  (ref) => SetCategoryArchivedUseCase(ref.watch(categoriesRepositoryProvider)),
);

final deleteCategoryUseCaseProvider = Provider<DeleteCategoryUseCase>(
  (ref) => DeleteCategoryUseCase(ref.watch(categoriesRepositoryProvider)),
);

final getBudgetsUseCaseProvider = Provider<GetBudgetsUseCase>(
  (ref) => GetBudgetsUseCase(ref.watch(categoriesRepositoryProvider)),
);

final saveBudgetUseCaseProvider = Provider<SaveBudgetUseCase>(
  (ref) => SaveBudgetUseCase(ref.watch(categoriesRepositoryProvider)),
);

final deleteBudgetUseCaseProvider = Provider<DeleteBudgetUseCase>(
  (ref) => DeleteBudgetUseCase(ref.watch(categoriesRepositoryProvider)),
);

final getSpentByCategoryUseCaseProvider = Provider<GetSpentByCategoryUseCase>(
  (ref) => GetSpentByCategoryUseCase(ref.watch(categoriesRepositoryProvider)),
);

// ---------------------------------------------------------------------------
// Contrôleur
// ---------------------------------------------------------------------------

/// Charge et modifie les catégories et les budgets mensuels.
final categoriesControllerProvider =
    NotifierProvider<CategoriesController, CategoriesState>(
      CategoriesController.new,
    );

class CategoriesController extends Notifier<CategoriesState> {
  static const String _unexpectedMessage =
      'Une erreur inattendue est survenue. Veuillez réessayer.';

  @override
  CategoriesState build() => const CategoriesState();

  /// Charge les catégories (créées au premier lancement) et leurs budgets.
  Future<void> load() async {
    state = CategoriesState(
      status: CategoriesStatus.loading,
      categories: state.categories,
      budgets: state.budgets,
    );
    await _reload();
  }

  /// Crée ou met à jour une catégorie.
  Future<String?> saveCategory({
    String? id,
    required String name,
    required CategoryKind kind,
    required String iconKey,
    required int colorHex,
    String? parentId,
  }) {
    return _mutate(
      () => ref.read(saveCategoryUseCaseProvider)(
        id: id,
        name: name,
        kind: kind,
        iconKey: iconKey,
        colorHex: colorHex,
        parentId: parentId,
      ),
    );
  }

  /// Archive ou restaure une catégorie.
  Future<String?> setCategoryArchived({
    required String id,
    required bool isArchived,
  }) {
    return _mutate(
      () => ref.read(setCategoryArchivedUseCaseProvider)(
        id: id,
        isArchived: isArchived,
      ),
    );
  }

  /// Supprime une catégorie inutilisée.
  Future<String?> deleteCategory(String id) =>
      _mutate(() => ref.read(deleteCategoryUseCaseProvider)(id));

  /// Enregistre le budget mensuel d'une catégorie.
  Future<String?> saveBudget({
    required String categoryId,
    required double monthlyLimit,
    required bool carryOver,
  }) {
    return _mutate(
      () => ref.read(saveBudgetUseCaseProvider)(
        categoryId: categoryId,
        monthlyLimit: monthlyLimit,
        carryOver: carryOver,
      ),
    );
  }

  /// Supprime le budget d'une catégorie.
  Future<String?> deleteBudget(String categoryId) =>
      _mutate(() => ref.read(deleteBudgetUseCaseProvider)(categoryId));

  Future<String?> _mutate(Future<Object?> Function() action) async {
    try {
      await action();
      await _reload();
      return null;
    } on CategoriesFailure catch (failure) {
      return failure.message;
    } catch (_) {
      return _unexpectedMessage;
    }
  }

  /// Recharge sans repasser par l'état de chargement (pas de clignotement).
  Future<void> _reload() async {
    try {
      final categories = await ref.read(getCategoriesUseCaseProvider)();
      final budgets = await ref.read(getBudgetsUseCaseProvider)();
      state = CategoriesState(
        status: CategoriesStatus.ready,
        categories: categories,
        budgets: budgets,
      );
    } on CategoriesFailure catch (failure) {
      state = CategoriesState(
        status: CategoriesStatus.failure,
        categories: state.categories,
        budgets: state.budgets,
        errorMessage: failure.message,
      );
    } catch (_) {
      state = CategoriesState(
        status: CategoriesStatus.failure,
        categories: state.categories,
        budgets: state.budgets,
        errorMessage: _unexpectedMessage,
      );
    }
  }
}

// ---------------------------------------------------------------------------
// Avancement des budgets
// ---------------------------------------------------------------------------

/// Avancement du mois en cours : prévu contre réel, par budget.
final budgetProgressProvider = FutureProvider<List<BudgetProgress>>((
  ref,
) async {
  final state = ref.watch(categoriesControllerProvider);
  final spentByCategory = ref.watch(getSpentByCategoryUseCaseProvider);

  final now = DateTime.now();
  final spent = await spentByCategory(DateTime(now.year, now.month));
  final previousSpent = await spentByCategory(
    DateTime(now.year, now.month - 1),
  );

  return buildBudgetProgress(
    categories: state.categories,
    budgets: state.budgets,
    spent: spent,
    previousSpent: previousSpent,
  );
});
