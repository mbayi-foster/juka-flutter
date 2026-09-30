import 'package:sqflite/sqflite.dart';

import 'package:juka/common/enums/operation_type.dart';
import 'package:juka/common/enums/transaction_category.dart';
import 'package:juka/features/operations/data/exceptions/operations_exception.dart';
import 'package:juka/features/operations/domain/entities/operation.dart';
import 'package:juka/features/operations/domain/entities/operation_attachment.dart';
import 'package:juka/features/operations/domain/entities/operation_filter.dart';
import 'package:juka/features/operations/domain/entities/recurring_operation.dart';
import 'package:juka/features/operations/domain/enums/recurrence_frequency.dart';
import 'package:juka/features/operations/domain/repositories/operations_repository.dart';
import 'package:juka/shared/database/app_database.dart';

/// Implémentation SQLite de [OperationsRepository].
///
/// Chaque écriture touche aussi le solde des comptes concernés, dans la même
/// transaction : les soldes du module Comptes restent donc cohérents avec les
/// opérations saisies. Les transferts déplacent de l'argent entre deux comptes
/// sans jamais impacter les statistiques de revenus / dépenses.
class OperationsSqfliteDataSource implements OperationsRepository {
  const OperationsSqfliteDataSource(this._appDatabase);

  static const String _operations = 'operations';
  static const String _attachments = 'operation_attachments';
  static const String _recurring = 'recurring_operations';
  static const String _accounts = 'accounts';

  final AppDatabase _appDatabase;

  /// Connexion partagée avec le module Comptes.
  Future<Database> get _db => _appDatabase.database;

  @override
  Future<List<Operation>> fetchOperations(OperationFilter filter) async {
    final db = await _db;
    final (where, args) = _buildWhere(filter);

    final rows = await db.query(
      _operations,
      where: where,
      whereArgs: args,
      orderBy: 'date DESC, rowid DESC',
    );

    return _withAttachments(db, [
      for (final row in rows) _operationFromRow(row),
    ]);
  }

  @override
  Future<Operation> fetchOperation(String id) async {
    final db = await _db;
    final rows = await db.query(
      _operations,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw const OperationsException('Cette opération est introuvable.');
    }

    final operation = _operationFromRow(rows.first);
    final withAttachments = await _withAttachments(db, [operation]);
    return withAttachments.first;
  }

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
  }) async {
    if (type.isTransfer) {
      throw const OperationsException(
        'Un transfert s\'enregistre avec createTransfer.',
      );
    }

    final db = await _db;
    final operation = Operation(
      id: _nextId('op'),
      label: label,
      type: type,
      amount: amount,
      category: category,
      accountId: accountId,
      date: date,
      note: _normalizeNote(note),
      recurringOperationId: recurringOperationId,
    );

    await db.transaction((txn) async {
      await txn.insert(_operations, _operationToRow(operation));
      await _applyEffects(txn, operation, sign: 1);
    });

    return operation;
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
  }) async {
    if (type.isTransfer) {
      throw const OperationsException(
        'Un transfert s\'enregistre avec createTransfer.',
      );
    }

    final db = await _db;
    final previous = await fetchOperation(id);

    final updated = Operation(
      id: id,
      label: label,
      type: type,
      amount: amount,
      category: category,
      accountId: accountId,
      date: date,
      note: _normalizeNote(note),
      attachments: previous.attachments,
      recurringOperationId: previous.recurringOperationId,
    );

    await db.transaction((txn) async {
      // On annule l'impact précédent avant d'appliquer le nouveau : le solde
      // reste juste même si le compte ou le montant ont changé.
      await _applyEffects(txn, previous, sign: -1);
      await txn.update(
        _operations,
        _operationToRow(updated),
        where: 'id = ?',
        whereArgs: [id],
      );
      await _applyEffects(txn, updated, sign: 1);
    });

    return updated;
  }

  @override
  Future<void> deleteOperation(String id) async {
    final db = await _db;
    final operation = await fetchOperation(id);

    await db.transaction((txn) async {
      await _applyEffects(txn, operation, sign: -1);
      await txn.delete(_operations, where: 'id = ?', whereArgs: [id]);
      await txn.delete(
        _attachments,
        where: 'operation_id = ?',
        whereArgs: [id],
      );
    });
  }

  @override
  Future<Operation> createTransfer({
    required String label,
    required double amount,
    required String fromAccountId,
    required String toAccountId,
    required DateTime date,
    String? note,
  }) async {
    if (fromAccountId == toAccountId) {
      throw const OperationsException(
        'Choisissez deux comptes différents pour le transfert.',
      );
    }

    final db = await _db;
    final operation = Operation(
      id: _nextId('op'),
      label: label,
      type: OperationType.transfer,
      amount: amount,
      category: TransactionCategory.transfer,
      accountId: fromAccountId,
      transferAccountId: toAccountId,
      date: date,
      note: _normalizeNote(note),
    );

    await db.transaction((txn) async {
      await txn.insert(_operations, _operationToRow(operation));
      await _applyEffects(txn, operation, sign: 1);
    });

    return operation;
  }

  // ---------------------------------------------------------------------
  // Opérations récurrentes
  // ---------------------------------------------------------------------

  @override
  Future<List<RecurringOperation>> fetchRecurringOperations() async {
    final db = await _db;
    final rows = await db.query(_recurring, orderBy: 'next_occurrence ASC');
    return [for (final row in rows) _recurringFromRow(row)];
  }

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
  }) async {
    final db = await _db;
    final recurringId = id ?? _nextId('rec');
    final existing = id == null ? null : await _findRecurring(id);

    final operation = RecurringOperation(
      id: recurringId,
      label: label,
      type: type,
      amount: amount,
      category: category,
      accountId: accountId,
      transferAccountId: transferAccountId,
      frequency: frequency,
      nextOccurrence: nextOccurrence,
      note: _normalizeNote(note),
      isActive: isActive,
      lastGeneratedAt: existing?.lastGeneratedAt,
    );

    await db.insert(
      _recurring,
      _recurringToRow(operation),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return operation;
  }

  @override
  Future<RecurringOperation> setRecurringActive({
    required String id,
    required bool isActive,
  }) async {
    final db = await _db;
    await _findRecurring(id);

    await db.update(
      _recurring,
      {'is_active': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    return _findRecurring(id);
  }

  @override
  Future<void> deleteRecurringOperation(String id) async {
    final db = await _db;
    await db.delete(_recurring, where: 'id = ?', whereArgs: [id]);
  }

  // ---------------------------------------------------------------------
  // Pièces jointes (seul le chemin est stocké en base)
  // ---------------------------------------------------------------------

  @override
  Future<List<OperationAttachment>> fetchAttachments(String operationId) async {
    final db = await _db;
    final rows = await db.query(
      _attachments,
      where: 'operation_id = ?',
      whereArgs: [operationId],
      orderBy: 'created_at ASC',
    );
    return [for (final row in rows) _attachmentFromRow(row)];
  }

  @override
  Future<OperationAttachment> saveAttachment(
    OperationAttachment attachment,
  ) async {
    final db = await _db;
    final persisted = attachment.isPersisted
        ? attachment
        : attachment.copyWith(id: _nextId('att'));

    await db.insert(
      _attachments,
      _attachmentToRow(persisted),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return persisted;
  }

  @override
  Future<void> deleteAttachment(String attachmentId) async {
    final db = await _db;
    await db.delete(_attachments, where: 'id = ?', whereArgs: [attachmentId]);
  }

  // ---------------------------------------------------------------------
  // Solde des comptes
  // ---------------------------------------------------------------------

  /// Comptes impactés par [operation] et variation correspondante.
  List<(String, double)> _balanceEffects(Operation operation) {
    return switch (operation.type) {
      OperationType.income => [(operation.accountId, operation.amount)],
      OperationType.expense => [(operation.accountId, -operation.amount)],
      OperationType.transfer => [
        (operation.accountId, -operation.amount),
        (operation.transferAccountId!, operation.amount),
      ],
    };
  }

  /// Applique (ou annule, avec `sign: -1`) l'impact de [operation] sur les
  /// soldes de comptes.
  Future<void> _applyEffects(
    DatabaseExecutor executor,
    Operation operation, {
    required int sign,
  }) async {
    for (final (accountId, delta) in _balanceEffects(operation)) {
      final updated = await executor.rawUpdate(
        'UPDATE $_accounts SET current_balance = current_balance + ? '
        'WHERE id = ?',
        [sign * delta, accountId],
      );

      if (updated == 0) {
        throw const OperationsException(
          'Le compte associé à cette opération est introuvable.',
        );
      }
    }
  }

  // ---------------------------------------------------------------------
  // Filtres, lignes et identifiants
  // ---------------------------------------------------------------------

  (String?, List<Object?>?) _buildWhere(OperationFilter filter) {
    final conditions = <String>[];
    final args = <Object?>[];

    if (filter.hasQuery) {
      final needle = '%${filter.query.trim()}%';
      conditions.add("(label LIKE ? OR IFNULL(note, '') LIKE ?)");
      args
        ..add(needle)
        ..add(needle);
    }

    final from = filter.from;
    if (from != null) {
      conditions.add('date >= ?');
      args.add(from.millisecondsSinceEpoch);
    }

    final to = filter.to;
    if (to != null) {
      conditions.add('date <= ?');
      args.add(to.millisecondsSinceEpoch);
    }

    final accountId = filter.accountId;
    if (accountId != null) {
      conditions.add('(account_id = ? OR transfer_account_id = ?)');
      args
        ..add(accountId)
        ..add(accountId);
    }

    final category = filter.category;
    if (category != null) {
      conditions.add('category = ?');
      args.add(category.name);
    }

    final type = filter.type;
    if (type != null) {
      conditions.add('type = ?');
      args.add(type.name);
    }

    if (conditions.isEmpty) return (null, null);
    return (conditions.join(' AND '), args);
  }

  /// Charge en une requête les pièces jointes des [operations] fournies.
  Future<List<Operation>> _withAttachments(
    Database db,
    List<Operation> operations,
  ) async {
    if (operations.isEmpty) return operations;

    final ids = [for (final operation in operations) operation.id];
    final placeholders = List.filled(ids.length, '?').join(', ');
    final rows = await db.query(
      _attachments,
      where: 'operation_id IN ($placeholders)',
      whereArgs: ids,
      orderBy: 'created_at ASC',
    );

    final byOperation = <String, List<OperationAttachment>>{};
    for (final row in rows) {
      final attachment = _attachmentFromRow(row);
      byOperation.putIfAbsent(attachment.operationId, () => []).add(attachment);
    }

    return [
      for (final operation in operations)
        operation.copyWith(attachments: byOperation[operation.id] ?? const []),
    ];
  }

  Future<RecurringOperation> _findRecurring(String id) async {
    final db = await _db;
    final rows = await db.query(
      _recurring,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw const OperationsException('Cette récurrence est introuvable.');
    }
    return _recurringFromRow(rows.first);
  }

  String _nextId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  String? _normalizeNote(String? note) {
    final trimmed = note?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  Map<String, Object?> _operationToRow(Operation operation) => {
    'id': operation.id,
    'label': operation.label,
    'type': operation.type.name,
    'amount': operation.amount,
    'category': operation.category.name,
    'account_id': operation.accountId,
    'transfer_account_id': operation.transferAccountId,
    'date': operation.date.millisecondsSinceEpoch,
    'note': operation.note,
    'recurring_operation_id': operation.recurringOperationId,
  };

  Operation _operationFromRow(Map<String, Object?> row) {
    final transferAccountId = row['transfer_account_id'] as String?;

    return Operation(
      id: row['id']! as String,
      label: row['label']! as String,
      type: OperationType.values.byName(row['type']! as String),
      amount: (row['amount']! as num).toDouble(),
      category: TransactionCategory.values.byName(row['category']! as String),
      accountId: row['account_id']! as String,
      transferAccountId: transferAccountId,
      date: DateTime.fromMillisecondsSinceEpoch(row['date']! as int),
      note: row['note'] as String?,
      recurringOperationId: row['recurring_operation_id'] as String?,
    );
  }

  Map<String, Object?> _recurringToRow(RecurringOperation operation) => {
    'id': operation.id,
    'label': operation.label,
    'type': operation.type.name,
    'amount': operation.amount,
    'category': operation.category.name,
    'account_id': operation.accountId,
    'transfer_account_id': operation.transferAccountId,
    'frequency': operation.frequency.name,
    'next_occurrence': operation.nextOccurrence.millisecondsSinceEpoch,
    'note': operation.note,
    'is_active': operation.isActive ? 1 : 0,
    'last_generated_at': operation.lastGeneratedAt?.millisecondsSinceEpoch,
  };

  RecurringOperation _recurringFromRow(Map<String, Object?> row) {
    final lastGeneratedAt = row['last_generated_at'] as int?;

    return RecurringOperation(
      id: row['id']! as String,
      label: row['label']! as String,
      type: OperationType.values.byName(row['type']! as String),
      amount: (row['amount']! as num).toDouble(),
      category: TransactionCategory.values.byName(row['category']! as String),
      accountId: row['account_id']! as String,
      transferAccountId: row['transfer_account_id'] as String?,
      frequency: RecurrenceFrequency.values.byName(row['frequency']! as String),
      nextOccurrence: DateTime.fromMillisecondsSinceEpoch(
        row['next_occurrence']! as int,
      ),
      note: row['note'] as String?,
      isActive: (row['is_active']! as int) == 1,
      lastGeneratedAt: lastGeneratedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastGeneratedAt),
    );
  }

  Map<String, Object?> _attachmentToRow(OperationAttachment attachment) => {
    'id': attachment.id,
    'operation_id': attachment.operationId,
    'file_path': attachment.filePath,
    'file_name': attachment.fileName,
    'created_at': attachment.createdAt.millisecondsSinceEpoch,
    'mime_type': attachment.mimeType,
    'size_in_bytes': attachment.sizeInBytes,
  };

  OperationAttachment _attachmentFromRow(Map<String, Object?> row) {
    return OperationAttachment(
      id: row['id']! as String,
      operationId: row['operation_id']! as String,
      filePath: row['file_path']! as String,
      fileName: row['file_name']! as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
      mimeType: row['mime_type'] as String?,
      sizeInBytes: row['size_in_bytes'] as int?,
    );
  }
}
