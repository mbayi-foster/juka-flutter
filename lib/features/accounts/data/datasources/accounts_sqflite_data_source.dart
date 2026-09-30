import 'package:juka/common/constants/app_constants.dart';
import 'package:sqflite/sqflite.dart';

import 'package:juka/common/enums/account_type.dart';
import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/accounts/data/datasources/accounts_local_data_source.dart';
import 'package:juka/features/accounts/data/datasources/balance_history_builder.dart';
import 'package:juka/features/accounts/data/exceptions/accounts_exception.dart';
import 'package:juka/features/accounts/domain/entities/account.dart';
import 'package:juka/features/accounts/domain/entities/account_balance_point.dart';

/// Implémentation SQLite ([sqflite]) de [AccountsLocalDataSource].
///
/// Les comptes créés par l'utilisateur sont conservés d'une session à l'autre
/// dans une base locale. Le reste du module ne connaît que l'interface
/// [AccountsLocalDataSource] : la remplacer par des appels HTTP ne toucherait
/// ni le domaine ni l'interface utilisateur.
class AccountsSqfliteDataSource implements AccountsLocalDataSource {
  static const String _databaseName = AppConstants.dbName;
  static const int _databaseVersion = 1;
  static const String _table = 'accounts';

  Future<Database>? _database;

  /// Ouvre la base au premier accès, puis réutilise la connexion.
  Future<Database> get _db => _database ??= _open();

  Future<Database> _open() async {
    // `package:path` n'est pas une dépendance directe du projet : le chemin est
    // construit à partir du répertoire fourni par `sqflite`.
    final path = '${await getDatabasesPath()}/$_databaseName';
    return openDatabase(path, version: _databaseVersion, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) {
    return db.execute('''
      CREATE TABLE $_table (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        currency TEXT NOT NULL,
        initial_balance REAL NOT NULL,
        current_balance REAL NOT NULL,
        created_at INTEGER NOT NULL,
        is_archived INTEGER NOT NULL DEFAULT 0,
        reconciled_balance REAL,
        reconciled_at INTEGER,
        note TEXT
      )
    ''');
  }

  @override
  Future<List<Account>> fetchAccounts() async {
    final db = await _db;
    final rows = await db.query(_table, orderBy: 'created_at ASC');
    return [for (final row in rows) _fromRow(row)];
  }

  @override
  Future<List<AccountBalancePoint>> fetchBalanceHistory(
    String accountId,
  ) async {
    return BalanceHistoryBuilder.build(await _findById(accountId));
  }

  @override
  Future<Account> createAccount({
    required String name,
    required AccountType type,
    required AppCurrency currency,
    required double initialBalance,
    String? note,
  }) async {
    final db = await _db;

    final account = Account(
      id: _nextId(),
      name: name,
      type: type,
      currency: currency,
      initialBalance: initialBalance,
      // Un compte neuf démarre au solde saisi.
      currentBalance: initialBalance,
      createdAt: DateTime.now(),
      note: _normalizeNote(note),
    );

    await db.insert(_table, _toRow(account));
    return account;
  }

  @override
  Future<Account> updateAccount({
    required String id,
    required String name,
    required AccountType type,
    required AppCurrency currency,
    required double initialBalance,
    String? note,
  }) async {
    final db = await _db;
    final previous = await _findById(id);

    // Le mouvement déjà enregistré est conservé : le solde courant se décale
    // d'autant que le solde initial.
    final updated = Account(
      id: previous.id,
      name: name,
      type: type,
      currency: currency,
      initialBalance: initialBalance,
      currentBalance: initialBalance + previous.movement,
      createdAt: previous.createdAt,
      isArchived: previous.isArchived,
      reconciledBalance: previous.reconciledBalance,
      reconciledAt: previous.reconciledAt,
      note: _normalizeNote(note),
    );

    await db.update(_table, _toRow(updated), where: 'id = ?', whereArgs: [id]);
    return updated;
  }

  @override
  Future<Account> setArchived({
    required String id,
    required bool isArchived,
  }) async {
    final db = await _db;
    await _findById(id);

    await db.update(
      _table,
      {'is_archived': isArchived ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    return _findById(id);
  }

  @override
  Future<Account> reconcile({
    required String id,
    required double realBalance,
  }) async {
    final db = await _db;
    await _findById(id);

    await db.update(
      _table,
      {
        'reconciled_balance': realBalance,
        'reconciled_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    return _findById(id);
  }

  Future<Account> _findById(String id) async {
    final db = await _db;
    final rows = await db.query(
      _table,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      throw const AccountsException('Ce compte est introuvable.');
    }
    return _fromRow(rows.first);
  }

  String _nextId() => 'acc-${DateTime.now().microsecondsSinceEpoch}';

  String? _normalizeNote(String? note) {
    final trimmed = note?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  Map<String, Object?> _toRow(Account account) => {
    'id': account.id,
    'name': account.name,
    'type': account.type.name,
    'currency': account.currency.code,
    'initial_balance': account.initialBalance,
    'current_balance': account.currentBalance,
    'created_at': account.createdAt.millisecondsSinceEpoch,
    'is_archived': account.isArchived ? 1 : 0,
    'reconciled_balance': account.reconciledBalance,
    'reconciled_at': account.reconciledAt?.millisecondsSinceEpoch,
    'note': account.note,
  };

  Account _fromRow(Map<String, Object?> row) {
    final reconciledAt = row['reconciled_at'] as int?;

    return Account(
      id: row['id']! as String,
      name: row['name']! as String,
      type: AccountType.values.byName(row['type']! as String),
      currency: _currencyFromCode(row['currency']! as String),
      initialBalance: (row['initial_balance']! as num).toDouble(),
      currentBalance: (row['current_balance']! as num).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
      isArchived: (row['is_archived']! as int) == 1,
      reconciledBalance: (row['reconciled_balance'] as num?)?.toDouble(),
      reconciledAt: reconciledAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(reconciledAt),
      note: row['note'] as String?,
    );
  }

  AppCurrency _currencyFromCode(String code) => AppCurrency.values.firstWhere(
    (currency) => currency.code == code,
    orElse: () => AppCurrency.eur,
  );
}
