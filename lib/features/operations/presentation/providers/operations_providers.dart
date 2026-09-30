import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:juka/common/enums/operation_type.dart';
import 'package:juka/common/enums/transaction_category.dart';
import 'package:juka/features/operations/data/datasources/operations_sqflite_data_source.dart';
import 'package:juka/features/operations/data/repositories/operations_repository_impl.dart';
import 'package:juka/features/operations/domain/entities/operation_filter.dart';
import 'package:juka/features/operations/domain/failures/operations_failure.dart';
import 'package:juka/features/operations/domain/repositories/operations_repository.dart';
import 'package:juka/features/operations/domain/usecases/create_operation_usecase.dart';
import 'package:juka/features/operations/domain/usecases/create_transfer_usecase.dart';
import 'package:juka/features/operations/domain/usecases/delete_operation_usecase.dart';
import 'package:juka/features/operations/domain/usecases/get_operations_usecase.dart';
import 'package:juka/features/operations/domain/usecases/update_operation_usecase.dart';
import 'package:juka/features/operations/presentation/state/operations_state.dart';
import 'package:juka/shared/database/app_database.dart';

// ---------------------------------------------------------------------------
// Injection des dépendances (data -> domain)
// ---------------------------------------------------------------------------

/// Source locale des opérations : SQLite, dans la base partagée de
/// l'application.
final operationsLocalDataSourceProvider = Provider<OperationsRepository>(
  (ref) => OperationsSqfliteDataSource(ref.watch(appDatabaseProvider)),
);

final operationsRepositoryProvider = Provider<OperationsRepository>(
  (ref) =>
      OperationsRepositoryImpl(ref.watch(operationsLocalDataSourceProvider)),
);

final getOperationsUseCaseProvider = Provider<GetOperationsUseCase>(
  (ref) => GetOperationsUseCase(ref.watch(operationsRepositoryProvider)),
);

final createOperationUseCaseProvider = Provider<CreateOperationUseCase>(
  (ref) => CreateOperationUseCase(ref.watch(operationsRepositoryProvider)),
);

final updateOperationUseCaseProvider = Provider<UpdateOperationUseCase>(
  (ref) => UpdateOperationUseCase(ref.watch(operationsRepositoryProvider)),
);

final deleteOperationUseCaseProvider = Provider<DeleteOperationUseCase>(
  (ref) => DeleteOperationUseCase(ref.watch(operationsRepositoryProvider)),
);

final createTransferUseCaseProvider = Provider<CreateTransferUseCase>(
  (ref) => CreateTransferUseCase(ref.watch(operationsRepositoryProvider)),
);

// ---------------------------------------------------------------------------
// Contrôleur
// ---------------------------------------------------------------------------

/// Charge, filtre et enregistre les opérations.
final operationsControllerProvider =
    NotifierProvider<OperationsController, OperationsState>(
      OperationsController.new,
    );

class OperationsController extends Notifier<OperationsState> {
  static const String _unexpectedMessage =
      'Une erreur inattendue est survenue. Veuillez réessayer.';

  @override
  OperationsState build() => const OperationsState();

  /// Charge les opérations correspondant au filtre courant.
  Future<void> load() async {
    state = OperationsState(
      status: OperationsStatus.loading,
      operations: state.operations,
      filter: state.filter,
    );
    await _reload();
  }

  /// Applique de nouveaux critères de recherche puis recharge la liste.
  Future<void> applyFilter(OperationFilter filter) async {
    state = OperationsState(
      status: state.status,
      operations: state.operations,
      filter: filter,
    );
    await load();
  }

  /// Enregistre un revenu ou une dépense.
  Future<String?> create({
    required String label,
    required OperationType type,
    required double amount,
    required TransactionCategory category,
    required String accountId,
    required DateTime date,
    String? note,
  }) {
    return _mutate(
      () => ref.read(createOperationUseCaseProvider)(
        label: label,
        type: type,
        amount: amount,
        category: category,
        accountId: accountId,
        date: date,
        note: note,
      ),
    );
  }

  /// Enregistre un transfert entre deux comptes (ni revenu, ni dépense).
  Future<String?> createTransfer({
    required String label,
    required double amount,
    required String fromAccountId,
    required String toAccountId,
    required DateTime date,
    String? note,
  }) {
    return _mutate(
      () => ref.read(createTransferUseCaseProvider)(
        label: label,
        amount: amount,
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
        date: date,
        note: note,
      ),
    );
  }

  /// Modifie une opération existante.
  Future<String?> update({
    required String id,
    required String label,
    required OperationType type,
    required double amount,
    required TransactionCategory category,
    required String accountId,
    required DateTime date,
    String? note,
  }) {
    return _mutate(
      () => ref.read(updateOperationUseCaseProvider)(
        id: id,
        label: label,
        type: type,
        amount: amount,
        category: category,
        accountId: accountId,
        date: date,
        note: note,
      ),
    );
  }

  Future<String?> delete(String id) =>
      _mutate(() => ref.read(deleteOperationUseCaseProvider)(id));

  /// Exécute une mutation puis recharge la liste. Retourne le message d'erreur
  /// à afficher, ou `null` en cas de succès.
  Future<String?> _mutate(Future<Object?> Function() action) async {
    try {
      await action();
      await _reload();
      return null;
    } on OperationsFailure catch (failure) {
      return failure.message;
    } catch (_) {
      return _unexpectedMessage;
    }
  }

  /// Recharge la liste sans repasser par l'état de chargement, pour éviter un
  /// clignotement après une saisie.
  Future<void> _reload() async {
    try {
      final operations = await ref.read(getOperationsUseCaseProvider)(
        state.filter,
      );
      state = OperationsState(
        status: OperationsStatus.ready,
        operations: operations,
        filter: state.filter,
      );
    } on OperationsFailure catch (failure) {
      state = OperationsState(
        status: OperationsStatus.failure,
        operations: state.operations,
        filter: state.filter,
        errorMessage: failure.message,
      );
    } catch (_) {
      state = OperationsState(
        status: OperationsStatus.failure,
        operations: state.operations,
        filter: state.filter,
        errorMessage: _unexpectedMessage,
      );
    }
  }
}
