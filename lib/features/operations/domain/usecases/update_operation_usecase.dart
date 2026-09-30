import 'package:juka/common/enums/operation_type.dart';
import 'package:juka/common/enums/transaction_category.dart';
import 'package:juka/features/operations/domain/entities/operation.dart';
import 'package:juka/features/operations/domain/repositories/operations_repository.dart';

/// Modifie une opération existante (la liste permet de la rouvrir).
class UpdateOperationUseCase {
  const UpdateOperationUseCase(this._repository);

  final OperationsRepository _repository;

  Future<Operation> call({
    required String id,
    required String label,
    required OperationType type,
    required double amount,
    required TransactionCategory category,
    required String accountId,
    required DateTime date,
    String? note,
  }) {
    return _repository.updateOperation(
      id: id,
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
