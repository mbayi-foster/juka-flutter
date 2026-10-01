import 'package:sqflite/sqflite.dart';

import 'package:juka/common/enums/operation_type.dart';
import 'package:juka/features/categories/data/datasources/default_categories.dart';
import 'package:juka/features/categories/data/exceptions/categories_exception.dart';
import 'package:juka/features/categories/domain/entities/budget.dart';
import 'package:juka/features/categories/domain/entities/category.dart';
import 'package:juka/features/categories/domain/enums/category_kind.dart';
import 'package:juka/features/categories/domain/repositories/categories_repository.dart';
import 'package:juka/shared/database/app_database.dart';

/// Implémentation SQLite de [CategoriesRepository].
///
/// Les catégories remplacent l'ancienne énumération figée : elles sont créées
/// au premier lancement (voir `DefaultCategories`) puis modifiables par
/// l'utilisateur. Leur identifiant est celui utilisé par la colonne `category`
/// des opérations, ce qui rend les deux mondes compatibles sans migration.
class CategoriesSqfliteDataSource implements CategoriesRepository {
  const CategoriesSqfliteDataSource(this._appDatabase);

  static const String _categories = 'categories';
  static const String _budgets = 'budgets';
  static const String _operations = 'operations';

  final AppDatabase _appDatabase;

  /// Connexion partagée par tous les modules.
  Future<Database> get _db => _appDatabase.database;

  @override
  Future<List<Category>> fetchCategories() async {
    final db = await _db;
    final rows = await db.query(
      _categories,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return [for (final row in rows) _fromRow(row)];
  }

  @override
  Future<List<Category>> ensureDefaults() async {
    final db = await _db;
    final count =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $_categories'),
        ) ??
        0;

    if (count == 0) {
      final batch = db.batch();
      for (final category in DefaultCategories.build()) {
        batch.insert(_categories, _toRow(category));
      }
      await batch.commit(noResult: true);
    }

    return fetchCategories();
  }

  @override
  Future<Category> saveCategory({
    String? id,
    required String name,
    required CategoryKind kind,
    required String iconKey,
    required int colorHex,
    String? parentId,
  }) async {
    final db = await _db;
    final existing = id == null ? null : await _findById(id);

    final category = Category(
      id: id ?? _nextId(),
      name: name,
      kind: kind,
      parentId: parentId,
      iconKey: iconKey,
      colorHex: colorHex,
      createdAt: existing?.createdAt ?? DateTime.now(),
      isArchived: existing?.isArchived ?? false,
    );

    await db.insert(
      _categories,
      _toRow(category),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return category;
  }

  @override
  Future<Category> setCategoryArchived({
    required String id,
    required bool isArchived,
  }) async {
    final db = await _db;
    await _findById(id);

    await db.transaction((txn) async {
      final values = {'is_archived': isArchived ? 1 : 0};
      await txn.update(_categories, values, where: 'id = ?', whereArgs: [id]);
      // Les sous-catégories suivent l'état de leur parent.
      await txn.update(
        _categories,
        values,
        where: 'parent_id = ?',
        whereArgs: [id],
      );
    });

    return _findById(id);
  }

  @override
  Future<void> deleteCategory(String id) async {
    final db = await _db;
    await _findById(id);

    if (await _count('SELECT COUNT(*) FROM $_categories WHERE parent_id = ?', [
          id,
        ]) >
        0) {
      throw const CategoriesException(
        'Cette catégorie contient des sous-catégories : supprimez-les d\'abord '
        'ou archivez la catégorie.',
      );
    }

    if (await _count('SELECT COUNT(*) FROM $_budgets WHERE category_id = ?', [
          id,
        ]) >
        0) {
      throw const CategoriesException(
        'Cette catégorie a un budget : archivez-la plutôt que de la '
        'supprimer.',
      );
    }

    if (await _count('SELECT COUNT(*) FROM $_operations WHERE category = ?', [
          id,
        ]) >
        0) {
      throw const CategoriesException(
        'Cette catégorie est utilisée par des opérations : archivez-la plutôt '
        'que de la supprimer.',
      );
    }

    await db.delete(_categories, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<Map<String, Budget>> fetchBudgets() async {
    final db = await _db;
    final rows = await db.query(_budgets);
    return {
      for (final row in rows)
        row['category_id']! as String: _budgetFromRow(row),
    };
  }

  @override
  Future<Budget> saveBudget({
    required String categoryId,
    required double monthlyLimit,
    required bool carryOver,
  }) async {
    final db = await _db;
    await _findById(categoryId);

    final budget = Budget(
      categoryId: categoryId,
      monthlyLimit: monthlyLimit,
      carryOver: carryOver,
      updatedAt: DateTime.now(),
    );

    await db.insert(
      _budgets,
      _budgetToRow(budget),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return budget;
  }

  @override
  Future<void> deleteBudget(String categoryId) async {
    final db = await _db;
    await db.delete(
      _budgets,
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
  }

  @override
  Future<Map<String, double>> spentByCategory(DateTime month) async {
    final db = await _db;
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);

    final rows = await db.rawQuery(
      'SELECT category, SUM(amount) AS total FROM $_operations '
      'WHERE type = ? AND date >= ? AND date < ? '
      'GROUP BY category',
      [
        OperationType.expense.name,
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
    );

    return {
      for (final row in rows)
        row['category']! as String: (row['total'] as num?)?.toDouble() ?? 0,
    };
  }

  Future<int> _count(String sql, List<Object?> args) async {
    final db = await _db;
    return Sqflite.firstIntValue(await db.rawQuery(sql, args)) ?? 0;
  }

  Future<Category> _findById(String id) async {
    final db = await _db;
    final rows = await db.query(
      _categories,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw const CategoriesException('Cette catégorie est introuvable.');
    }
    return _fromRow(rows.first);
  }

  String _nextId() => 'cat-${DateTime.now().microsecondsSinceEpoch}';

  Map<String, Object?> _toRow(Category category) => {
    'id': category.id,
    'name': category.name,
    'kind': category.kind.name,
    'parent_id': category.parentId,
    'icon_key': category.iconKey,
    'color_hex': category.colorHex,
    'is_archived': category.isArchived ? 1 : 0,
    'created_at': category.createdAt.millisecondsSinceEpoch,
  };

  Category _fromRow(Map<String, Object?> row) {
    return Category(
      id: row['id']! as String,
      name: row['name']! as String,
      kind: CategoryKind.values.byName(row['kind']! as String),
      parentId: row['parent_id'] as String?,
      iconKey: row['icon_key']! as String,
      colorHex: row['color_hex']! as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
      isArchived: (row['is_archived']! as int) == 1,
    );
  }

  Map<String, Object?> _budgetToRow(Budget budget) => {
    'category_id': budget.categoryId,
    'monthly_limit': budget.monthlyLimit,
    'carry_over': budget.carryOver ? 1 : 0,
    'updated_at': (budget.updatedAt ?? DateTime.now()).millisecondsSinceEpoch,
  };

  Budget _budgetFromRow(Map<String, Object?> row) {
    final updatedAt = row['updated_at'] as int?;

    return Budget(
      categoryId: row['category_id']! as String,
      monthlyLimit: (row['monthly_limit']! as num).toDouble(),
      carryOver: (row['carry_over']! as int) == 1,
      updatedAt: updatedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(updatedAt),
    );
  }
}
