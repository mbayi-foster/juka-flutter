import 'package:juka/features/operations/domain/repositories/operations_repository.dart';

/// Supprime une opération et ses pièces jointes.
class DeleteOperationUseCase {
  const DeleteOperationUseCase(this._repository);

  final OperationsRepository _repository;

  Future<void> call(String id) => _repository.deleteOperation(id);
}
