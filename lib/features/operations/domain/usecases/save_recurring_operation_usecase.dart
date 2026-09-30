import 'package:juka/common/enums/operation_type.dart';
import 'package:juka/common/enums/transaction_category.dart';
import 'package:juka/features/operations/domain/entities/recurring_operation.dart';
import 'package:juka/features/operations/domain/enums/recurrence_frequency.dart';
import 'package:juka/features/operations/domain/repositories/operations_repository.dart';

/// Crée ([id] `null`) ou met à jour un modèle d'opération récurrente.
class SaveRecurringOperationUseCase {
  const SaveRecurringOperationUseCase(this._repository);

  final OperationsRepository _repository;

  Future<RecurringOperation> call({
    String? id,
    required String label,
    required OperationType type,
    required double amount,
    required TransactionCategory category,
    required String accountId,
    required RecurrenceFrequency frequency,
    required DateTime nextOccurrence,
    String? transferAccountId,
    String? note,
    bool isActive = true,
  }) {
    return _repository.saveRecurringOperation(
      id: id,
      label: label,
      type: type,
      amount: amount,
      category: category,
      accountId: accountId,
      frequency: frequency,
      nextOccurrence: nextOccurrence,
      transferAccountId: transferAccountId,
      note: note,
      isActive: isActive,
    );
  }
}
