import 'package:juka/common/enums/operation_type.dart';
import 'package:juka/common/enums/transaction_category.dart';
import 'package:juka/features/operations/domain/enums/recurrence_frequency.dart';

/// Modèle d'une opération qui se répète (loyer, salaire, abonnements…).
///
/// Le modèle ne contient pas les opérations déjà générées : il décrit seulement
/// ce qu'il faut créer et quand.
class RecurringOperation {
  const RecurringOperation({
    required this.id,
    required this.label,
    required this.type,
    required this.amount,
    required this.category,
    required this.accountId,
    required this.frequency,
    required this.nextOccurrence,
    this.transferAccountId,
    this.note,
    this.isActive = true,
    this.lastGeneratedAt,
  });

  final String id;

  final String label;
  final OperationType type;

  /// Montant toujours positif : le sens est porté par [type].
  final double amount;

  final TransactionCategory category;

  /// Compte débité (dépense, transfert) ou crédité (revenu).
  final String accountId;

  /// Compte crédité pour un transfert récurrent.
  final String? transferAccountId;

  final RecurrenceFrequency frequency;

  /// Prochaine date à laquelle l'opération doit être créée.
  final DateTime nextOccurrence;

  final String? note;

  /// Un modèle en pause est conservé mais ne génère plus rien.
  final bool isActive;

  /// Dernière génération, `null` si jamais exécutée.
  final DateTime? lastGeneratedAt;

  /// `true` si l'échéance est atteinte (ou dépassée) à la date [now].
  bool isDue(DateTime now) =>
      isActive &&
      !nextOccurrence.isAfter(DateTime(now.year, now.month, now.day));

  /// Échéance suivante après [date].
  DateTime occurrenceAfter(DateTime date) {
    var next = nextOccurrence;
    while (!next.isAfter(date)) {
      next = frequency.next(next);
    }
    return next;
  }

  RecurringOperation copyWith({
    String? label,
    OperationType? type,
    double? amount,
    TransactionCategory? category,
    String? accountId,
    String? transferAccountId,
    RecurrenceFrequency? frequency,
    DateTime? nextOccurrence,
    String? note,
    bool? isActive,
    DateTime? lastGeneratedAt,
    bool clearTransferAccount = false,
  }) {
    return RecurringOperation(
      id: id,
      label: label ?? this.label,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      accountId: accountId ?? this.accountId,
      transferAccountId: clearTransferAccount
          ? null
          : (transferAccountId ?? this.transferAccountId),
      frequency: frequency ?? this.frequency,
      nextOccurrence: nextOccurrence ?? this.nextOccurrence,
      note: note ?? this.note,
      isActive: isActive ?? this.isActive,
      lastGeneratedAt: lastGeneratedAt ?? this.lastGeneratedAt,
    );
  }
}
