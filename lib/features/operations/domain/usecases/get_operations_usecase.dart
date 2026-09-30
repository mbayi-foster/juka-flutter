import 'package:juka/features/operations/domain/entities/operation.dart';
import 'package:juka/features/operations/domain/entities/operation_filter.dart';
import 'package:juka/features/operations/domain/repositories/operations_repository.dart';

/// Récupère les opérations correspondant à un filtre : période, compte,
/// catégorie et recherche libre.
class GetOperationsUseCase {
  const GetOperationsUseCase(this._repository);

  final OperationsRepository _repository;

  Future<List<Operation>> call(OperationFilter filter) =>
      _repository.fetchOperations(filter);
}
