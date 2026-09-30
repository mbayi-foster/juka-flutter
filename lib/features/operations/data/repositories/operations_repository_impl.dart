import 'package:juka/common/enums/operation_type.dart';
import 'package:juka/common/enums/transaction_category.dart';
import 'package:juka/features/operations/data/exceptions/operations_exception.dart';
import 'package:juka/features/operations/domain/entities/operation.dart';
import 'package:juka/features/operations/domain/entities/operation_attachment.dart';
import 'package:juka/features/operations/domain/entities/operation_filter.dart';
import 'package:juka/features/operations/domain/entities/recurring_operation.dart';
import 'package:juka/features/operations/domain/enums/recurrence_frequency.dart';
import 'package:juka/features/operations/domain/failures/operations_failure.dart';
import 'package:juka/features/operations/domain/repositories/operations_repository.dart';

/// Implémentation du contrat [OperationsRepository] au-dessus de la source
/// locale SQLite.
///
/// Elle traduit les [OperationsException] techniques en [OperationsFailure]
/// métier, afin que le domaine ne manipule que des erreurs affichables.
class OperationsRepositoryImpl implements OperationsRepository {
  const OperationsRepositoryImpl(this._localDataSource);

  /// Source locale : SQLite en production, en mémoire dans les tests.
  final OperationsRepository _localDataSource;

  static const String _unexpectedMessage =
      'Une erreur inattendue est survenue. Veuillez réessayer.';

  @override
  Future<List<Operation>> fetchOperations(OperationFilter filter) =>
      _guard(() => _localDataSource.fetchOperations(filter));

  @override
  Future<Operation> fetchOperation(String id) =>
      _guard(() => _localDataSource.fetchOperation(id));

  @override
  Future<Operation> createOperation({
    required String label,
    required OperationType type,
    required double amount,
    required TransactionCategory category,
    required String accountId,
    required DateTime date,
    String? note,
    String? recurringOperationId,
  }) {
    return _guard(
      () => _localDataSource.createOperation(
        label: label,
        type: type,
        amount: amount,
        category: category,
        accountId: accountId,
        date: date,
        note: note,
        recurringOperationId: recurringOperationId,
      ),
    );
  }

  @override
  Future<Operation> updateOperation({
    required String id,
    required String label,
    required OperationType type,
    required double amount,
    required TransactionCategory category,
    required String accountId,
    required DateTime date,
    String? note,
  }) {
    return _guard(
      () => _localDataSource.updateOperation(
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

  @override
  Future<void> deleteOperation(String id) =>
      _guard(() => _localDataSource.deleteOperation(id));

  @override
  Future<Operation> createTransfer({
    required String label,
    required double amount,
    required String fromAccountId,
    required String toAccountId,
    required DateTime date,
    String? note,
  }) {
    return _guard(
      () => _localDataSource.createTransfer(
        label: label,
        amount: amount,
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
        date: date,
        note: note,
      ),
    );
  }

  @override
  Future<List<RecurringOperation>> fetchRecurringOperations() =>
      _guard(_localDataSource.fetchRecurringOperations);

  @override
  Future<RecurringOperation> saveRecurringOperation({
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
    return _guard(
      () => _localDataSource.saveRecurringOperation(
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
      ),
    );
  }

  @override
  Future<RecurringOperation> setRecurringActive({
    required String id,
    required bool isActive,
  }) {
    return _guard(
      () => _localDataSource.setRecurringActive(id: id, isActive: isActive),
    );
  }

  @override
  Future<void> deleteRecurringOperation(String id) =>
      _guard(() => _localDataSource.deleteRecurringOperation(id));

  @override
  Future<List<OperationAttachment>> fetchAttachments(String operationId) =>
      _guard(() => _localDataSource.fetchAttachments(operationId));

  @override
  Future<OperationAttachment> saveAttachment(OperationAttachment attachment) =>
      _guard(() => _localDataSource.saveAttachment(attachment));

  @override
  Future<void> deleteAttachment(String attachmentId) =>
      _guard(() => _localDataSource.deleteAttachment(attachmentId));

  /// Exécute [action] et convertit les erreurs techniques en
  /// [OperationsFailure].
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on OperationsFailure {
      rethrow;
    } on OperationsException catch (exception) {
      throw OperationsFailure(exception.message);
    } catch (_) {
      throw const OperationsFailure(_unexpectedMessage);
    }
  }
}
