import 'package:juka/features/categories/domain/entities/budget.dart';
import 'package:juka/features/categories/domain/entities/category.dart';

/// État des catégories et de leurs budgets mensuels.
enum CategoriesStatus { loading, ready, failure }

/// État exposé par `categoriesControllerProvider`.
class CategoriesState {
  const CategoriesState({
    this.status = CategoriesStatus.loading,
    this.categories = const [],
    this.budgets = const {},
    this.errorMessage,
  });

  final CategoriesStatus status;

  /// Toutes les catégories, archivées comprises.
  final List<Category> categories;

  /// Budgets indexés par identifiant de catégorie.
  final Map<String, Budget> budgets;

  final String? errorMessage;

  bool get isLoading => status == CategoriesStatus.loading;

  bool get hasFailed => status == CategoriesStatus.failure;

  /// Catégories non archivées.
  List<Category> get activeCategories =>
      _sorted(categories.where((category) => !category.isArchived));

  /// Catégories archivées.
  List<Category> get archivedCategories =>
      _sorted(categories.where((category) => category.isArchived));

  /// Catégories racines (sans parent).
  List<Category> get roots =>
      _sorted(categories.where((category) => category.isRoot));

  /// Catégories pouvant recevoir un budget mensuel.
  List<Category> get budgetable => _sorted(
    categories.where(
      (category) => category.isBudgetable && !category.isArchived,
    ),
  );

  /// Index par identifiant.
  Map<String, Category> get byId => {
    for (final category in categories) category.id: category,
  };

  /// Sous-catégories directes d'une catégorie.
  List<Category> childrenOf(String parentId) =>
      _sorted(categories.where((category) => category.parentId == parentId));

  Category? categoryById(String id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  Budget? budgetOf(String categoryId) => budgets[categoryId];

  /// Profondeur d'une catégorie (0 pour une catégorie racine).
  int depthOf(Category category) {
    var depth = 0;
    var current = category;
    final visited = <String>{category.id};

    while (current.parentId != null && visited.add(current.parentId!)) {
      final parent = categoryById(current.parentId!);
      if (parent == null) break;
      depth++;
      current = parent;
    }
    return depth;
  }

  /// Chemin lisible d'une catégorie : `Alimentation › Restaurant`.
  String pathOf(Category category) {
    final names = <String>[category.name];
    final visited = <String>{category.id};
    var current = category;

    while (current.parentId != null && visited.add(current.parentId!)) {
      final parent = categoryById(current.parentId!);
      if (parent == null) break;
      names.insert(0, parent.name);
      current = parent;
    }

    return names.join(' › ');
  }

  CategoriesState copyWith({
    CategoriesStatus? status,
    List<Category>? categories,
    Map<String, Budget>? budgets,
    String? errorMessage,
  }) {
    return CategoriesState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      budgets: budgets ?? this.budgets,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  static List<Category> _sorted(Iterable<Category> source) {
    final result = source.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }
}
