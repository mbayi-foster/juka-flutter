import 'package:juka/features/operations/domain/entities/recurring_operation.dart';
import 'package:juka/features/operations/domain/repositories/operations_repository.dart';

/// Met en pause ou réactive un modèle récurrent sans le supprimer.
class SetRecurringActiveUseCase {
  const SetRecurringActiveUseCase(this._repository);

  final OperationsRepository _repository;

  Future<RecurringOperation> call({
    required String id,
    required bool isActive,
  }) => _repository.setRecurringActive(id: id, isActive: isActive);
}
