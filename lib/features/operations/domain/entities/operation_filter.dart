import 'package:juka/common/enums/operation_type.dart';
import 'package:juka/common/enums/transaction_category.dart';
import 'package:juka/features/operations/domain/entities/operation.dart';

/// Critères de recherche et de filtrage de la liste des opérations.
///
/// Les mêmes règles servent à toutes les implémentations de
/// `OperationsRepository` (mémoire, SQLite) grâce à [matches] : le
/// comportement des filtres est donc identique partout.
class OperationFilter {
  const OperationFilter({
    this.query = '',
    this.from,
    this.to,
    this.accountId,
    this.category,
    this.type,
  });

  /// Recherche libre sur le libellé et la note.
  final String query;

  /// Borne de début de période (incluse).
  final DateTime? from;

  /// Borne de fin de période (incluse).
  final DateTime? to;

  /// Compte concerné (compte source pour un transfert).
  final String? accountId;

  final TransactionCategory? category;
  final OperationType? type;

  bool get hasQuery => query.trim().isNotEmpty;

  bool get hasPeriod => from != null || to != null;

  bool get hasAccount => accountId != null;

  bool get hasCategory => category != null;

  bool get hasType => type != null;

  /// `true` lorsqu'aucun critère n'est appliqué.
  bool get isEmpty =>
      !hasQuery && !hasPeriod && !hasAccount && !hasCategory && !hasType;

  /// Nombre de filtres actifs hors recherche libre (badge de l'interface).
  int get activeCount =>
      (hasPeriod ? 1 : 0) +
      (hasAccount ? 1 : 0) +
      (hasCategory ? 1 : 0) +
      (hasType ? 1 : 0);

  /// La date est-elle comprise dans la période demandée ?
  bool matchesDate(DateTime date) {
    final from = this.from;
    final to = this.to;
    if (from != null && date.isBefore(from)) return false;
    if (to != null && date.isAfter(to)) return false;
    return true;
  }

  /// L'opération satisfait-elle tous les critères ?
  bool matches(Operation operation) {
    if (hasQuery) {
      final needle = query.trim().toLowerCase();
      final haystack = '${operation.label} ${operation.note ?? ''}'
          .toLowerCase();
      if (!haystack.contains(needle)) return false;
    }

    if (!matchesDate(operation.date)) return false;

    final accountId = this.accountId;
    if (accountId != null &&
        !operation.impactedAccountIds.contains(accountId)) {
      return false;
    }

    final category = this.category;
    if (category != null && operation.category != category) return false;

    final type = this.type;
    if (type != null && operation.type != type) return false;

    return true;
  }

  OperationFilter copyWith({
    String? query,
    DateTime? from,
    DateTime? to,
    String? accountId,
    TransactionCategory? category,
    OperationType? type,
    bool clearPeriod = false,
    bool clearAccount = false,
    bool clearCategory = false,
    bool clearType = false,
  }) {
    return OperationFilter(
      query: query ?? this.query,
      from: clearPeriod ? null : (from ?? this.from),
      to: clearPeriod ? null : (to ?? this.to),
      accountId: clearAccount ? null : (accountId ?? this.accountId),
      category: clearCategory ? null : (category ?? this.category),
      type: clearType ? null : (type ?? this.type),
    );
  }

  /// Réinitialise la recherche et tous les filtres.
  OperationFilter cleared() => const OperationFilter();
}
