import 'package:juka/features/operations/domain/entities/recurring_operation.dart';
import 'package:juka/features/operations/domain/repositories/operations_repository.dart';

/// Liste les modèles récurrents : loyer, salaire, abonnements…
class GetRecurringOperationsUseCase {
  const GetRecurringOperationsUseCase(this._repository);

  final OperationsRepository _repository;

  Future<List<RecurringOperation>> call() =>
      _repository.fetchRecurringOperations();
}
