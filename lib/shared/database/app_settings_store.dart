import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'package:juka/shared/database/app_database.dart';

/// Magasin clé/valeur local, adossé à la table `app_settings`.
///
/// Toutes les préférences (thème, langue, format des dates, rappels) et le
/// profil local (nom, code PIN) passent par ici : une seule table et donc une
/// seule lecture pour tout charger au démarrage.
class AppSettingsStore {
  const AppSettingsStore(this._appDatabase);

  static const String table = 'app_settings';

  final AppDatabase _appDatabase;

  /// Toutes les paires clé/valeur enregistrées.
  Future<Map<String, String>> loadAll() async {
    final db = await _appDatabase.database;
    final rows = await db.query(table);

    return {
      for (final row in rows) row['key']! as String: row['value']! as String,
    };
  }

  /// Enregistre une valeur (insertion ou remplacement).
  Future<void> save(String key, String value) async {
    final db = await _appDatabase.database;
    await db.insert(table, {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Enregistre plusieurs valeurs en une seule transaction.
  Future<void> saveAll(Map<String, String> values) async {
    if (values.isEmpty) return;

    final db = await _appDatabase.database;
    final batch = db.batch();
    for (final entry in values.entries) {
      batch.insert(table, {
        'key': entry.key,
        'value': entry.value,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Supprime une préférence.
  Future<void> remove(String key) async {
    final db = await _appDatabase.database;
    await db.delete(table, where: 'key = ?', whereArgs: [key]);
  }
}

/// Magasin partagé de toutes les préférences locales.
final appSettingsStoreProvider = Provider<AppSettingsStore>(
  (ref) => AppSettingsStore(ref.watch(appDatabaseProvider)),
);
