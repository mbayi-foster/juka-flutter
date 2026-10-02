import 'package:sqflite/sqflite.dart';

import 'package:juka/common/enums/app_currency.dart';
import 'package:juka/features/currencies/domain/entities/exchange_rate.dart';
import 'package:juka/features/currencies/domain/repositories/currencies_repository.dart';
import 'package:juka/shared/database/app_database.dart';

/// Implémentation SQLite de [CurrenciesRepository].
///
/// Deux tables : `currencies` (les devises suivies) et `exchange_rates` (un
/// taux par devise et par mois).
class CurrenciesSqfliteDataSource implements CurrenciesRepository {
  const CurrenciesSqfliteDataSource(this._appDatabase);

  static const String _currencies = 'currencies';
  static const String _rates = 'exchange_rates';

  final AppDatabase _appDatabase;

  Future<Database> get _db => _appDatabase.database;

  @override
  Future<List<AppCurrency>> fetchTrackedCurrencies() async {
    final db = await _db;
    final rows = await db.query(_currencies, orderBy: 'created_at ASC');

    final tracked = <AppCurrency>[];
    for (final row in rows) {
      final currency = _currencyFromCode(row['code'] as String?);
      if (currency != null) tracked.add(currency);
    }
    return tracked;
  }

  @override
  Future<void> trackCurrency(AppCurrency currency) async {
    final db = await _db;
    await db.insert(_currencies, {
      'code': currency.code,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  @override
  Future<void> untrackCurrency(AppCurrency currency) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(
        _currencies,
        where: 'code = ?',
        whereArgs: [currency.code],
      );
      await txn.delete(
        _rates,
        where: 'currency_code = ?',
        whereArgs: [currency.code],
      );
    });
  }

  @override
  Future<List<ExchangeRate>> fetchRates() async {
    final db = await _db;
    final rows = await db.query(_rates, orderBy: 'month ASC');

    final rates = <ExchangeRate>[];
    for (final row in rows) {
      final currency = _currencyFromCode(row['currency_code'] as String?);
      if (currency == null) continue;
      rates.add(
        ExchangeRate(
          currency: currency,
          month: DateTime.fromMillisecondsSinceEpoch(row['month']! as int),
          rate: (row['rate']! as num).toDouble(),
        ),
      );
    }
    return rates;
  }

  @override
  Future<void> saveRate({
    required AppCurrency currency,
    required DateTime month,
    required double rate,
  }) async {
    final db = await _db;
    await db.insert(_rates, {
      'currency_code': currency.code,
      'month': DateTime(month.year, month.month).millisecondsSinceEpoch,
      'rate': rate,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> deleteRate({
    required AppCurrency currency,
    required DateTime month,
  }) async {
    final db = await _db;
    await db.delete(
      _rates,
      where: 'currency_code = ? AND month = ?',
      whereArgs: [
        currency.code,
        DateTime(month.year, month.month).millisecondsSinceEpoch,
      ],
    );
  }

  @override
  Future<void> clear() async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.delete(_rates);
      await txn.delete(_currencies);
    });
  }

  AppCurrency? _currencyFromCode(String? code) {
    if (code == null) return null;
    for (final currency in AppCurrency.values) {
      if (currency.code == code) return currency;
    }
    return null;
  }
}
