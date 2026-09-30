import 'package:juka/common/enums/operation_type.dart';
import 'package:juka/common/enums/transaction_category.dart';
import 'package:juka/features/operations/domain/entities/operation_attachment.dart';

/// Opération financière : revenu, dépense ou transfert entre deux comptes.
class Operation {
  const Operation({
    required this.id,
    required this.label,
    required this.type,
    required this.amount,
    required this.category,
    required this.accountId,
    required this.date,
    this.transferAccountId,
    this.note,
    this.attachments = const [],
    this.recurringOperationId,
  });

  final String id;

  /// Libellé saisi par l'utilisateur (ex. « Courses alimentaires »).
  final String label;

  final OperationType type;

  /// Montant toujours positif : le sens est porté par [type].
  final double amount;

  final TransactionCategory category;

  /// Compte débité (dépense, transfert) ou crédité (revenu).
  final String accountId;

  /// Compte crédité, uniquement pour un [OperationType.transfer].
  final String? transferAccountId;

  final DateTime date;

  final String? note;

  /// Photos de reçus rattachées à l'opération.
  final List<OperationAttachment> attachments;

  /// Opération récurrente à l'origine de cette ligne, `null` si saisie à la main.
  final String? recurringOperationId;

  bool get isTransfer => type.isTransfer;

  bool get isIncome => type.isIncome;

  bool get isExpense => type.isExpense;

  /// Montant signé vu du compte source, prêt à être formaté.
  double get signedAmount => type.isIncome ? amount : -amount;

  /// Un transfert valide doit viser un autre compte que le compte source.
  bool get isValidTransfer =>
      !isTransfer ||
      (transferAccountId != null && transferAccountId != accountId);

  /// Comptes réellement impactés par l'opération.
  List<String> get impactedAccountIds => [accountId, ?transferAccountId];

  Operation copyWith({
    String? label,
    OperationType? type,
    double? amount,
    TransactionCategory? category,
    String? accountId,
    DateTime? date,
    String? transferAccountId,
    String? note,
    List<OperationAttachment>? attachments,
    String? recurringOperationId,
    bool clearTransferAccount = false,
  }) {
    return Operation(
      id: id,
      label: label ?? this.label,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      accountId: accountId ?? this.accountId,
      date: date ?? this.date,
      transferAccountId: clearTransferAccount
          ? null
          : (transferAccountId ?? this.transferAccountId),
      note: note ?? this.note,
      attachments: attachments ?? this.attachments,
      recurringOperationId: recurringOperationId ?? this.recurringOperationId,
    );
  }
}
