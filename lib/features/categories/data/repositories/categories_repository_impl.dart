import 'package:juka/features/categories/data/exceptions/categories_exception.dart';
import 'package:juka/features/categories/domain/entities/budget.dart';
import 'package:juka/features/categories/domain/entities/category.dart';
import 'package:juka/features/categories/domain/enums/category_kind.dart';
import 'package:juka/features/categories/domain/failures/categories_failure.dart';
import 'package:juka/features/categories/domain/repositories/categories_repository.dart';

/// Implémentation du contrat [CategoriesRepository] au-dessus de la source
/// locale SQLite.
///
/// Elle traduit les [CategoriesException] techniques en [CategoriesFailure]
/// métier, et laisse remonter les refus de suppression tels quels.
class CategoriesRepositoryImpl implements CategoriesRepository {
  const CategoriesRepositoryImpl(this._localDataSource);

  /// Source locale : SQLite en production, doublure dans les tests.
  final CategoriesRepository _localDataSource;

  static const String _unexpectedMessage =
      'Une erreur inattendue est survenue. Veuillez réessayer.';

  @override
  Future<List<Category>> fetchCategories() =>
      _guard(_localDataSource.fetchCategories);

  @override
  Future<List<Category>> ensureDefaults() =>
      _guard(_localDataSource.ensureDefaults);

  @override
  Future<Category> saveCategory({
    String? id,
    required String name,
    required CategoryKind kind,
    required String iconKey,
    required int colorHex,
    String? parentId,
  }) {
    return _guard(
      () => _localDataSource.saveCategory(
        id: id,
        name: name,
        kind: kind,
        iconKey: iconKey,
        colorHex: colorHex,
        parentId: parentId,
      ),
    );
  }

  @override
  Future<Category> setCategoryArchived({
    required String id,
    required bool isArchived,
  }) {
    return _guard(
      () =>
          _localDataSource.setCategoryArchived(id: id, isArchived: isArchived),
    );
  }

  @override
  Future<void> deleteCategory(String id) =>
      _guard(() => _localDataSource.deleteCategory(id));

  @override
  Future<Map<String, Budget>> fetchBudgets() =>
      _guard(_localDataSource.fetchBudgets);

  @override
  Future<Budget> saveBudget({
    required String categoryId,
    required double monthlyLimit,
    required bool carryOver,
  }) {
    return _guard(
      () => _localDataSource.saveBudget(
        categoryId: categoryId,
        monthlyLimit: monthlyLimit,
        carryOver: carryOver,
      ),
    );
  }

  @override
  Future<void> deleteBudget(String categoryId) =>
      _guard(() => _localDataSource.deleteBudget(categoryId));

  @override
  Future<Map<String, double>> spentByCategory(DateTime month) =>
      _guard(() => _localDataSource.spentByCategory(month));

  /// Exécute [action] et convertit les erreurs techniques en
  /// [CategoriesFailure].
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on CategoriesFailure {
      rethrow;
    } on CategoriesException catch (exception) {
      throw CategoriesFailure(exception.message);
    } catch (_) {
      throw const CategoriesFailure(_unexpectedMessage);
    }
  }
}
