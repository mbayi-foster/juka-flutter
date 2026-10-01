import 'package:sqflite/sqflite.dart';

import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/wealth/domain/entities/net_worth_snapshot.dart';
import 'package:juka/features/wealth/domain/repositories/wealth_repository.dart';
import 'package:juka/shared/database/app_database.dart';

/// Implémentation SQLite de [WealthRepository].
///
/// Les photos mensuelles sont conservées une par (mois, devise) : rouvrir
/// l'application dans le même mois met simplement la photo à jour.
class WealthSqfliteDataSource implements WealthRepository {
  const WealthSqfliteDataSource(this._appDatabase);

  static const String _table = 'net_worth_snapshots';

  final AppDatabase _appDatabase;

  Future<Database> get _db => _appDatabase.database;

  @override
  Future<List<NetWorthSnapshot>> fetchSnapshots({
    required AppCurrency currency,
    int? limit,
  }) async {
    final db = await _db;
    final rows = await db.query(
      _table,
      where: 'currency = ?',
      whereArgs: [currency.code],
      orderBy: 'month DESC',
      limit: limit,
    );

    // La requête trie du plus récent au plus ancien pour pouvoir limiter ;
    // l'appelant reçoit l'historique dans l'ordre chronologique.
    final snapshots = [for (final row in rows) _fromRow(row)];
    return snapshots.reversed.toList();
  }

  @override
  Future<NetWorthSnapshot> saveSnapshot(NetWorthSnapshot snapshot) async {
    final db = await _db;
    await db.insert(
      _table,
      _toRow(snapshot),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return snapshot;
  }

  @override
  Future<void> clearSnapshots(AppCurrency currency) async {
    final db = await _db;
    await db.delete(_table, where: 'currency = ?', whereArgs: [currency.code]);
  }

  Map<String, Object?> _toRow(NetWorthSnapshot snapshot) => {
    'month': snapshot.month.millisecondsSinceEpoch,
    'currency': snapshot.currency.code,
    'assets': snapshot.assets,
    'liabilities': snapshot.liabilities,
    'recorded_at': snapshot.recordedAt.millisecondsSinceEpoch,
  };

  NetWorthSnapshot _fromRow(Map<String, Object?> row) {
    return NetWorthSnapshot(
      month: DateTime.fromMillisecondsSinceEpoch(row['month']! as int),
      currency: _currencyFromCode(row['currency']! as String),
      assets: (row['assets']! as num).toDouble(),
      liabilities: (row['liabilities']! as num).toDouble(),
      recordedAt: DateTime.fromMillisecondsSinceEpoch(
        row['recorded_at']! as int,
      ),
    );
  }

  AppCurrency _currencyFromCode(String code) => AppCurrency.values.firstWhere(
    (currency) => currency.code == code,
    orElse: () => AppCurrency.eur,
  );
}
