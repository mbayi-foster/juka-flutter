import 'package:juka/features/operations/domain/entities/operation.dart';
import 'package:juka/features/operations/domain/entities/operation_filter.dart';

/// État de la liste des opérations : chargement, données ou erreur.
enum OperationsStatus { loading, ready, failure }

/// État exposé par `operationsControllerProvider`.
class OperationsState {
  const OperationsState({
    this.status = OperationsStatus.loading,
    this.operations = const [],
    this.filter = const OperationFilter(),
    this.errorMessage,
  });

  final OperationsStatus status;

  /// Opérations correspondant à [filter], de la plus récente à la plus ancienne.
  final List<Operation> operations;

  /// Recherche et filtres courants.
  final OperationFilter filter;

  final String? errorMessage;

  bool get isLoading => status == OperationsStatus.loading;

  bool get hasFailed => status == OperationsStatus.failure;

  Operation? operationById(String id) {
    for (final operation in operations) {
      if (operation.id == id) return operation;
    }
    return null;
  }

  OperationsState copyWith({
    OperationsStatus? status,
    List<Operation>? operations,
    OperationFilter? filter,
    String? errorMessage,
  }) {
    return OperationsState(
      status: status ?? this.status,
      operations: operations ?? this.operations,
      filter: filter ?? this.filter,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
