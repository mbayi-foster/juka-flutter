import 'package:juka/features/categories/domain/enums/category_kind.dart';

/// Catégorie d'opération, personnalisable par l'utilisateur.
///
/// Une catégorie peut avoir une [parentId] : elle devient alors une
/// sous-catégorie, ce qui permet de détailler une dépense (par exemple
/// « Restaurant » sous « Alimentation »).
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.kind,
    required this.iconKey,
    required this.colorHex,
    required this.createdAt,
    this.parentId,
    this.isArchived = false,
  });

  final String id;

  /// Nom donné par l'utilisateur (ex. « Alimentation »).
  final String name;

  final CategoryKind kind;

  /// Catégorie parente, `null` pour une catégorie racine.
  final String? parentId;

  /// Clé de l'icône dans le catalogue `CategoryVisuals`.
  final String iconKey;

  /// Couleur de la catégorie, encodée en ARGB (`0xFF2E7D32`).
  ///
  /// Stockée sous forme d'entier pour garder le domaine indépendant de Flutter.
  final int colorHex;

  final DateTime createdAt;

  /// Une catégorie archivée n'est plus proposée, mais reste lisible sur les
  /// opérations déjà saisies.
  final bool isArchived;

  bool get isSubCategory => parentId != null;

  bool get isRoot => parentId == null;

  /// `true` si la catégorie peut recevoir un budget mensuel.
  bool get isBudgetable => kind.isBudgetable;

  Category copyWith({
    String? name,
    CategoryKind? kind,
    String? parentId,
    String? iconKey,
    int? colorHex,
    bool? isArchived,
    bool clearParent = false,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      parentId: clearParent ? null : (parentId ?? this.parentId),
      iconKey: iconKey ?? this.iconKey,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }
}
