import 'package:juka/common/enums/operation_type.dart';
import 'package:juka/common/enums/transaction_category.dart';
import 'package:juka/features/operations/domain/entities/operation.dart';
import 'package:juka/features/operations/domain/repositories/operations_repository.dart';

/// Saisie rapide d'un revenu ou d'une dépense.
///
/// Pour déplacer de l'argent entre deux comptes, voir `CreateTransferUseCase`.
class CreateOperationUseCase {
  const CreateOperationUseCase(this._repository);

  final OperationsRepository _repository;

  Future<Operation> call({
    required String label,
    required OperationType type,
    required double amount,
    required TransactionCategory category,
    required String accountId,
    required DateTime date,
    String? note,
  }) {
    return _repository.createOperation(
      label: label,
      type: type,
      amount: amount,
      category: category,
      accountId: accountId,
      date: date,
      note: note,
    );
  }
}
