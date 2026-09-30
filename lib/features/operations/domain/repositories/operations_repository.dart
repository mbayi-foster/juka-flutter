import 'package:juka/common/enums/operation_type.dart';
import 'package:juka/common/enums/transaction_category.dart';
import 'package:juka/features/operations/domain/entities/operation.dart';
import 'package:juka/features/operations/domain/entities/operation_attachment.dart';
import 'package:juka/features/operations/domain/entities/operation_filter.dart';
import 'package:juka/features/operations/domain/entities/recurring_operation.dart';
import 'package:juka/features/operations/domain/enums/recurrence_frequency.dart';

/// Contrat du domaine pour les opérations, les transferts, les modèles
/// récurrents et les pièces jointes.
///
/// L'implémentation concrète vit dans la couche `data` (SQLite, API…) : le
/// domaine ignore où et comment les opérations sont stockées.
abstract interface class OperationsRepository {
  /// Opérations correspondant à [filter], de la plus récente à la plus ancienne.
  Future<List<Operation>> fetchOperations(OperationFilter filter);

  Future<Operation> fetchOperation(String id);

  /// Crée un revenu ou une dépense.
  ///
  /// Un transfert passe par [createTransfer].
  Future<Operation> createOperation({
    required String label,
    required OperationType type,
    required double amount,
    required TransactionCategory category,
    required String accountId,
    required DateTime date,
    String? note,
    String? recurringOperationId,
  });

  Future<Operation> updateOperation({
    required String id,
    required String label,
    required OperationType type,
    required double amount,
    required TransactionCategory category,
    required String accountId,
    required DateTime date,
    String? note,
  });

  Future<void> deleteOperation(String id);

  /// Enregistre un transfert entre deux comptes.
  ///
  /// Un transfert déplace de l'argent sans le faire sortir du patrimoine : il
  /// n'est compté ni comme revenu ni comme dépense.
  Future<Operation> createTransfer({
    required String label,
    required double amount,
    required String fromAccountId,
    required String toAccountId,
    required DateTime date,
    String? note,
  });

  // ---------------------------------------------------------------------
  // Opérations récurrentes (loyer, salaire, abonnements…)
  // ---------------------------------------------------------------------

  Future<List<RecurringOperation>> fetchRecurringOperations();

  /// Crée ([id] `null`) ou met à jour un modèle récurrent.
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
  });

  /// Met en pause ou réactive un modèle sans le supprimer.
  Future<RecurringOperation> setRecurringActive({
    required String id,
    required bool isActive,
  });

  Future<void> deleteRecurringOperation(String id);

  // ---------------------------------------------------------------------
  // Pièces jointes
  // ---------------------------------------------------------------------

  /// Pièces jointes d'une opération (également portées par [Operation]).
  Future<List<OperationAttachment>> fetchAttachments(String operationId);

  /// Enregistre la pièce jointe en base : **seul son chemin** y est conservé,
  /// le fichier restant dans le stockage privé de l'application.
  Future<OperationAttachment> saveAttachment(OperationAttachment attachment);

  Future<void> deleteAttachment(String attachmentId);
}
