import 'package:juka/features/operations/domain/repositories/operations_repository.dart';

/// Supprime un modèle récurrent (les opérations déjà créées sont conservées).
class DeleteRecurringOperationUseCase {
  const DeleteRecurringOperationUseCase(this._repository);

  final OperationsRepository _repository;

  Future<void> call(String id) => _repository.deleteRecurringOperation(id);
}
