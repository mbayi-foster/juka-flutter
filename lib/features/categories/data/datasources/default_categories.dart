import 'package:juka/features/categories/domain/entities/category.dart';
import 'package:juka/features/categories/domain/enums/category_kind.dart';

/// Catégories créées au premier lancement de l'application.
///
/// Leurs identifiants reprennent les valeurs de `TransactionCategory` : les
/// opérations enregistrées avant l'arrivée des catégories personnalisables
/// restent ainsi rattachées sans migration de données.
abstract final class DefaultCategories {
  /// Libellés des catégories issues de l'énumération historique.
  static const Map<String, String> _labels = {
    'housing': 'Logement',
    'food': 'Alimentation',
    'transport': 'Transport',
    'restaurants': 'Restaurants',
    'leisure': 'Loisirs',
    'health': 'Santé',
    'shopping': 'Shopping',
    'subscriptions': 'Abonnements',
    'salary': 'Salaire',
    'savings': 'Épargne',
    'transfer': 'Transfert',
    'other': 'Divers',
  };

  /// Icône (clé du catalogue) et couleur ARGB de chaque catégorie par défaut.
  static const Map<String, (String, int)> _visuals = {
    'housing': ('home', 0xFF6C63FF),
    'food': ('basket', 0xFF2E7D32),
    'transport': ('car', 0xFF0288D1),
    'restaurants': ('restaurant', 0xFFEB8A3E),
    'leisure': ('game', 0xFFEC407A),
    'health': ('health', 0xFF26A69A),
    'shopping': ('bag', 0xFF8D6E63),
    'subscriptions': ('subscription', 0xFF7E57C2),
    'salary': ('salary', 0xFF2E7D32),
    'savings': ('savings', 0xFFF5B301),
    'transfer': ('transfer', 0xFF2563EB),
    'other': ('other', 0xFF8A8A8A),
  };

  /// Sens par défaut de chaque catégorie.
  static const Map<String, CategoryKind> _kinds = {
    'salary': CategoryKind.income,
    'savings': CategoryKind.income,
    'transfer': CategoryKind.transfer,
  };

  /// Construit la liste des catégories par défaut.
  ///
  /// [now] est injectable pour rendre la génération déterministe en test.
  static List<Category> build({DateTime? now}) {
    final createdAt = now ?? DateTime.now();

    return [
      for (final entry in _labels.entries)
        Category(
          id: entry.key,
          name: entry.value,
          kind: _kinds[entry.key] ?? CategoryKind.expense,
          iconKey: _visuals[entry.key]?.$1 ?? 'other',
          colorHex: _visuals[entry.key]?.$2 ?? 0xFF8A8A8A,
          createdAt: createdAt,
        ),
    ];
  }
}
